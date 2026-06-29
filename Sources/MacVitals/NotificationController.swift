import Foundation
import UserNotifications

@MainActor
final class NotificationController {
    private var wasMemoryHigh = false
    private var wasSwapHigh = false

    func evaluate(stats: SystemStats, settings: MonitorSettings) {
        guard settings.notificationsEnabled else {
            wasMemoryHigh = false
            wasSwapHigh = false
            return
        }

        let isMemoryHigh = stats.memory.pressure >= settings.memoryPressureThreshold
        if isMemoryHigh && !wasMemoryHigh {
            deliver(
                title: L.t("notification.memory.title"),
                body: String(
                    format: L.t("notification.memory.body"),
                    Int(stats.memory.pressure * 100),
                    ByteText.format(stats.memory.swapUsedBytes)
                )
            )
        }
        wasMemoryHigh = isMemoryHigh

        let isSwapHigh = stats.memory.swapUsedBytes >= settings.swapThresholdBytes
        if isSwapHigh && !wasSwapHigh {
            deliver(
                title: L.t("notification.swap.title"),
                body: String(
                    format: L.t("notification.swap.body"),
                    ByteText.format(stats.memory.swapUsedBytes)
                )
            )
        }
        wasSwapHigh = isSwapHigh
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    private func deliver(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "macvitals-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
