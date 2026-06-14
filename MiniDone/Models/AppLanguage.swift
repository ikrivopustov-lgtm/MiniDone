import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var title: String {
        switch self {
        case .russian:
            "Русский"
        case .english:
            "English"
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum SidebarSelection: Hashable {
    case allTasks
    case today
    case completed
    case project(String)
    case settings
}
