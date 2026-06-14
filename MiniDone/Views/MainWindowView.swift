import SwiftData
import SwiftUI

struct MainWindowView: View {
    @State private var selection: SidebarSelection = .allTasks
    @State private var draggedTask: TaskItem?
    @State private var isShowingOnboarding = false
    @AppStorage(Constants.StorageKeys.language) private var languageRawValue = AppLanguage.russian.rawValue
    @AppStorage(Constants.StorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    private var language: AppLanguage {
        SettingsViewModel.language(from: languageRawValue)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, draggedTask: $draggedTask, language: language)
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        } detail: {
            MainDetailView(selection: $selection, draggedTask: $draggedTask, language: language)
        }
        .background {
            AppStyle.windowBackground
                .ignoresSafeArea()

            WindowMetadataView(identifier: Constants.Windows.mainID, title: "MiniDone")
                .frame(width: 0, height: 0)
        }
        .frame(
            minWidth: Constants.WindowSize.mainMinWidth,
            minHeight: Constants.WindowSize.mainMinHeight
        )
        .accessibilityIdentifier("mainWindow")
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView(language: language) {
                completeOnboarding()
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                isShowingOnboarding = true
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if !completed {
                isShowingOnboarding = true
            }
        }
        .onChange(of: isShowingOnboarding) { _, isShowing in
            if !isShowing && !hasCompletedOnboarding {
                hasCompletedOnboarding = true
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        isShowingOnboarding = false
    }
}

private struct MainDetailView: View {
    @Binding var selection: SidebarSelection
    @Binding var draggedTask: TaskItem?
    let language: AppLanguage

    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]

    var body: some View {
        switch selection {
        case .allTasks:
            TaskListView(
                title: LocalizationService.text(.allTasks, language: language),
                project: nil,
                showsAllActiveTasks: true,
                showsTodayTasks: false,
                draggedTask: $draggedTask,
                language: language
            )
        case .today:
            TaskListView(
                title: LocalizationService.text(.today, language: language),
                project: nil,
                showsAllActiveTasks: true,
                showsTodayTasks: true,
                draggedTask: $draggedTask,
                language: language
            )
        case .completed:
            CompletedTasksView(language: language)
        case .project(let projectName):
            if let project = projects.first(where: { $0.name == projectName }) {
                TaskListView(
                    title: project.name,
                    project: project,
                    showsAllActiveTasks: false,
                    showsTodayTasks: false,
                    draggedTask: $draggedTask,
                    language: language,
                    onProjectRenamed: { newName in
                        selection = .project(newName)
                    }
                )
            } else {
                EmptyStateView(
                    systemImage: "folder",
                    title: LocalizationService.text(.emptyProjects, language: language)
                )
            }
        case .settings:
            SettingsView()
        }
    }
}
