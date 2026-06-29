import SwiftUI

struct OnboardingView: View {
    let complete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(spacing: 14) {
                OnboardingFact(
                    icon: "memorychip",
                    title: L.t("onboarding.monitoring.title"),
                    detail: L.t("onboarding.monitoring.detail")
                )
                OnboardingFact(
                    icon: "lock.shield",
                    title: L.t("onboarding.privacy.title"),
                    detail: L.t("onboarding.privacy.detail")
                )
                OnboardingFact(
                    icon: "hand.raised",
                    title: L.t("onboarding.control.title"),
                    detail: L.t("onboarding.control.detail")
                )
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            Spacer()

            Divider()

            HStack {
                Text(L.t("onboarding.footer"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L.t("onboarding.done"), action: complete)
                    .buttonStyle(.borderedProminent)
            }
            .padding(18)
        }
        .frame(width: 480, height: 390)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.green)
                Text("MacVitals")
                    .font(.system(size: 24, weight: .semibold))
            }

            Text(L.t("onboarding.subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct OnboardingFact: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
