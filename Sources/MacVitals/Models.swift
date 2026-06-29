import Foundation

struct SystemStats {
    var memory: MemoryStats = .empty
    var cpu: CPUStats = .empty
    var disk: DiskStats = .empty
    var battery: BatteryStats = .empty
    var network: NetworkStats = .empty
    var processes: [ProcessStats] = []
    var sampledAt: Date = .now

    var menuBarTitle: String {
        menuBarTitle(for: .memoryPressure)
    }

    func menuBarTitle(for mode: MenuBarDisplayMode) -> String {
        switch mode {
        case .memoryPressure:
            return "MV \(Int(memory.pressure * 100))%"
        case .usedMemory:
            return ByteText.format(memory.usedBytes)
        case .cpu:
            return "CPU \(cpu.activePercent.percentText)"
        case .compact:
            return "MV"
        }
    }

    var recommendations: [SystemRecommendation] {
        SystemRecommendation.make(for: self)
    }
}

struct HistorySample: Identifiable {
    let id = UUID()
    var sampledAt: Date
    var memoryPressure: Double
    var cpuActive: Double
    var swapUsedBytes: UInt64
}

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case memoryPressure
    case usedMemory
    case cpu
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memoryPressure: L.t("menu.mode.memoryPressure")
        case .usedMemory: L.t("menu.mode.usedMemory")
        case .cpu: L.t("menu.mode.cpu")
        case .compact: L.t("menu.mode.compact")
        }
    }
}

enum SamplingMode: String, CaseIterable, Identifiable {
    case balanced
    case lowPower
    case responsive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: L.t("sampling.mode.balanced")
        case .lowPower: L.t("sampling.mode.lowPower")
        case .responsive: L.t("sampling.mode.responsive")
        }
    }

    var detail: String {
        switch self {
        case .balanced: L.t("sampling.mode.balanced.detail")
        case .lowPower: L.t("sampling.mode.lowPower.detail")
        case .responsive: L.t("sampling.mode.responsive.detail")
        }
    }

    func interval(isFocused: Bool) -> TimeInterval {
        switch (self, isFocused) {
        case (.balanced, true): 1.5
        case (.balanced, false): 4.0
        case (.lowPower, true): 3.0
        case (.lowPower, false): 10.0
        case (.responsive, true): 1.0
        case (.responsive, false): 2.5
        }
    }
}

struct MonitorSettings {
    var menuBarDisplayMode: MenuBarDisplayMode
    var samplingMode: SamplingMode
    var notificationsEnabled: Bool
    var memoryPressureThreshold: Double
    var swapThresholdBytes: UInt64

    static let defaults = MonitorSettings(
        menuBarDisplayMode: .memoryPressure,
        samplingMode: .balanced,
        notificationsEnabled: false,
        memoryPressureThreshold: 0.82,
        swapThresholdBytes: 2 * 1024 * 1024 * 1024
    )
}

struct MemoryStats {
    var totalBytes: UInt64
    var usedBytes: UInt64
    var appBytes: UInt64
    var wiredBytes: UInt64
    var compressedBytes: UInt64
    var cachedBytes: UInt64
    var freeBytes: UInt64
    var swapUsedBytes: UInt64

    var pressure: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, Double(usedBytes) / Double(totalBytes))
    }

    static let empty = MemoryStats(
        totalBytes: 0,
        usedBytes: 0,
        appBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0,
        cachedBytes: 0,
        freeBytes: 0,
        swapUsedBytes: 0
    )
}

struct CPUStats {
    var systemPercent: Double
    var userPercent: Double
    var idlePercent: Double

    var activePercent: Double {
        min(1, max(0, systemPercent + userPercent))
    }

    static let empty = CPUStats(systemPercent: 0, userPercent: 0, idlePercent: 1)
}

struct DiskStats {
    var totalBytes: UInt64
    var freeBytes: UInt64

