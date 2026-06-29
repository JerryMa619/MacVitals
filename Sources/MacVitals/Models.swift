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

struct MonitorSettings {
    var menuBarDisplayMode: MenuBarDisplayMode
    var notificationsEnabled: Bool
    var memoryPressureThreshold: Double
    var swapThresholdBytes: UInt64

    static let defaults = MonitorSettings(
        menuBarDisplayMode: .memoryPressure,
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
