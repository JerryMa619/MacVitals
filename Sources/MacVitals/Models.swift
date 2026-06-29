import Foundation

struct SystemStats {
    var memory: MemoryStats = .empty
    var cpu: CPUStats = .empty
    var disk: DiskStats = .empty
    var battery: BatteryStats = .empty
    var thermal: ThermalStats = .empty
    var network: NetworkStats = .empty
    var processes: [ProcessStats] = []
    var sampledAt: Date = .now

    var menuBarTitle: String {
        menuBarTitle(for: .memoryPressure)
    }

    func menuBarTitle(for mode: MenuBarDisplayMode) -> String {
        switch mode {
        case .memoryPressure:
            return "MacVitals \(Int(memory.pressure * 100))%"
        case .usedMemory:
            return "MacVitals \(ByteText.format(memory.usedBytes))"
        case .cpu:
            return "MacVitals CPU \(cpu.activePercent.percentText)"
        case .compact:
            return "MV"
        }
    }

    var recommendations: [SystemRecommendation] {
        SystemRecommendation.make(for: self)
    }

    func diagnostics(history: [HistorySample]) -> [HealthDiagnostic] {
        HealthDiagnostic.make(stats: self, history: history)
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
        case (.balanced, true): 0.8
        case (.balanced, false): 3.0
        case (.lowPower, true): 1.5
        case (.lowPower, false): 8.0
        case (.responsive, true): 0.5
        case (.responsive, false): 1.5
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese
    case french
    case russian
    case german

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: L.t("language.system")
        case .english: "English"
        case .simplifiedChinese: "中文"
        case .french: "Français"
        case .russian: "Русский"
        case .german: "Deutsch"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .simplifiedChinese: "zh-Hans"
        case .french: "fr"
        case .russian: "ru"
        case .german: "de"
        }
    }
}

struct MonitorSettings {
    var menuBarDisplayMode: MenuBarDisplayMode
    var samplingMode: SamplingMode
    var appLanguage: AppLanguage
    var notificationsEnabled: Bool
    var memoryPressureThreshold: Double
    var swapThresholdBytes: UInt64

