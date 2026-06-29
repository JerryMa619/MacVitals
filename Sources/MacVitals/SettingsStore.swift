import Foundation

struct SettingsStore {
    private enum Key {
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let notificationsEnabled = "notificationsEnabled"
        static let memoryPressureThreshold = "memoryPressureThreshold"
        static let swapThresholdBytes = "swapThresholdBytes"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> MonitorSettings {
        let fallback = MonitorSettings.defaults
        let modeRawValue = defaults.string(forKey: Key.menuBarDisplayMode) ?? fallback.menuBarDisplayMode.rawValue
        let mode = MenuBarDisplayMode(rawValue: modeRawValue) ?? fallback.menuBarDisplayMode
        let memoryThreshold = defaults.object(forKey: Key.memoryPressureThreshold) as? Double ?? fallback.memoryPressureThreshold
        let swapThreshold = (defaults.object(forKey: Key.swapThresholdBytes) as? NSNumber)?.uint64Value ?? fallback.swapThresholdBytes

        return MonitorSettings(
            menuBarDisplayMode: mode,
            notificationsEnabled: defaults.bool(forKey: Key.notificationsEnabled),
            memoryPressureThreshold: memoryThreshold,
            swapThresholdBytes: swapThreshold
        )
    }

    func save(_ settings: MonitorSettings) {
        defaults.set(settings.menuBarDisplayMode.rawValue, forKey: Key.menuBarDisplayMode)
        defaults.set(settings.notificationsEnabled, forKey: Key.notificationsEnabled)
        defaults.set(settings.memoryPressureThreshold, forKey: Key.memoryPressureThreshold)
        defaults.set(NSNumber(value: settings.swapThresholdBytes), forKey: Key.swapThresholdBytes)
    }
}
