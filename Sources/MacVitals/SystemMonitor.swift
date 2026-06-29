import AppKit
import Darwin
import Foundation
import IOKit.ps
import UserNotifications

@MainActor
final class SystemMonitor: ObservableObject {
    @Published private(set) var stats = SystemStats()
    @Published private(set) var history: [HistorySample] = []
    @Published private(set) var settings: MonitorSettings
    @Published private(set) var launchAtLoginEnabled = LaunchAtLoginController.isEnabled
    @Published private(set) var settingsError: String?
    @Published private(set) var snapshotStatus: String?

    var onStatsChanged: ((SystemStats) -> Void)?

    private var timer: Timer?
    private var sampler = SystemSampler()
    private let settingsStore = SettingsStore()
    private let notificationController = NotificationController()
    private var isFocused = false
    private let maxHistorySamples = 120
    private var snapshotStatusExpiresAt: Date?

    init() {
        settings = settingsStore.load()
    }

    func start() {
        syncLaunchAtLogin()
        sample()
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func setFocused(_ focused: Bool) {
        isFocused = focused
        scheduleTimer()
    }

    func refreshNow() {
        sample()
    }

    func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
    }

    func copyDiagnosticSnapshot() {
        let snapshot = DiagnosticSnapshot.make(stats: stats, history: history)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snapshot, forType: .string)
        snapshotStatus = L.t("diagnostics.copied")
        snapshotStatusExpiresAt = Date().addingTimeInterval(3)
    }

    func syncLaunchAtLogin() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try LaunchAtLoginController.setEnabled(enabled)
            settingsError = nil
            syncLaunchAtLogin()
        } catch {
            settingsError = error.localizedDescription
            syncLaunchAtLogin()
        }
    }

    func setMenuBarDisplayMode(_ mode: MenuBarDisplayMode) {
        settings.menuBarDisplayMode = mode
        saveSettings()
        onStatsChanged?(stats)
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationController.requestAuthorization()
                settings.notificationsEnabled = granted
                settingsError = granted ? nil : L.t("error.notificationsDenied")
                saveSettings()
            }
        } else {
            settings.notificationsEnabled = false
            saveSettings()
        }
    }

    func setMemoryPressureThreshold(_ threshold: Double) {
        settings.memoryPressureThreshold = threshold
        saveSettings()
    }

    func setSwapThresholdBytes(_ bytes: UInt64) {
        settings.swapThresholdBytes = bytes
        saveSettings()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval: TimeInterval = isFocused ? 1.5 : 4.0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }

    private func sample() {
        stats = sampler.sample()
        appendHistorySample(from: stats)
        notificationController.evaluate(stats: stats, settings: settings)
        onStatsChanged?(stats)
        clearSnapshotStatusIfNeeded()
    }

    private func saveSettings() {
        settingsStore.save(settings)
    }

    private func appendHistorySample(from stats: SystemStats) {
        history.append(
            HistorySample(
                sampledAt: stats.sampledAt,
                memoryPressure: stats.memory.pressure,
                cpuActive: stats.cpu.activePercent,
                swapUsedBytes: stats.memory.swapUsedBytes
            )
        )

        if history.count > maxHistorySamples {
            history.removeFirst(history.count - maxHistorySamples)
        }
    }

    private func clearSnapshotStatusIfNeeded() {
        guard let snapshotStatusExpiresAt else { return }
        if Date() >= snapshotStatusExpiresAt {
            snapshotStatus = nil
            self.snapshotStatusExpiresAt = nil
        }
    }
}

private final class SystemSampler {
    private var previousCPU: host_cpu_load_info_data_t?
    private var previousNetworkBytes: (received: UInt64, sent: UInt64, date: Date)?

    func sample() -> SystemStats {
        SystemStats(
            memory: sampleMemory(),
            cpu: sampleCPU(),
            disk: sampleDisk(),
            battery: sampleBattery(),
            network: sampleNetwork(),
            processes: sampleProcesses(),
            sampledAt: .now
        )
    }

    private func sampleMemory() -> MemoryStats {
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return .empty
        }

        let page = UInt64(pageSize)
        let total = ProcessInfo.processInfo.physicalMemory
        let free = UInt64(vmStats.free_count + vmStats.speculative_count) * page
        let app = UInt64(vmStats.active_count) * page
        let wired = UInt64(vmStats.wire_count) * page
        let compressed = UInt64(vmStats.compressor_page_count) * page
        let cached = UInt64(vmStats.inactive_count + vmStats.purgeable_count) * page
        let used = min(total, app + wired + compressed)

