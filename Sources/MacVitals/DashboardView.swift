import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    let openSettings: () -> Void

    var body: some View {
        ZStack {
            VitalsBackdrop()

            VStack(spacing: 0) {
                header
                Divider()
                    .overlay(VitalsTheme.line)
                ScrollView {
                    VStack(spacing: 16) {
                        OverviewSection(stats: monitor.stats)
                        TrendSection(history: monitor.history)
                        RecommendationSection(recommendations: monitor.stats.recommendations)
                        MemorySection(memory: monitor.stats.memory)
                        HardwareSection(stats: monitor.stats)
                        DiagnosticsSection(snapshotStatus: monitor.snapshotStatus) {
                            monitor.copyDiagnosticSnapshot()
                        }
                        ProcessSection(processes: monitor.stats.processes) {
                            monitor.openActivityMonitor()
                        }
                    }
                    .padding(18)
                }
                Divider()
                    .overlay(VitalsTheme.line)
                footer
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            monitor.setFocused(true)
        }
        .onDisappear {
            monitor.setFocused(false)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacVitals")
                    .font(.system(size: 22, weight: .bold))
                Text(monitor.stats.sampledAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
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
            .buttonStyle(VitalsButtonStyle())

            Spacer()

            Button {
                openSettings()
            } label: {
                Label(L.t("action.settings"), systemImage: "gearshape")
            }
            .buttonStyle(VitalsButtonStyle())

            Button {
                monitor.openActivityMonitor()
            } label: {
                Label(L.t("action.activityMonitor"), systemImage: "waveform.path.ecg")
            }
            .buttonStyle(VitalsButtonStyle())
        }
        .padding(12)
    }
}

private struct RecommendationSection: View {
    let recommendations: [SystemRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(L.t("section.recommendations"))

            VStack(spacing: 8) {
                ForEach(recommendations) { recommendation in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: recommendation.severity.symbolName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(color(for: recommendation.severity))
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(recommendation.title)
                                .font(.system(size: 12, weight: .medium))
                            Text(recommendation.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .panelStyle()
    }

    private func color(for severity: RecommendationSeverity) -> Color {
        switch severity {
        case .healthy: .green
        case .notice: .blue
        case .warning: .orange
        }
    }
}

private struct DiagnosticsSection: View {
    let snapshotStatus: String?
    let copySnapshot: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                SectionTitle(L.t("section.diagnostics"))
                Text(L.t("diagnostics.snapshotHelp"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let snapshotStatus {
                Text(snapshotStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: copySnapshot) {
                Label(L.t("action.copySnapshot"), systemImage: "doc.on.doc")
            }
            .buttonStyle(VitalsButtonStyle())
        }
        .panelStyle()
    }
}

private struct TrendSection: View {
    let history: [HistorySample]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(L.t("section.trends"))
                Spacer()
                Text(L.t("trends.window"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 12) {
                TrendChart(
                    title: L.t("metric.memory"),
                    value: history.last?.memoryPressure ?? 0,
                    values: history.map(\.memoryPressure),
                    tint: .green,
                    valueText: (history.last?.memoryPressure ?? 0).percentText
                )
                TrendChart(
                    title: "CPU",
                    value: history.last?.cpuActive ?? 0,
                    values: history.map(\.cpuActive),
                    tint: .blue,
                    valueText: (history.last?.cpuActive ?? 0).percentText
                )
                TrendChart(
                    title: "Swap",
                    value: normalizedSwap,
                    values: normalizedSwapHistory,
                    tint: .orange,
                    valueText: ByteText.format(history.last?.swapUsedBytes ?? 0)
                )
            }
        }
        .panelStyle(padding: 14)
    }

    private var normalizedSwapHistory: [Double] {
        let maxSwap = max(history.map(\.swapUsedBytes).max() ?? 0, 1)
        return history.map { Double($0.swapUsedBytes) / Double(maxSwap) }
    }

    private var normalizedSwap: Double {
        normalizedSwapHistory.last ?? 0
    }
}

private struct TrendChart: View {
    let title: String
    let value: Double
    let values: [Double]
    let tint: Color
    let valueText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.95))
                    .monospacedDigit()
            }

            Sparkline(values: values, tint: tint)
                .frame(height: 78)
                .accessibilityLabel(title)
                .accessibilityValue(valueText)
        }
    }
}

private struct Sparkline: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let points = chartPoints(size: proxy.size)

            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(VitalsTheme.mutedLine, lineWidth: 1)
                    )
                ChartGrid()
                    .stroke(tint.opacity(0.12), lineWidth: 0.7)
                    .padding(6)

                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: size.height))
                        for point in points {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.28), tint.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(tint.opacity(0.98), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .shadow(color: tint.opacity(0.65), radius: 8)
                } else {
                    Capsule()
                        .fill(tint.opacity(0.35))
                        .frame(width: 28, height: 4)
                }
            }
        }
    }

    private func chartPoints(size: CGSize) -> [CGPoint] {
        guard !values.isEmpty, size.width > 0, size.height > 0 else { return [] }
        let clipped = values.map { min(1, max(0, $0)) }
        let step = clipped.count > 1 ? size.width / CGFloat(clipped.count - 1) : 0

        return clipped.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * step,
                y: size.height - (CGFloat(value) * size.height)
            )
        }
    }
}

private struct ChartGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let verticalDivisions = 6
        let horizontalDivisions = 3

        for index in 1..<verticalDivisions {
            let x = rect.minX + rect.width * CGFloat(index) / CGFloat(verticalDivisions)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        for index in 1...horizontalDivisions {
            let y = rect.minY + rect.height * CGFloat(index) / CGFloat(horizontalDivisions + 1)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private struct OverviewSection: View {
    let stats: SystemStats

    var body: some View {
        HStack(spacing: 14) {
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

private struct MetricRing: View {
    let title: String
    let value: Double
    let detail: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(VitalsTheme.mutedLine, lineWidth: 9)

                Circle()
                    .trim(from: 0, to: min(1, max(0, value)))
                    .stroke(
                        AngularGradient(
                            colors: [tint.opacity(0.25), tint, .white.opacity(0.9), tint],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint.opacity(0.7), radius: 9)

                Circle()
                    .stroke(tint.opacity(0.16), lineWidth: 1)
                    .padding(12)

                VStack(spacing: 1) {
                    Text(value.percentText)
                        .font(.system(size: 19, weight: .bold))
                        .monospacedDigit()
                    Text(title.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
            .frame(width: 92, height: 92)

            Text(detail)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(VitalsTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.24), radius: 14, y: 5)
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
        .background(VitalsTheme.panelStrong)
        .overlay(Capsule().stroke(color.opacity(0.42), lineWidth: 1))
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
            .foregroundStyle(.white.opacity(0.92))
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
    func panelStyle(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VitalsTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(VitalsTheme.line, lineWidth: 1)
            )
            .shadow(color: VitalsTheme.glow.opacity(0.12), radius: 12, y: 5)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
