import Foundation

enum DiagnosticSnapshot {
    static func make(stats: SystemStats, history: [HistorySample]) -> String {
        var lines: [String] = []
        lines.append("MacVitals Diagnostic Snapshot")
        lines.append("Generated: \(dateFormatter.string(from: stats.sampledAt))")
        lines.append("")
        lines.append("Summary")
        lines.append("- Memory pressure: \(stats.memory.pressure.percentText)")
        lines.append("- CPU active: \(stats.cpu.activePercent.percentText)")
        lines.append("- Swap used: \(ByteText.format(stats.memory.swapUsedBytes))")
        lines.append("- Disk free: \(ByteText.format(stats.disk.freeBytes))")
        lines.append("- Battery: \(batteryText(stats.battery))")
        lines.append("- Network down: \(ByteText.rate(stats.network.receivedBytesPerSecond))")
        lines.append("- Network up: \(ByteText.rate(stats.network.sentBytesPerSecond))")
        lines.append("")
        lines.append("Memory")
        lines.append("- Total: \(ByteText.format(stats.memory.totalBytes))")
        lines.append("- Used: \(ByteText.format(stats.memory.usedBytes))")
        lines.append("- App: \(ByteText.format(stats.memory.appBytes))")
        lines.append("- Wired: \(ByteText.format(stats.memory.wiredBytes))")
        lines.append("- Compressed: \(ByteText.format(stats.memory.compressedBytes))")
        lines.append("- Cached: \(ByteText.format(stats.memory.cachedBytes))")
        lines.append("- Free: \(ByteText.format(stats.memory.freeBytes))")
        lines.append("")
        lines.append("Recent Trend")
        lines.append("- Samples: \(history.count)")
        lines.append("- Average memory pressure: \(average(history.map(\.memoryPressure)).percentText)")
        lines.append("- Peak memory pressure: \((history.map(\.memoryPressure).max() ?? 0).percentText)")
        lines.append("- Average CPU active: \(average(history.map(\.cpuActive)).percentText)")
        lines.append("- Peak CPU active: \((history.map(\.cpuActive).max() ?? 0).percentText)")
        lines.append("- Peak swap: \(ByteText.format(history.map(\.swapUsedBytes).max() ?? 0))")
        lines.append("")
        lines.append("Heavy Apps")

        if stats.processes.isEmpty {
            lines.append("- No running app data available.")
        } else {
            for process in stats.processes {
                lines.append("- \(process.name): \(ByteText.format(process.memoryBytes))")
            }
        }

        lines.append("")
        lines.append("Note: This snapshot is generated locally and is not uploaded by MacVitals.")
        return lines.joined(separator: "\n")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func batteryText(_ battery: BatteryStats) -> String {
        guard let percent = battery.percent else {
            return battery.powerSource
        }

        let charging = battery.isCharging ? " charging" : ""
        return "\(percent.percentText)\(charging)"
    }
}
