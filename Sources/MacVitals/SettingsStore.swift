import Foundation

struct SettingsStore {
    private enum Key {
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let samplingMode = "samplingMode"
        static let appLanguage = "appLanguage"
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
        let samplingModeRawValue = defaults.string(forKey: Key.samplingMode) ?? fallback.samplingMode.rawValue
        let samplingMode = SamplingMode(rawValue: samplingModeRawValue) ?? fallback.samplingMode
        let appLanguageRawValue = defaults.string(forKey: Key.appLanguage) ?? fallback.appLanguage.rawValue
        let appLanguage = AppLanguage(rawValue: appLanguageRawValue) ?? fallback.appLanguage
        let memoryThreshold = defaults.object(forKey: Key.memoryPressureThreshold) as? Double ?? fallback.memoryPressureThreshold
        let swapThreshold = (defaults.object(forKey: Key.swapThresholdBytes) as? NSNumber)?.uint64Value ?? fallback.swapThresholdBytes

        return MonitorSettings(
            menuBarDisplayMode: mode,
            samplingMode: samplingMode,
            appLanguage: appLanguage,
            notificationsEnabled: defaults.bool(forKey: Key.notificationsEnabled),
            memoryPressureThreshold: memoryThreshold,
            swapThresholdBytes: swapThreshold
        )
    }

    func save(_ settings: MonitorSettings) {
        defaults.set(settings.menuBarDisplayMode.rawValue, forKey: Key.menuBarDisplayMode)
        defaults.set(settings.samplingMode.rawValue, forKey: Key.samplingMode)
        defaults.set(settings.appLanguage.rawValue, forKey: Key.appLanguage)
        defaults.set(settings.notificationsEnabled, forKey: Key.notificationsEnabled)
        defaults.set(settings.memoryPressureThreshold, forKey: Key.memoryPressureThreshold)
        defaults.set(NSNumber(value: settings.swapThresholdBytes), forKey: Key.swapThresholdBytes)
    }
}