    var usedBytes: UInt64 {
        totalBytes > freeBytes ? totalBytes - freeBytes : 0
    }

    var usedPercent: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, Double(usedBytes) / Double(totalBytes))
    }

    static let empty = DiskStats(totalBytes: 0, freeBytes: 0)
}

struct BatteryStats {
    var percent: Double?
    var isCharging: Bool
    var powerSource: String

    static let empty = BatteryStats(percent: nil, isCharging: false, powerSource: "Unknown")
}

struct NetworkStats {
    var receivedBytesPerSecond: UInt64
    var sentBytesPerSecond: UInt64

    static let empty = NetworkStats(receivedBytesPerSecond: 0, sentBytesPerSecond: 0)
}

struct ProcessStats: Identifiable {
    var id: pid_t { pid }
    var pid: pid_t
    var name: String
    var memoryBytes: UInt64
}

enum RecommendationSeverity {
    case healthy
    case notice
    case warning

    var symbolName: String {
        switch self {
        case .healthy: "checkmark.circle"
        case .notice: "info.circle"
        case .warning: "exclamationmark.triangle"
        }
    }
}

struct SystemRecommendation: Identifiable {
    let id: String
    let severity: RecommendationSeverity
    let title: String
    let detail: String

    static func make(for stats: SystemStats) -> [SystemRecommendation] {
        var recommendations: [SystemRecommendation] = []
        let heaviestProcess = stats.processes.first
        let swapIsHigh = stats.memory.swapUsedBytes >= 1_073_741_824
        let memoryIsTight = stats.memory.pressure >= 0.82
        let memoryIsBusy = stats.memory.pressure >= 0.72
        let cpuIsBusy = stats.cpu.activePercent >= 0.78
        let diskIsTight = stats.disk.usedPercent >= 0.9

        if memoryIsTight, swapIsHigh, let heaviestProcess {
            recommendations.append(
                SystemRecommendation(
                    id: "memory-swap-heavy-app",
                    severity: .warning,
                    title: L.t("recommendation.memorySwap.title"),
                    detail: String(
                        format: L.t("recommendation.memorySwap.detail"),
                        heaviestProcess.name,
                        ByteText.format(heaviestProcess.memoryBytes),
                        ByteText.format(stats.memory.swapUsedBytes)
                    )
                )
            )
        } else if memoryIsTight {
            recommendations.append(
                SystemRecommendation(
                    id: "memory-tight",
                    severity: .warning,
                    title: L.t("recommendation.memoryTight.title"),
                    detail: L.t("recommendation.memoryTight.detail")
                )
            )
        } else if memoryIsBusy, let heaviestProcess {
            recommendations.append(
                SystemRecommendation(
                    id: "memory-busy",
                    severity: .notice,
                    title: L.t("recommendation.memoryBusy.title"),
                    detail: String(
                        format: L.t("recommendation.memoryBusy.detail"),
                        heaviestProcess.name,
                        ByteText.format(heaviestProcess.memoryBytes)
                    )
                )
            )
        }

        if cpuIsBusy {
            recommendations.append(
                SystemRecommendation(
                    id: "cpu-busy",
                    severity: .notice,
                    title: L.t("recommendation.cpuBusy.title"),
                    detail: L.t("recommendation.cpuBusy.detail")
                )
            )
        }

        if diskIsTight {
            recommendations.append(
                SystemRecommendation(
                    id: "disk-tight",
                    severity: .notice,
                    title: L.t("recommendation.diskTight.title"),
                    detail: String(
                        format: L.t("recommendation.diskTight.detail"),
                        ByteText.format(stats.disk.freeBytes)
                    )
                )
            )
        }

        if recommendations.isEmpty {
            recommendations.append(
                SystemRecommendation(
                    id: "healthy",
                    severity: .healthy,
                    title: L.t("recommendation.healthy.title"),
                    detail: L.t("recommendation.healthy.detail")
                )
            )
        }

        return Array(recommendations.prefix(3))
    }
}
