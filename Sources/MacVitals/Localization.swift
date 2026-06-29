import Foundation

enum L {
    private static let languageKey = "appLanguage"

    static func t(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: currentBundle, comment: "")
    }

    static func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
    }

    private static var currentBundle: Bundle {
        let rawValue = UserDefaults.standard.string(forKey: languageKey) ?? AppLanguage.system.rawValue
        let language = AppLanguage(rawValue: rawValue) ?? .system
        guard
            let localeIdentifier = language.localeIdentifier,
            let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }
}
