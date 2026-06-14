import AppKit
import SwiftUI

enum AppStyle {
    static let windowBackground = adaptive(
        light: NSColor(calibratedWhite: 0.965, alpha: 1),
        dark: NSColor(calibratedWhite: 0.105, alpha: 1)
    )
    static let sidebarBackground = adaptive(
        light: NSColor(calibratedWhite: 0.925, alpha: 1),
        dark: NSColor(calibratedWhite: 0.135, alpha: 1)
    )
    static let panelBackground = adaptive(
        light: NSColor(calibratedWhite: 0.985, alpha: 1),
        dark: NSColor(calibratedWhite: 0.165, alpha: 1)
    )
    static let fieldBackground = adaptive(
        light: NSColor(calibratedWhite: 0.995, alpha: 1),
        dark: NSColor(calibratedWhite: 0.155, alpha: 1)
    )
    static let fieldBorder = adaptive(
        light: NSColor(calibratedWhite: 0.78, alpha: 1),
        dark: NSColor(calibratedWhite: 0.31, alpha: 1)
    )
    static let fieldFocusedBorder = adaptive(
        light: NSColor(calibratedRed: 0.23, green: 0.48, blue: 0.78, alpha: 1),
        dark: NSColor(calibratedRed: 0.43, green: 0.68, blue: 0.96, alpha: 1)
    )
    static let selectionBackground = adaptive(
        light: NSColor(calibratedRed: 0.84, green: 0.91, blue: 1.0, alpha: 1),
        dark: NSColor(calibratedRed: 0.17, green: 0.23, blue: 0.31, alpha: 1)
    )
    static let rowBackground = adaptive(
        light: NSColor(calibratedWhite: 0.985, alpha: 1),
        dark: NSColor(calibratedWhite: 0.145, alpha: 1)
    )
    static let rowHoverBackground = adaptive(
        light: NSColor(calibratedWhite: 0.93, alpha: 1),
        dark: NSColor(calibratedWhite: 0.20, alpha: 1)
    )
    static let divider = adaptive(
        light: NSColor(calibratedWhite: 0.78, alpha: 1),
        dark: NSColor(calibratedWhite: 0.27, alpha: 1)
    )
    static let primaryText = Color.primary
    static let secondaryText = adaptive(
        light: NSColor(calibratedWhite: 0.34, alpha: 1),
        dark: NSColor(calibratedWhite: 0.72, alpha: 1)
    )
    static let mutedText = adaptive(
        light: NSColor(calibratedWhite: 0.42, alpha: 1),
        dark: NSColor(calibratedWhite: 0.58, alpha: 1)
    )
    static let green = adaptive(
        light: NSColor(calibratedRed: 0.10, green: 0.50, blue: 0.27, alpha: 1),
        dark: NSColor(calibratedRed: 0.29, green: 0.78, blue: 0.51, alpha: 1)
    )
    static let danger = adaptive(
        light: NSColor(calibratedRed: 0.70, green: 0.18, blue: 0.16, alpha: 1),
        dark: NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.44, alpha: 1)
    )
    static let warningText = adaptive(
        light: NSColor(calibratedRed: 0.62, green: 0.22, blue: 0.08, alpha: 1),
        dark: NSColor(calibratedRed: 1.0, green: 0.66, blue: 0.42, alpha: 1)
    )
    static let warningBackground = adaptive(
        light: NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.82, alpha: 1),
        dark: NSColor(calibratedRed: 0.31, green: 0.17, blue: 0.11, alpha: 1)
    )
    static let blue = Color(red: 0.36, green: 0.62, blue: 0.94)
    static let mint = Color(red: 0.28, green: 0.72, blue: 0.58)
    static let pink = Color(red: 0.84, green: 0.34, blue: 0.55)
    static let cream = Color(red: 0.96, green: 0.82, blue: 0.55)
    static let purple = Color(red: 0.62, green: 0.52, blue: 0.94)
    static let projectColors = [blue, mint, pink, cream, purple]

    static func font(_ size: CGFloat, _ weight: FontWeight = .regular) -> Font {
        .system(size: size, weight: weight.systemWeight, design: .default)
    }

    enum FontWeight {
        case regular
        case medium
        case semiBold
        case semibold
        case bold

        var systemWeight: Font.Weight {
            switch self {
            case .regular:
                .regular
            case .medium:
                .medium
            case .semiBold, .semibold:
                .semibold
            case .bold:
                .bold
            }
        }
    }

    static func projectColor(for name: String) -> Color {
        projectColors[projectColorIndex(for: name)]
    }

    static func projectColor(for project: Project) -> Color {
        projectColors[normalizedProjectColorIndex(project.colorIndex)]
    }

    static func projectColorIndex(for name: String) -> Int {
        let total = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return abs(total) % projectColors.count
    }

    static func normalizedProjectColorIndex(_ index: Int) -> Int {
        guard !projectColors.isEmpty else { return 0 }
        return ((index % projectColors.count) + projectColors.count) % projectColors.count
    }

    static func tagForeground(for name: String) -> Color {
        [tagBlueText, tagMintText, tagGoldText, tagPinkText][bucket(for: name)]
    }

    static func tagBackground(for name: String) -> Color {
        [tagBlueBackground, tagMintBackground, tagGoldBackground, tagPinkBackground][bucket(for: name)]
    }

    private static let tagBlueText = adaptive(
        light: NSColor(calibratedRed: 0.08, green: 0.32, blue: 0.62, alpha: 1),
        dark: NSColor(calibratedRed: 0.60, green: 0.78, blue: 1.0, alpha: 1)
    )
    private static let tagBlueBackground = adaptive(
        light: NSColor(calibratedRed: 0.86, green: 0.93, blue: 1.0, alpha: 1),
        dark: NSColor(calibratedRed: 0.12, green: 0.20, blue: 0.30, alpha: 1)
    )
    private static let tagMintText = adaptive(
        light: NSColor(calibratedRed: 0.08, green: 0.42, blue: 0.32, alpha: 1),
        dark: NSColor(calibratedRed: 0.56, green: 0.91, blue: 0.78, alpha: 1)
    )
    private static let tagMintBackground = adaptive(
        light: NSColor(calibratedRed: 0.84, green: 0.95, blue: 0.91, alpha: 1),
        dark: NSColor(calibratedRed: 0.10, green: 0.25, blue: 0.21, alpha: 1)
    )
    private static let tagGoldText = adaptive(
        light: NSColor(calibratedRed: 0.48, green: 0.30, blue: 0.08, alpha: 1),
        dark: NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.52, alpha: 1)
    )
    private static let tagGoldBackground = adaptive(
        light: NSColor(calibratedRed: 1.0, green: 0.91, blue: 0.78, alpha: 1),
        dark: NSColor(calibratedRed: 0.27, green: 0.20, blue: 0.11, alpha: 1)
    )
    private static let tagPinkText = adaptive(
        light: NSColor(calibratedRed: 0.58, green: 0.17, blue: 0.34, alpha: 1),
        dark: NSColor(calibratedRed: 1.0, green: 0.67, blue: 0.82, alpha: 1)
    )
    private static let tagPinkBackground = adaptive(
        light: NSColor(calibratedRed: 1.0, green: 0.87, blue: 0.93, alpha: 1),
        dark: NSColor(calibratedRed: 0.28, green: 0.13, blue: 0.21, alpha: 1)
    )

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua ? dark : light
        })
    }

    private static func bucket(for value: String) -> Int {
        let total = value.lowercased().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return abs(total) % 4
    }
}

private struct AppFieldBackground: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppStyle.fieldBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isFocused ? AppStyle.fieldFocusedBorder : AppStyle.fieldBorder, lineWidth: isFocused ? 1.2 : 1)
            }
    }
}

extension View {
    func appFieldBackground(isFocused: Bool = false, cornerRadius: CGFloat = 8) -> some View {
        modifier(AppFieldBackground(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

struct AppIconButtonStyle: ButtonStyle {
    var isDanger = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isDanger ? AppStyle.danger : AppStyle.secondaryText)
            .frame(width: 28, height: 28)
            .background(configuration.isPressed ? AppStyle.selectionBackground : Color.clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
    }
}
