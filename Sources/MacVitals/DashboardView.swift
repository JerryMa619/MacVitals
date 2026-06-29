import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var monitor: SystemMonitor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    OverviewSection(stats: monitor.stats)
                    MemorySection(memory: monitor.stats.memory)
                    HardwareSection(stats: monitor.stats)
                    PreferencesSection(
                        settings: monitor.settings,
                        launchAtLoginEnabled: monitor.launchAtLoginEnabled,
                        settingsError: monitor.settingsError
                    ) { mode in
                        monitor.setMenuBarDisplayMode(mode)
                    } setNotificationsEnabled: { enabled in
                        monitor.setNotificationsEnabled(enabled)
                    } setMemoryPressureThreshold: { threshold in
                        monitor.setMemoryPressureThreshold(threshold)
                    } setSwapThresholdBytes: { bytes in
                        monitor.setSwapThresholdBytes(bytes)
                    } setLaunchAtLoginEnabled: { enabled in
                        monitor.setLaunchAtLoginEnabled(enabled)
                    }
                    ProcessSection(processes: monitor.stats.processes) {
                        monitor.openActivityMonitor()
                    }
                }
                .padding(16)
            }
            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacVitals")
                    .font(.system(size: 18, weight: .semibold))
                Text(monitor.stats.sampledAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusPill(pressure: monitor.stats.memory.pressure)
        }
        .padding(16)
    }

    private var footer: some View {
        HStack {
            Button {
                monitor.refreshNow()
            } label: {
                Label(L.t("action.refresh"), systemImage: "arrow.clockwise")
            }

            Spacer()

            Button {
                monitor.openActivityMonitor()
            } label: {
                Label(L.t("action.activityMonitor"), systemImage: "waveform.path.ecg")
            }
        }
        .buttonStyle(.borderless)
        .padding(12)
    }
}

private struct OverviewSection: View {
    let stats: SystemStats

    var body: some View {
        HStack(spacing: 12) {
            MetricRing(title: L.t("metric.memory"), value: stats.memory.pressure, detail: ByteText.format(stats.memory.usedBytes))
            MetricRing(title: "CPU", value: stats.cpu.activePercent, detail: stats.cpu.activePercent.percentText)
            MetricRing(title: L.t("metric.disk"), value: stats.disk.usedPercent, detail: ByteText.format(stats.disk.freeBytes))
        }
    }
}

private struct MemorySection: View {
    let memory: MemoryStats

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(L.t("section.memory"))
            ProgressView(value: memory.pressure)
                .tint(color(for: memory.pressure))
            VStack(spacing: 8) {
                StatRow(L.t("memory.app"), ByteText.format(memory.appBytes))
                StatRow(L.t("memory.wired"), ByteText.format(memory.wiredBytes))
                StatRow(L.t("memory.compressed"), ByteText.format(memory.compressedBytes))
                StatRow(L.t("memory.cached"), ByteText.format(memory.cachedBytes))
                StatRow("Swap", ByteText.format(memory.swapUsedBytes))
            }
        }
        .panelStyle()
    }

    private func color(for pressure: Double) -> Color {
        switch pressure {
        case 0..<0.65: .green
        case 0..<0.82: .yellow
        default: .red
        }
    }
}

private struct HardwareSection: View {
    let stats: SystemStats

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(L.t("section.hardware"))
            StatRow("CPU", String(format: L.t("hardware.cpuActive"), stats.cpu.activePercent.percentText))
            StatRow(L.t("hardware.diskFree"), ByteText.format(stats.disk.freeBytes))
            StatRow(L.t("hardware.battery"), batteryText)
            StatRow(L.t("hardware.networkDown"), ByteText.rate(stats.network.receivedBytesPerSecond))
            StatRow(L.t("hardware.networkUp"), ByteText.rate(stats.network.sentBytesPerSecond))
        }
        .panelStyle()
    }

    private var batteryText: String {
        guard let percent = stats.battery.percent else {
            return stats.battery.powerSource
        }
        let charging = stats.battery.isCharging ? " \(L.t("battery.charging"))" : ""
        return "\(percent.percentText)\(charging)"
    }
}

