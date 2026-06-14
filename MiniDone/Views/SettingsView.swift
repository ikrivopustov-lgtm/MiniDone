import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.StorageKeys.language) private var languageRawValue = AppLanguage.russian.rawValue
    @AppStorage(Constants.StorageKeys.theme) private var themeRawValue = AppTheme.system.rawValue
    @AppStorage(Constants.StorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    private var language: AppLanguage {
        SettingsViewModel.language(from: languageRawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(LocalizationService.text(.settings, language: language))
                .font(AppStyle.font(20, .semibold))
                .foregroundStyle(AppStyle.primaryText)

            VStack(spacing: 0) {
                SettingsPickerRow(
                    title: LocalizationService.text(.language, language: language),
                    selection: $languageRawValue,
                    options: [
                        (LocalizationService.text(.russian, language: language), AppLanguage.russian.rawValue),
                        (LocalizationService.text(.english, language: language), AppLanguage.english.rawValue)
                    ],
                    controlWidth: 190,
                    accessibilityIdentifier: "languagePicker"
                )

                Divider()
                    .overlay(AppStyle.divider)

                SettingsPickerRow(
                    title: LocalizationService.text(.appearance, language: language),
                    selection: $themeRawValue,
                    options: [
                        (LocalizationService.text(.themeSystem, language: language), AppTheme.system.rawValue),
                        (LocalizationService.text(.themeLight, language: language), AppTheme.light.rawValue),
                        (LocalizationService.text(.themeDark, language: language), AppTheme.dark.rawValue)
                    ],
                    controlWidth: 240,
                    accessibilityIdentifier: "themePicker"
                )

                Divider()
                    .overlay(AppStyle.divider)

                SettingsActionRow(
                    title: LocalizationService.text(.onboardingShowAgain, language: language),
                    systemImage: "questionmark.circle",
                    accessibilityIdentifier: "showOnboardingButton"
                ) {
                    hasCompletedOnboarding = false
                }
            }
            .background(AppStyle.rowBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppStyle.fieldBorder, lineWidth: 0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 310)
        .background(AppStyle.windowBackground)
    }
}

private struct SettingsPickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [(title: String, value: String)]
    let controlWidth: CGFloat
    let accessibilityIdentifier: String

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(AppStyle.font(13, .semibold))
                .foregroundStyle(AppStyle.primaryText)

            Spacer()

            SettingsSegmentedControl(selection: $selection, options: options)
            .frame(width: controlWidth)
            .accessibilityIdentifier(accessibilityIdentifier)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct SettingsActionRow: View {
    let title: String
    let systemImage: String
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(AppStyle.font(13, .semibold))
                .foregroundStyle(AppStyle.primaryText)

            Spacer()

            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(AppStyle.panelBackground, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppStyle.fieldBorder, lineWidth: 0.7)
                    }
            }
            .buttonStyle(.plain)
            .help(title)
            .accessibilityIdentifier(accessibilityIdentifier)
            .accessibilityLabel(title)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct SettingsSegmentedControl: View {
    @Binding var selection: String
    let options: [(title: String, value: String)]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.value) { option in
                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(AppStyle.font(12, selection == option.value ? .semibold : .medium))
                        .foregroundStyle(selection == option.value ? AppStyle.primaryText : AppStyle.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(selection == option.value ? AppStyle.selectionBackground : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .appFieldBackground(cornerRadius: 9)
    }
}