        return MemoryStats(
            totalBytes: total,
            usedBytes: used,
            appBytes: app,
            wiredBytes: wired,
            compressedBytes: compressed,
            cachedBytes: cached,
            freeBytes: free,
            swapUsedBytes: sampleSwapUsed()
        )
    }

    private func sampleSwapUsed() -> UInt64 {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.stride
        let result = sysctlbyname("vm.swapusage", &swap, &size, nil, 0)
        return result == 0 ? swap.xsu_used : 0
    }

    private func sampleCPU() -> CPUStats {
        var cpuInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return .empty
        }

        defer { previousCPU = cpuInfo }
        guard let previousCPU else {
            return .empty
        }

        let user = Double(cpuInfo.cpu_ticks.0 - previousCPU.cpu_ticks.0)
        let system = Double(cpuInfo.cpu_ticks.1 - previousCPU.cpu_ticks.1)
        let idle = Double(cpuInfo.cpu_ticks.2 - previousCPU.cpu_ticks.2)
        let nice = Double(cpuInfo.cpu_ticks.3 - previousCPU.cpu_ticks.3)
        let total = max(1, user + system + idle + nice)

        return CPUStats(
            systemPercent: system / total,
            userPercent: (user + nice) / total,
            idlePercent: idle / total
        )
    }

    private func sampleDisk() -> DiskStats {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: "/")
            let total = attributes[.systemSize] as? NSNumber
            let free = attributes[.systemFreeSize] as? NSNumber
            return DiskStats(totalBytes: total?.uint64Value ?? 0, freeBytes: free?.uint64Value ?? 0)
        } catch {
            return .empty
        }
    }

    private func sampleBattery() -> BatteryStats {
        guard
            let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
            let source = sources.first,
            let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatteryStats(percent: nil, isCharging: false, powerSource: "Power")
        }

        let current = description[kIOPSCurrentCapacityKey] as? Double
        let max = description[kIOPSMaxCapacityKey] as? Double
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        let state = description[kIOPSPowerSourceStateKey] as? String ?? "Unknown"
        let percent = current.flatMap { current in
            max.flatMap { max in max > 0 ? current / max : nil }
        }

        return BatteryStats(percent: percent, isCharging: isCharging, powerSource: state)
    }

    private func sampleNetwork() -> NetworkStats {
        var received: UInt64 = 0
        var sent: UInt64 = 0
        var addresses: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&addresses) == 0, let firstAddress = addresses else {
            return .empty
        }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddress
        while pointer != nil {
            guard
                let interface = pointer?.pointee,
                interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK),
                let data = interface.ifa_data
            else {
                pointer = pointer?.pointee.ifa_next
                continue
            }

            let name = String(cString: interface.ifa_name)
            if name.hasPrefix("en") || name.hasPrefix("utun") {
                let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                received += UInt64(networkData.ifi_ibytes)
                sent += UInt64(networkData.ifi_obytes)
            }
            pointer = pointer?.pointee.ifa_next
        }
        freeifaddrs(addresses)

        let now = Date()
        defer { previousNetworkBytes = (received, sent, now) }
        guard let previousNetworkBytes else {
            return .empty
        }

        let elapsed = max(0.1, now.timeIntervalSince(previousNetworkBytes.date))
        let receivedRate = Double(received - previousNetworkBytes.received) / elapsed
        let sentRate = Double(sent - previousNetworkBytes.sent) / elapsed
        return NetworkStats(
            receivedBytesPerSecond: UInt64(max(0, receivedRate)),
            sentBytesPerSecond: UInt64(max(0, sentRate))
        )
    }

    private func sampleProcesses() -> [ProcessStats] {
        NSWorkspace.shared.runningApplications
            .compactMap { app -> ProcessStats? in
                var taskInfo = proc_taskinfo()
                let size = MemoryLayout<proc_taskinfo>.stride
                let result = proc_pidinfo(app.processIdentifier, PROC_PIDTASKINFO, 0, &taskInfo, Int32(size))
                guard result == size else { return nil }

                return ProcessStats(
                    pid: app.processIdentifier,
                    name: app.localizedName ?? app.bundleURL?.deletingPathExtension().lastPathComponent ?? "Process \(app.processIdentifier)",
                    memoryBytes: taskInfo.pti_resident_size
                )
            }
            .sorted { $0.memoryBytes > $1.memoryBytes }
            .prefix(8)
            .map { $0 }
    }
}
