import SwiftUI

struct AppSceneRoot<Content: View>: View {
    @AppStorage(Constants.StorageKeys.language) private var languageRawValue = AppLanguage.russian.rawValue
    @AppStorage(Constants.StorageKeys.theme) private var themeRawValue = AppTheme.system.rawValue

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var language: AppLanguage {
        SettingsViewModel.language(from: languageRawValue)
    }

    private var theme: AppTheme {
        SettingsViewModel.theme(from: themeRawValue)
    }

    var body: some View {
        content
            .environment(\.locale, language.locale)
            .preferredColorScheme(theme.colorScheme)
    }
}
