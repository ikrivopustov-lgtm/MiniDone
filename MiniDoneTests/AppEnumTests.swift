import SwiftUI
import XCTest
@testable import MiniDone

final class AppEnumTests: XCTestCase {
    func testAppLanguageMetadata() {
        XCTAssertEqual(AppLanguage.russian.rawValue, "ru")
        XCTAssertEqual(AppLanguage.russian.id, "ru")
        XCTAssertEqual(AppLanguage.russian.locale.identifier, "ru")
        XCTAssertEqual(AppLanguage.russian.title, "Русский")

        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.english.id, "en")
        XCTAssertEqual(AppLanguage.english.locale.identifier, "en")
        XCTAssertEqual(AppLanguage.english.title, "English")
    }

    func testAppThemeColorSchemes() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, ColorScheme.light)
        XCTAssertEqual(AppTheme.dark.colorScheme, ColorScheme.dark)
    }

    func testSidebarSelectionHashingAndEquality() {
        XCTAssertEqual(SidebarSelection.allTasks, .allTasks)
        XCTAssertEqual(SidebarSelection.today, .today)
        XCTAssertEqual(SidebarSelection.completed, .completed)
        XCTAssertEqual(SidebarSelection.settings, .settings)
        XCTAssertEqual(SidebarSelection.project("Work"), .project("Work"))
        XCTAssertNotEqual(SidebarSelection.project("Work"), .project("Personal"))

        let selections: Set<SidebarSelection> = [
            .allTasks,
            .today,
            .completed,
            .settings,
            .project("Work"),
            .project("Work")
        ]
        XCTAssertEqual(selections.count, 5)
    }
}
