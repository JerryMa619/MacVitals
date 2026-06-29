import SwiftUI

struct MenuBarVitalsView: View {
    @EnvironmentObject private var monitor: SystemMonitor
    let openDashboard: () -> Void

    var body: some View {
        ZStack {
            VitalsBackdrop()

            VStack(alignment: .leading, spacing: 14) {
                header
                primaryGauge
                miniMetrics
                miniTrend
                topInsight
                actions
            }
            .padding(18)
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
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("MacVitals")
                    .font(.system(size: 19, weight: .bold))
                Text(monitor.stats.sampledAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
            }
            Spacer()
            Image(systemName: statusSymbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(statusColor)
                .shadow(color: statusColor.opacity(0.55), radius: 8)
        }
    }

    private var primaryGauge: some View {
        HStack(spacing: 16) {
            MiniArc(value: monitor.stats.memory.pressure, tint: statusColor)
                .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 8) {
                Text(L.t("metric.memory").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.48))
                Text(monitor.stats.memory.pressure.percentText)
                    .font(.system(size: 34, weight: .bold))
                    .monospacedDigit()
                Text(ByteText.format(monitor.stats.memory.usedBytes))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
            }
            Spacer()
        }
        .panelStyle(padding: 14)
    }

    private var miniMetrics: some View {
        HStack(spacing: 10) {
            MiniMetric(title: "CPU", value: monitor.stats.cpu.activePercent.percentText, tint: .blue)
            MiniMetric(title: L.t("hardware.thermal"), value: monitor.stats.thermal.title, tint: thermalColor)
            MiniMetric(title: L.t("metric.disk"), value: ByteText.format(monitor.stats.disk.freeBytes), tint: .purple)
        }
    }

    private var miniTrend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.t("menu.trend"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            MiniSparkline(values: monitor.history.map(\.memoryPressure), tint: statusColor)
                .frame(height: 52)
        }
        .panelStyle(padding: 12)
    }

    private var topInsight: some View {
        let recommendation = monitor.stats.recommendations.first

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: recommendation?.severity.symbolName ?? "checkmark.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(recommendationColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation?.title ?? L.t("recommendation.healthy.title"))
                    .font(.system(size: 13, weight: .semibold))
                Text(recommendation?.detail ?? L.t("recommendation.healthy.detail"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(3)
            }
        }
        .panelStyle(padding: 12)
    }

    private var actions: some View {
        HStack {
            Button {
                monitor.refreshNow()
            } label: {
                Label(L.t("action.refresh"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(VitalsButtonStyle())

            Spacer()

            Button(action: openDashboard) {
                Label(L.t("action.dashboard"), systemImage: "rectangle.inset.filled")
            }
            .buttonStyle(VitalsButtonStyle())
        }
    }

    private var statusColor: Color {
        switch monitor.stats.memory.pressure {
        case 0..<0.65: .green
        case 0..<0.82: .orange
        default: .red
        }
    }

    private var statusSymbol: String {
        switch monitor.stats.memory.pressure {
        case 0..<0.65: "checkmark.seal"
        case 0..<0.82: "waveform.path.ecg"
        default: "exclamationmark.triangle"
        }
    }

    private var recommendationColor: Color {
        guard let severity = monitor.stats.recommendations.first?.severity else { return .green }
        switch severity {
        case .healthy: return .green
        case .notice: return .blue
        case .warning: return .orange
        }
    }

    private var thermalColor: Color {
        switch monitor.stats.thermal.severity {
        case .healthy: return .green
        case .notice: return .orange
        case .warning: return .red
        }
    }
}

private struct MiniMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.42))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(VitalsTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.36), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MiniArc: View {
    let value: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(VitalsTheme.mutedLine, lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(1, max(0, value)))
                .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.65), radius: 10)
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: 1)
                .padding(15)
        }
    }
}

private struct MiniSparkline: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let points = chartPoints(size: proxy.size)

            ZStack {
                ChartGrid()
                    .stroke(tint.opacity(0.1), lineWidth: 0.7)

                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(tint.opacity(0.96), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: tint.opacity(0.58), radius: 7)
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
