import Foundation

enum L {
    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), table: "Localizable")
    }
}