private struct ProcessSection: View {
    let processes: [ProcessStats]
    let openActivityMonitor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(L.t("section.heavyApps"))
                Spacer()
                Button(action: openActivityMonitor) {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.borderless)
                .help(L.t("action.activityMonitor"))
            }

            if processes.isEmpty {
                Text(L.t("process.empty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(processes) { process in
                    HStack {
                        Text(process.name)
                            .lineLimit(1)
                        Spacer()
                        Text(ByteText.format(process.memoryBytes))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.system(size: 12))
                }
            }
        }
        .panelStyle()
    }
}

private struct PreferencesSection: View {
    let settings: MonitorSettings
    let launchAtLoginEnabled: Bool
    let settingsError: String?
    let setMenuBarDisplayMode: (MenuBarDisplayMode) -> Void
    let setNotificationsEnabled: (Bool) -> Void
    let setMemoryPressureThreshold: (Double) -> Void
    let setSwapThresholdBytes: (UInt64) -> Void
    let setLaunchAtLoginEnabled: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(L.t("section.preferences"))

            Picker(L.t("settings.menuBar"), selection: Binding(
                get: { settings.menuBarDisplayMode },
                set: { newValue in
                    setMenuBarDisplayMode(newValue)
                }
            )) {
                ForEach(MenuBarDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Toggle(isOn: Binding(
                get: { settings.notificationsEnabled },
                set: { newValue in
                    setNotificationsEnabled(newValue)
                }
            )) {
                Label(L.t("settings.notifications"), systemImage: "bell")
            }
            .toggleStyle(.switch)

            if settings.notificationsEnabled {
                VStack(spacing: 8) {
                    ThresholdRow(
                        title: L.t("settings.memoryThreshold"),
                        value: settings.memoryPressureThreshold,
                        range: 0.65...0.95,
                        display: settings.memoryPressureThreshold.percentText,
                        setValue: setMemoryPressureThreshold
                    )
                    SwapThresholdRow(
                        value: settings.swapThresholdBytes,
                        setValue: setSwapThresholdBytes
                    )
                }
            }

            Toggle(isOn: Binding(
                get: { launchAtLoginEnabled },
                set: { newValue in
                    setLaunchAtLoginEnabled(newValue)
                }
            )) {
                Label(L.t("settings.launchAtLogin"), systemImage: "power")
            }
            .toggleStyle(.switch)

            if let settingsError {
                Text(settingsError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .panelStyle()
    }
}

private struct ThresholdRow: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let display: String
    let setValue: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(display)
                    .monospacedDigit()
            }
            .font(.system(size: 12))

            Slider(value: Binding(
                get: { value },
                set: { newValue in
                    setValue(newValue)
                }
            ), in: range, step: 0.01)
        }
    }
}

private struct SwapThresholdRow: View {
    let value: UInt64
    let setValue: (UInt64) -> Void

    private var gbValue: Double {
        Double(value) / 1_073_741_824
    }

    var body: some View {
        ThresholdRow(
            title: L.t("settings.swapThreshold"),
            value: gbValue,
            range: 1...16,
            display: ByteText.format(value)
        ) { newValue in
            setValue(UInt64(newValue * 1_073_741_824))
        }
    }
}

private struct MetricRing: View {
    let title: String
    let value: Double
    let detail: String

    var body: some View {
        VStack(spacing: 6) {
            Gauge(value: value) {
                EmptyView()
            } currentValueLabel: {
                Text(value.percentText)
                    .font(.system(size: 12, weight: .semibold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var tint: Color {
        switch value {
        case 0..<0.65: .green
        case 0..<0.82: .orange
        default: .red
        }
    }
}

private struct StatusPill: View {
    let pressure: Double

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())
    }

    private var label: String {
        switch pressure {
        case 0..<0.65: L.t("status.healthy")
        case 0..<0.82: L.t("status.busy")
        default: L.t("status.tight")
        }
    }

    private var color: Color {
        switch pressure {
        case 0..<0.65: .green
        case 0..<0.82: .orange
        default: .red
        }
    }
}

private struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.system(size: 12))
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
