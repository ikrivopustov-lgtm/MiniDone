import AppKit
import SwiftData
import SwiftUI

@main
struct MiniDoneApp: App {
    @NSApplicationDelegateAdaptor(MiniDoneAppDelegate.self) private var appDelegate

    private let sharedModelContainer: ModelContainer

    init() {
        do {
            #if DEBUG
            Self.applyUITestDefaultsIfNeeded()
            #endif
            let modelContainer = try Self.makeModelContainer()
            #if DEBUG
            Self.seedUITestDataIfNeeded(in: modelContainer)
            #endif
            sharedModelContainer = modelContainer
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup("MiniDone", id: Constants.Windows.mainID) {
            AppSceneRoot {
                MainWindowView()
            }
            .modelContainer(sharedModelContainer)
        }
        .defaultSize(
            width: Constants.WindowSize.mainDefaultWidth,
            height: Constants.WindowSize.mainDefaultHeight
        )
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            AppSceneRoot {
                MiniMenuBarView()
            }
            .modelContainer(sharedModelContainer)
        } label: {
            AppSceneRoot {
                MenuBarLabelView()
            }
            .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)

        Settings {
            AppSceneRoot {
                SettingsView()
            }
            .modelContainer(sharedModelContainer)
        }
    }

    #if DEBUG
    private static func applyUITestDefaultsIfNeeded() {
        guard ProcessInfo.processInfo.environment["MINIDONE_UI_TESTS"] == "1" else { return }

        let environment = ProcessInfo.processInfo.environment
        UserDefaults.standard.set(
            environment["MINIDONE_LANGUAGE"] ?? AppLanguage.russian.rawValue,
            forKey: Constants.StorageKeys.language
        )
        UserDefaults.standard.set(
            environment["MINIDONE_THEME"] ?? AppTheme.system.rawValue,
            forKey: Constants.StorageKeys.theme
        )
        if let onboardingCompleted = environment["MINIDONE_ONBOARDING_COMPLETED"] {
            UserDefaults.standard.set(
                onboardingCompleted != "0",
                forKey: Constants.StorageKeys.hasCompletedOnboarding
            )
        } else if environment["MINIDONE_RESET_ONBOARDING"] == "1" {
            UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        }
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
    }
    #endif

    private static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([
            TaskItem.self,
            Project.self,
            TaskTag.self
        ])
        let storeURL = try storeURL()
        migrateLegacyDefaultStoreIfNeeded(to: storeURL)

        let configuration = ModelConfiguration("MiniDone", schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    #if DEBUG
    @MainActor
    private static func seedUITestDataIfNeeded(in modelContainer: ModelContainer) {
        let environment = ProcessInfo.processInfo.environment
        guard environment["MINIDONE_UI_TESTS"] == "1",
              let seedScenario = environment["MINIDONE_SEED_SCENARIO"] else {
            return
        }

        switch seedScenario {
        case "taskFlow":
            seedTaskFlowData(in: modelContainer)
        case "projectTask":
            seedProjectTaskData(in: modelContainer)
        case "tagFilter":
            seedTagFilterData(in: modelContainer)
        case "recurring":
            seedRecurringData(in: modelContainer)
        default:
            return
        }
    }

    @MainActor
    private static func seedTaskFlowData(in modelContainer: ModelContainer) {
        let modelContext = modelContainer.mainContext
        modelContext.insert(
            TaskItem(
                title: "UI Flow Task",
                orderIndex: -Date().timeIntervalSinceReferenceDate
            )
        )
        try? modelContext.save()
    }

    @MainActor
    private static func seedProjectTaskData(in modelContainer: ModelContainer) {
        let modelContext = modelContainer.mainContext
        let project = Project(
            name: "QAProject",
            colorIndex: AppStyle.projectColorIndex(for: "QAProject")
        )
        let tag = TaskTag(name: "qa")

        modelContext.insert(project)
        modelContext.insert(tag)
        modelContext.insert(
            TaskItem(
                title: "Project scoped task",
                orderIndex: -Date().timeIntervalSinceReferenceDate,
                project: project,
                tags: [tag]
            )
        )
        try? modelContext.save()
    }

    @MainActor
    private static func seedTagFilterData(in modelContainer: ModelContainer) {
        let modelContext = modelContainer.mainContext
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let workTag = TaskTag(name: "work")
        let homeTag = TaskTag(name: "home")

        modelContext.insert(workTag)
        modelContext.insert(homeTag)
        modelContext.insert(
            TaskItem(
                title: "Plan launch",
                dueDate: tomorrow,
                orderIndex: -Date().timeIntervalSinceReferenceDate,
                tags: [workTag]
            )
        )
        modelContext.insert(
            TaskItem(
                title: "Clean desk",
                orderIndex: -Date().timeIntervalSinceReferenceDate - 1,
                tags: [homeTag]
            )
        )
        try? modelContext.save()
    }

    @MainActor
    private static func seedRecurringData(in modelContainer: ModelContainer) {
        let modelContext = modelContainer.mainContext
        let today = Calendar.current.startOfDay(for: .now)
        let opsTag = TaskTag(name: "ops")

        modelContext.insert(opsTag)
        modelContext.insert(
            TaskItem(
                title: "Daily backup",
                dueDate: today,
                orderIndex: -Date().timeIntervalSinceReferenceDate,
                recurrenceRule: .daily,
                tags: [opsTag]
            )
        )
        try? modelContext.save()
    }
    #endif

    private static func storeURL() throws -> URL {
        #if DEBUG
        if ProcessInfo.processInfo.environment["MINIDONE_UI_TESTS"] == "1" {
            if let testStorePath = ProcessInfo.processInfo.environment["MINIDONE_STORE_URL"],
               !testStorePath.isEmpty {
                let storeURL = URL(fileURLWithPath: testStorePath)
                try FileManager.default.createDirectory(
                    at: storeURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                if ProcessInfo.processInfo.environment["MINIDONE_RESET_STORE"] == "1" {
                    removeStoreFiles(at: storeURL)
                }

                return storeURL
            }
        }
        #endif

        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = applicationSupportURL.appendingPathComponent("MiniDone", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("MiniDone.store")
    }

    #if DEBUG
    private static func removeStoreFiles(at storeURL: URL) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
    }
    #endif

    private static func migrateLegacyDefaultStoreIfNeeded(to storeURL: URL) {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["MINIDONE_STORE_URL"] == nil else { return }
        #endif

        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: storeURL.path) else { return }

        guard let applicationSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }

        let legacyStoreURL = applicationSupportURL.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: legacyStoreURL.path) else { return }

        for suffix in ["", "-wal", "-shm"] {
            let sourceURL = URL(fileURLWithPath: legacyStoreURL.path + suffix)
            let targetURL = URL(fileURLWithPath: storeURL.path + suffix)

            guard fileManager.fileExists(atPath: sourceURL.path),
                  !fileManager.fileExists(atPath: targetURL.path) else {
                continue
            }

            try? fileManager.copyItem(at: sourceURL, to: targetURL)
        }
    }
}

final class MiniDoneAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

private struct MenuBarLabelView: View {
    @Query private var tasks: [TaskItem]

    private var displayedCount: Int {
        let todayCount = tasks.filter { TaskListViewModel.isDueTodayOrOverdue($0) }.count
        if todayCount > 0 {
            return todayCount
        }

        return tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        HStack(spacing: 4) {
            Image("MenuBarIcon")

            if displayedCount > 0 {
                Text("\(displayedCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }
}
