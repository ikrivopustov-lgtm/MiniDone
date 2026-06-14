import SwiftData
import SwiftUI

struct MiniMenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @AppStorage(Constants.StorageKeys.language) private var languageRawValue = AppLanguage.russian.rawValue
    @AppStorage(Constants.StorageKeys.miniWindowHeight) private var miniWindowHeight = Double(Constants.WindowSize.miniHeight)

    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]
    @Query(sort: [SortDescriptor(\TaskTag.name)]) private var tags: [TaskTag]
    @Query private var tasks: [TaskItem]

    @State private var selectedProjectName: String?
    @State private var resizeStartHeight: CGFloat?
    @State private var undoAction: UndoAction?

    private var language: AppLanguage {
        SettingsViewModel.language(from: languageRawValue)
    }

    private var selectedProject: Project? {
        guard let selectedProjectName else { return nil }
        return projects.first { $0.name == selectedProjectName }
    }

    private var selectedActiveCount: Int {
        selectedActiveTasks.count
    }

    private var selectedActiveTasks: [TaskItem] {
        let filtered = tasks.filter { task in
            guard !task.isCompleted else { return false }

            if let selectedProjectName {
                return task.project?.name == selectedProjectName
            }

            return true
        }

        return TaskListViewModel.activeTasksSorted(filtered)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 7) {
                        BrandMarkView(size: 18)

                        Text(LocalizationService.text(.miniTitle, language: language))
                            .font(AppStyle.font(16, .semibold))
                            .foregroundStyle(AppStyle.primaryText)
                    }

                    Spacer()

                    Button {
                        WindowFocusService.openMainWindow(openWindow)
                    } label: {
                        Label(LocalizationService.text(.openMainWindow, language: language), systemImage: "arrow.up.right")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .font(AppStyle.font(12, .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .appFieldBackground(cornerRadius: 7)
                }

                MiniProjectPicker(
                    selectedProjectName: $selectedProjectName,
                    projects: projects,
                    language: language
                )

                AddTaskView(
                    project: selectedProject,
                    existingTags: tags,
                    existingProjects: projects,
                    language: language,
                    compact: true
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Rectangle()
                .fill(AppStyle.divider)
                .frame(height: 1)

            MiniTaskListView(
                activeTasks: selectedActiveTasks,
                showsProject: selectedProjectName == nil,
                language: language,
                onUndoAction: presentUndo
            )

            Rectangle()
                .fill(AppStyle.divider)
                .frame(height: 1)

            HStack(spacing: 10) {
                Text(LocalizationService.activeTaskCount(selectedActiveCount, language: language))
                    .font(AppStyle.font(12, .semibold))
                    .foregroundStyle(AppStyle.secondaryText)

                Spacer(minLength: 8)

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(AppIconButtonStyle())
                .help(LocalizationService.text(.settings, language: language))
                .accessibilityLabel(LocalizationService.text(.settings, language: language))

                Button {
                    WindowFocusService.quit()
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(AppIconButtonStyle(isDanger: true))
                .help(LocalizationService.text(.quit, language: language))
                .accessibilityLabel(LocalizationService.text(.quit, language: language))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            resizeHandle
        }
        .frame(width: Constants.WindowSize.miniWidth, height: boundedMiniHeight)
        .background(AppStyle.windowBackground)
        .overlay(alignment: .bottom) {
            if let undoAction {
                UndoBannerView(action: undoAction, language: language) {
                    self.undoAction = nil
                }
                .padding(.bottom, 34)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: projects.map(\.name)) { _, projectNames in
            if let selectedProjectName, !projectNames.contains(selectedProjectName) {
                self.selectedProjectName = nil
            }
        }
    }

    private var boundedMiniHeight: CGFloat {
        min(
            max(CGFloat(miniWindowHeight), Constants.WindowSize.miniMinHeight),
            Constants.WindowSize.miniMaxHeight
        )
    }

    private var resizeHandle: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 8)
            .overlay(alignment: .center) {
                Capsule()
                    .fill(AppStyle.divider)
                    .frame(width: 34, height: 3)
                    .opacity(0.9)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if resizeStartHeight == nil {
                            resizeStartHeight = boundedMiniHeight
                        }

                        let startHeight = resizeStartHeight ?? boundedMiniHeight
                        miniWindowHeight = Double(
                            min(
                                max(startHeight + value.translation.height, Constants.WindowSize.miniMinHeight),
                                Constants.WindowSize.miniMaxHeight
                            )
                        )
                    }
                    .onEnded { _ in
                        resizeStartHeight = nil
                    }
            )
            .help(LocalizationService.text(.resizeWindow, language: language))
    }

    private func presentUndo(_ action: UndoAction) {
        withAnimation(.easeInOut(duration: 0.16)) {
            undoAction = action
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if undoAction?.id == action.id {
                withAnimation(.easeInOut(duration: 0.16)) {
                    undoAction = nil
                }
            }
        }
    }
}
