import SwiftUI

enum VitalsTheme {
    static let backgroundTop = Color(red: 0.03, green: 0.05, blue: 0.08)
    static let backgroundBottom = Color(red: 0.005, green: 0.015, blue: 0.03)
    static let panel = Color.white.opacity(0.065)
    static let panelStrong = Color.white.opacity(0.105)
    static let line = Color.white.opacity(0.12)
    static let mutedLine = Color.white.opacity(0.07)
    static let accent = Color(nsColor: .controlAccentColor)
    static let glow = Color.cyan.opacity(0.38)
}

struct VitalsBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [VitalsTheme.backgroundTop, VitalsTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GridOverlay()
                .stroke(VitalsTheme.mutedLine, lineWidth: 0.6)
                .opacity(0.65)

            LinearGradient(
                colors: [.clear, VitalsTheme.accent.opacity(0.16), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

private struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 28

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

struct ChartGrid: Shape {
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

extension View {
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

struct VitalsButtonStyle: ButtonStyle {
    enum Role {
        case normal
        case destructive
    }

    var role: Role = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(role == .destructive ? Color.red.opacity(0.95) : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(buttonFill(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule()
                    .stroke(buttonStroke, lineWidth: 1)
            )
            .shadow(color: glowColor.opacity(configuration.isPressed ? 0.12 : 0.28), radius: 10, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private func buttonFill(isPressed: Bool) -> Color {
        switch role {
        case .normal:
            return VitalsTheme.accent.opacity(isPressed ? 0.52 : 0.34)
        case .destructive:
            return Color.red.opacity(isPressed ? 0.22 : 0.14)
        }
    }

    private var buttonStroke: Color {
        switch role {
        case .normal:
            return VitalsTheme.accent.opacity(0.72)
        case .destructive:
            return Color.red.opacity(0.55)
        }
    }

    private var glowColor: Color {
        role == .destructive ? .red : VitalsTheme.accent
    }
}

struct VitalsIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 28, height: 28)
            .foregroundStyle(.white.opacity(0.88))
            .background(
                Circle()
                    .fill(VitalsTheme.panelStrong.opacity(configuration.isPressed ? 0.65 : 1))
            )
            .overlay(Circle().stroke(VitalsTheme.line, lineWidth: 1))
    }
}
