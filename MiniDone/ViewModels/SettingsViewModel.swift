import Foundation

enum SettingsViewModel {
    static func language(from rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .russian
    }

    static func theme(from rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .system
    }
}
