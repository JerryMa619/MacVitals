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
                        launchAtLoginEnabled: monitor.launchAtLoginEnabled,
                        settingsError: monitor.settingsError
                    ) { enabled in
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
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Spacer()

            Button {
                monitor.openActivityMonitor()
            } label: {
                Label("Activity Monitor", systemImage: "waveform.path.ecg")
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
            MetricRing(title: "Memory", value: stats.memory.pressure, detail: ByteText.format(stats.memory.usedBytes))
            MetricRing(title: "CPU", value: stats.cpu.activePercent, detail: stats.cpu.activePercent.percentText)
            MetricRing(title: "Disk", value: stats.disk.usedPercent, detail: ByteText.format(stats.disk.freeBytes))
        }
    }
}

private struct MemorySection: View {
    let memory: MemoryStats

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Memory")
            ProgressView(value: memory.pressure)
                .tint(color(for: memory.pressure))
            VStack(spacing: 8) {
                StatRow("App", ByteText.format(memory.appBytes))
                StatRow("Wired", ByteText.format(memory.wiredBytes))
                StatRow("Compressed", ByteText.format(memory.compressedBytes))
                StatRow("Cached", ByteText.format(memory.cachedBytes))
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
            SectionTitle("Hardware")
            StatRow("CPU", "\(stats.cpu.activePercent.percentText) active")
            StatRow("Disk free", ByteText.format(stats.disk.freeBytes))
            StatRow("Battery", batteryText)
            StatRow("Network down", ByteText.rate(stats.network.receivedBytesPerSecond))
            StatRow("Network up", ByteText.rate(stats.network.sentBytesPerSecond))
        }
        .panelStyle()
    }

    private var batteryText: String {
        guard let percent = stats.battery.percent else {
            return stats.battery.powerSource
        }
        let charging = stats.battery.isCharging ? " charging" : ""
        return "\(percent.percentText)\(charging)"
    }
}

private struct ProcessSection: View {
    let processes: [ProcessStats]
    let openActivityMonitor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle("Heavy Apps")
                Spacer()
                Button(action: openActivityMonitor) {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.borderless)
                .help("Open Activity Monitor")
            }

            if processes.isEmpty {
                Text("No running app data available.")
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
    let launchAtLoginEnabled: Bool
    let settingsError: String?
    let setLaunchAtLoginEnabled: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Preferences")
            Toggle(isOn: Binding(
                get: { launchAtLoginEnabled },
                set: { newValue in
                    setLaunchAtLoginEnabled(newValue)
                }
            )) {
                Label("Launch at Login", systemImage: "power")
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
        case 0..<0.65: "Healthy"
        case 0..<0.82: "Busy"
        default: "Tight"
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