    static let defaults = MonitorSettings(
        menuBarDisplayMode: .memoryPressure,
        samplingMode: .balanced,
        appLanguage: .system,
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

struct ThermalStats {
    var state: ProcessInfo.ThermalState

    var title: String {
        switch state {
        case .nominal: L.t("thermal.nominal")
        case .fair: L.t("thermal.fair")
        case .serious: L.t("thermal.serious")
        case .critical: L.t("thermal.critical")
        @unknown default: L.t("thermal.unknown")
        }
    }

    var detail: String {
        switch state {
        case .nominal: L.t("thermal.nominal.detail")
        case .fair: L.t("thermal.fair.detail")
        case .serious: L.t("thermal.serious.detail")
        case .critical: L.t("thermal.critical.detail")
        @unknown default: L.t("thermal.unknown.detail")
        }
    }

    var symbolName: String {
        switch state {
        case .nominal: "thermometer.low"
        case .fair: "thermometer.medium"
        case .serious, .critical: "thermometer.high"
        @unknown default: "thermometer.variable"
        }
    }

    var severity: RecommendationSeverity {
        switch state {
        case .nominal: .healthy
        case .fair: .notice
        case .serious, .critical: .warning
        @unknown default: .notice
        }
    }

    static let empty = ThermalStats(state: .nominal)
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

enum RecommendationSeverity: Equatable {
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
        let thermalNeedsAttention = stats.thermal.severity != .healthy

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

        if thermalNeedsAttention {
            recommendations.append(
                SystemRecommendation(
                    id: "thermal-state",
                    severity: stats.thermal.severity,
                    title: String(format: L.t("recommendation.thermal.title"), stats.thermal.title),
                    detail: stats.thermal.detail
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

struct HealthDiagnostic: Identifiable {
    let id: String
    let severity: RecommendationSeverity
    let symbolName: String
    let title: String
    let detail: String
    let valueText: String

    static func make(stats: SystemStats, history: [HistorySample]) -> [HealthDiagnostic] {
        [
            healthScore(stats: stats),
            pressureTrend(history: history),
            bottleneck(stats: stats),
            powerLoad(stats: stats)
        ]
    }

    private static func healthScore(stats: SystemStats) -> HealthDiagnostic {
        let swapPressure = min(1, Double(stats.memory.swapUsedBytes) / Double(2 * 1024 * 1024 * 1024))
        let diskPressure = max(0, (stats.disk.usedPercent - 0.82) / 0.18)
        let thermalPenalty: Double

        switch stats.thermal.state {
        case .nominal: thermalPenalty = 0
        case .fair: thermalPenalty = 0.08
        case .serious: thermalPenalty = 0.18
        case .critical: thermalPenalty = 0.26
        @unknown default: thermalPenalty = 0.08
        }

        let risk =
            stats.memory.pressure * 0.42 +
            swapPressure * 0.22 +
            stats.cpu.activePercent * 0.18 +
            diskPressure * 0.10 +
            thermalPenalty

        let score = Int(max(0, min(100, (1 - risk) * 100)).rounded())
        let severity: RecommendationSeverity = score >= 72 ? .healthy : (score >= 48 ? .notice : .warning)

        return HealthDiagnostic(
            id: "health-score",
            severity: severity,
            symbolName: "gauge.medium",
            title: L.t("diagnostic.healthScore.title"),
            detail: L.t("diagnostic.healthScore.detail"),
            valueText: "\(score)"
        )
    }

    private static func pressureTrend(history: [HistorySample]) -> HealthDiagnostic {
        let values = history.map(\.memoryPressure)
        guard values.count >= 8 else {
            return HealthDiagnostic(
                id: "pressure-trend",
                severity: .healthy,
                symbolName: "chart.line.uptrend.xyaxis",
                title: L.t("diagnostic.trend.warming.title"),
                detail: L.t("diagnostic.trend.warming.detail"),
                valueText: "--"
            )
        }

        let window = min(16, values.count / 2)
        let recent = average(Array(values.suffix(window)))
        let previous = average(Array(values.dropLast(window).suffix(window)))
        let delta = recent - previous

        if delta >= 0.08 {
            return HealthDiagnostic(
                id: "pressure-trend",
                severity: .notice,
                symbolName: "arrow.up.right",
                title: L.t("diagnostic.trend.rising.title"),
                detail: String(format: L.t("diagnostic.trend.rising.detail"), abs(delta).percentText),
                valueText: "+\(abs(delta).percentText)"
            )
        }

        if delta <= -0.08 {
            return HealthDiagnostic(
                id: "pressure-trend",
                severity: .healthy,
                symbolName: "arrow.down.right",
                title: L.t("diagnostic.trend.easing.title"),
                detail: String(format: L.t("diagnostic.trend.easing.detail"), abs(delta).percentText),
                valueText: "-\(abs(delta).percentText)"
            )
        }

        return HealthDiagnostic(
            id: "pressure-trend",
            severity: .healthy,
            symbolName: "equal",
            title: L.t("diagnostic.trend.stable.title"),
            detail: L.t("diagnostic.trend.stable.detail"),
            valueText: "0%"
        )
    }

    private static func bottleneck(stats: SystemStats) -> HealthDiagnostic {
        let swapPressure = min(1, Double(stats.memory.swapUsedBytes) / Double(2 * 1024 * 1024 * 1024))
        let memoryScore = stats.memory.pressure + swapPressure * 0.5
        let cpuScore = stats.cpu.activePercent
        let diskScore = stats.disk.usedPercent >= 0.9 ? stats.disk.usedPercent : 0
        let thermalScore: Double

        switch stats.thermal.state {
        case .nominal: thermalScore = 0
        case .fair: thermalScore = 0.72
        case .serious: thermalScore = 0.92
        case .critical: thermalScore = 1
        @unknown default: thermalScore = 0.5
        }

        let candidates = [
            ("memory", memoryScore),
            ("cpu", cpuScore),
            ("disk", diskScore),
            ("thermal", thermalScore)
        ]
        let top = candidates.max { $0.1 < $1.1 } ?? ("none", 0)

        guard top.1 >= 0.72 else {
            return HealthDiagnostic(
                id: "bottleneck",
                severity: .healthy,
                symbolName: "checkmark.seal",
                title: L.t("diagnostic.bottleneck.none.title"),
                detail: L.t("diagnostic.bottleneck.none.detail"),
                valueText: L.t("diagnostic.bottleneck.none.value")
            )
        }

        let severity: RecommendationSeverity = top.1 >= 0.9 ? .warning : .notice
        let valueText: String

        switch top.0 {
        case "memory":
            valueText = stats.memory.pressure.percentText
        case "cpu":
            valueText = stats.cpu.activePercent.percentText
        case "disk":
            valueText = ByteText.format(stats.disk.freeBytes)
        default:
            valueText = stats.thermal.title
        }

        return HealthDiagnostic(
            id: "bottleneck",
            severity: severity,
            symbolName: symbolName(for: top.0),
            title: L.t("diagnostic.bottleneck.\(top.0).title"),
            detail: L.t("diagnostic.bottleneck.\(top.0).detail"),
            valueText: valueText
        )
    }

    private static func powerLoad(stats: SystemStats) -> HealthDiagnostic {
        let networkLoad = min(1, Double(stats.network.receivedBytesPerSecond + stats.network.sentBytesPerSecond) / 20_000_000)
        let thermalLoad: Double

        switch stats.thermal.state {
        case .nominal: thermalLoad = 0
        case .fair: thermalLoad = 0.35
        case .serious: thermalLoad = 0.75
        case .critical: thermalLoad = 1
        @unknown default: thermalLoad = 0.25
        }

        let load = stats.cpu.activePercent * 0.65 + thermalLoad * 0.25 + networkLoad * 0.10

        if load >= 0.72 {
            return HealthDiagnostic(
                id: "power-load",
                severity: .notice,
                symbolName: "bolt.fill",
                title: L.t("diagnostic.power.high.title"),
                detail: L.t("diagnostic.power.high.detail"),
                valueText: load.percentText
            )
        }

        if load >= 0.42 {
            return HealthDiagnostic(
                id: "power-load",
                severity: .healthy,
                symbolName: "bolt",
                title: L.t("diagnostic.power.moderate.title"),
                detail: L.t("diagnostic.power.moderate.detail"),
                valueText: load.percentText
            )
        }

        return HealthDiagnostic(
            id: "power-load",
            severity: .healthy,
            symbolName: "leaf",
            title: L.t("diagnostic.power.low.title"),
            detail: L.t("diagnostic.power.low.detail"),
            valueText: load.percentText
        )
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func symbolName(for bottleneck: String) -> String {
        switch bottleneck {
        case "memory": "memorychip"
        case "cpu": "cpu"
        case "disk": "internaldrive"
        case "thermal": "thermometer.high"
        default: "checkmark.seal"
        }
    }
}
