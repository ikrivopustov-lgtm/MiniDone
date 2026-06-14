import XCTest

@MainActor
final class MiniDoneUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = makeApp(language: "ru", theme: "system")
        app.launch()
        waitForMainWindow()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testLaunchShowsMainWindowAndSidebarSections() {
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
        XCTAssertTrue(mainWindow.staticTexts["Все задачи"].waitForExistence(timeout: 3))
        XCTAssertTrue(sidebarItem("sidebarCompleted").exists)
        XCTAssertTrue(mainWindow.textFields["addTaskField"].exists)
        XCTAssertTrue(mainWindow.textFields["projectCreateField"].exists)
    }

    func testCompleteRestoreAndDeleteTaskFlow() {
        app.terminate()
        app = makeApp(language: "ru", theme: "system", seed: "taskFlow")
        app.launch()
        waitForMainWindow()

        XCTAssertTrue(element(label: "UI Flow Task").waitForExistence(timeout: 3))

        mainWindow.buttons["taskCompleteButton"].firstMatch.click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForNonExistence(timeout: 2))

        sidebarItem("sidebarCompleted").click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForExistence(timeout: 3))

        mainWindow.buttons["completedTaskRestoreButton"].firstMatch.click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForNonExistence(timeout: 2))

        sidebarItem("sidebarAllTasks").click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForExistence(timeout: 3))

        mainWindow.buttons["taskCompleteButton"].firstMatch.click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForNonExistence(timeout: 2))

        sidebarItem("sidebarCompleted").click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForExistence(timeout: 3))
        mainWindow.buttons["completedTaskDeleteButton"].firstMatch.click()
        XCTAssertTrue(element(label: "UI Flow Task").waitForNonExistence(timeout: 2))
    }

    func testProjectScopedTaskAppearsInsideSelectedProject() {
        app.terminate()
        app = makeApp(language: "ru", theme: "system", seed: "projectTask")
        app.launch()
        waitForMainWindow()

        let projectRow = sidebarItem("sidebarProject-QAProject")
        projectRow.click()

        XCTAssertTrue(element(label: "Project scoped task").waitForExistence(timeout: 3))
        XCTAssertTrue(element(identifier: "#qa").waitForExistence(timeout: 3))
    }

    func testTagFilterAndSmartDeadlineChips() {
        app.terminate()
        app = makeApp(language: "ru", theme: "system", seed: "tagFilter")
        app.launch()
        waitForMainWindow()

        XCTAssertTrue(element(label: "Plan launch").waitForExistence(timeout: 3))
        XCTAssertTrue(element(identifier: "#work").waitForExistence(timeout: 3))
        XCTAssertTrue(element(identifier: "завтра").waitForExistence(timeout: 3))
        XCTAssertTrue(element(label: "Clean desk").waitForExistence(timeout: 3))
        XCTAssertTrue(element(identifier: "tagFilter-work").waitForExistence(timeout: 3))

        element(identifier: "tagFilter-work").click()

        XCTAssertTrue(element(label: "Plan launch").waitForExistence(timeout: 3))
        XCTAssertTrue(element(label: "Clean desk").waitForNonExistence(timeout: 2))

        element(identifier: "tagFilterAll").click()
        XCTAssertTrue(element(label: "Clean desk").waitForExistence(timeout: 3))
    }

    func testRecurringTaskCreatesNextOccurrenceAfterCompletion() {
        app.terminate()
        app = makeApp(language: "ru", theme: "system", seed: "recurring")
        app.launch()
        waitForMainWindow()

        XCTAssertTrue(element(label: "Daily backup").waitForExistence(timeout: 3))
        XCTAssertTrue(element(identifier: "#ops").waitForExistence(timeout: 3))
        XCTAssertTrue(element(identifier: "ежедневно").waitForExistence(timeout: 3))

        mainWindow.buttons["taskCompleteButton"].firstMatch.click()

        XCTAssertTrue(element(label: "Daily backup").waitForExistence(timeout: 3))

        sidebarItem("sidebarCompleted").click()
        XCTAssertTrue(element(label: "Daily backup").waitForExistence(timeout: 3))
    }

    func testSettingsControlsExist() {
        sidebarItem("sidebarSettings").click()

        XCTAssertTrue(mainWindow.descendants(matching: .any)["languagePicker"].waitForExistence(timeout: 3))
        XCTAssertTrue(mainWindow.descendants(matching: .any)["themePicker"].waitForExistence(timeout: 3))
        XCTAssertTrue(mainWindow.descendants(matching: .any)["showOnboardingButton"].waitForExistence(timeout: 3))
    }

    func testEnglishAndLightLaunchConfiguration() {
        app.terminate()
        app = makeApp(language: "en", theme: "light")
        app.launch()
        waitForMainWindow()

        XCTAssertTrue(mainWindow.staticTexts["All tasks"].waitForExistence(timeout: 5))
        XCTAssertTrue(mainWindow.staticTexts["No tasks yet"].waitForExistence(timeout: 3))
    }

    func testOnboardingFirstLaunchWalkthroughCanFinish() {
        app.terminate()
        app = makeApp(language: "ru", theme: "system", onboardingCompleted: false)
        app.launch()
        waitForMainWindow()

        XCTAssertTrue(onboardingElement(identifier: "onboardingSheet").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Познакомимся с MiniDone"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Тихий список задач для Mac"].waitForExistence(timeout: 3))

        for title in ["Быстрый ввод", "Организация", "Завершение без страха", "Menu bar и настройки"] {
            onboardingButton(title: "Дальше").click()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3))
        }

        onboardingButton(title: "Начать пользоваться").click()
        XCTAssertTrue(onboardingElement(identifier: "onboardingSheet").waitForNonExistence(timeout: 3))
    }

    func testSettingsCanShowOnboardingAgain() {
        sidebarItem("sidebarSettings").click()

        mainWindow.descendants(matching: .any)["showOnboardingButton"].click()

        XCTAssertTrue(onboardingElement(identifier: "onboardingSheet").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Познакомимся с MiniDone"].waitForExistence(timeout: 3))

        onboardingButton(title: "Пропустить").click()
        XCTAssertTrue(onboardingElement(identifier: "onboardingSheet").waitForNonExistence(timeout: 3))
    }

    private func makeApp(
        language: String,
        theme: String,
        seed: String? = nil,
        onboardingCompleted: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MiniDoneUITests-\(UUID().uuidString)")
            .appendingPathComponent("MiniDone.store")

        app.launchEnvironment["MINIDONE_UI_TESTS"] = "1"
        app.launchEnvironment["MINIDONE_LANGUAGE"] = language
        app.launchEnvironment["MINIDONE_THEME"] = theme
        app.launchEnvironment["MINIDONE_STORE_URL"] = storeURL.path
        app.launchEnvironment["MINIDONE_RESET_STORE"] = "1"
        app.launchEnvironment["MINIDONE_ONBOARDING_COMPLETED"] = onboardingCompleted ? "1" : "0"
        if let seed {
            app.launchEnvironment["MINIDONE_SEED_SCENARIO"] = seed
        }
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES", "-NSQuitAlwaysKeepsWindows", "NO"]
        return app
    }

    private var mainWindow: XCUIElement {
        app.windows.firstMatch
    }

    private func waitForMainWindow() {
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        app.activate()
    }

    private func sidebarItem(_ identifier: String) -> XCUIElement {
        let item = mainWindow.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 3))
        return item
    }

    private func element(label: String) -> XCUIElement {
        mainWindow.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    private func element(identifier: String) -> XCUIElement {
        mainWindow.descendants(matching: .any)[identifier].firstMatch
    }

    private func onboardingElement(identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func onboardingButton(title: String) -> XCUIElement {
        let button = app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
        if button.waitForExistence(timeout: 1) {
            return button
        }

        let visibleTitle = app.staticTexts[title].firstMatch
        XCTAssertTrue(visibleTitle.waitForExistence(timeout: 3))
        return visibleTitle
    }
}

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
