import SwiftData
import SwiftUI

struct CompletedTasksView: View {
    let language: AppLanguage

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TaskItem.createdAt, order: .reverse)]) private var tasks: [TaskItem]
    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]
    @Query(sort: [SortDescriptor(\TaskTag.name)]) private var tags: [TaskTag]
    @State private var undoAction: UndoAction?
    @State private var isShowingSearch = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var completedTasks: [TaskItem] {
        TaskListViewModel.completedTasksNewestFirst(from: tasks)
            .filter { TaskListViewModel.matchesSearch($0, searchText: searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(LocalizationService.text(.completed, language: language))
                    .font(AppStyle.font(19, .semibold))
                    .foregroundStyle(AppStyle.primaryText)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isShowingSearch.toggle()
                    }

                    if isShowingSearch {
                        isSearchFocused = true
                    } else {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(AppIconButtonStyle())
                .keyboardShortcut("f", modifiers: .command)
                .help(LocalizationService.text(.showSearch, language: language))
                .accessibilityLabel(LocalizationService.text(.showSearch, language: language))

                if !completedTasks.isEmpty {
                    Button {
                        clearCompleted()
                    } label: {
                        Label(LocalizationService.text(.clearCompleted, language: language), systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .font(AppStyle.font(12, .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .appFieldBackground(cornerRadius: 7)
                    .accessibilityLabel(LocalizationService.text(.clearCompleted, language: language))
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 24)

            if isShowingSearch {
                searchField
                    .padding(.horizontal, 26)
                    .padding(.bottom, 14)
            }

            Rectangle()
                .fill(AppStyle.divider)
                .frame(height: 1)

            if completedTasks.isEmpty {
                Spacer()
                EmptyStateView(
                    systemImage: "checkmark.seal",
                    title: LocalizationService.text(.emptyCompleted, language: language)
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(completedTasks) { task in
                            CompletedTaskRowView(
                                task: task,
                                language: language,
                                onUndoAction: presentUndo
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
        .background(AppStyle.windowBackground)
        .overlay(alignment: .bottom) {
            if let undoAction {
                UndoBannerView(action: undoAction, language: language) {
                    self.undoAction = nil
                }
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func clearCompleted() {
        let snapshots = TaskListViewModel(modelContext: modelContext).clearCompleted(completedTasks)
        presentUndo(
            UndoAction(message: LocalizationService.text(.clearedCompleted, language: language)) {
                let viewModel = TaskListViewModel(modelContext: modelContext)

                for snapshot in snapshots {
                    viewModel.restoreDeletedTask(
                        from: snapshot,
                        existingProjects: projects,
                        existingTags: tags
                    )
                }
            }
        )
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppStyle.secondaryText)

            TextField(LocalizationService.text(.showSearch, language: language), text: $searchText)
                .textFieldStyle(.plain)
                .font(AppStyle.font(13, .medium))
                .focused($isSearchFocused)
                .onExitCommand {
                    isShowingSearch = false
                    searchText = ""
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppStyle.secondaryText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .appFieldBackground(isFocused: isSearchFocused)
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

private struct CompletedTaskRowView: View {
    let task: TaskItem
    let language: AppLanguage
    var onUndoAction: (UndoAction) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]
    @Query(sort: [SortDescriptor(\TaskTag.name)]) private var tags: [TaskTag]
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppStyle.green)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(AppStyle.font(14, .semibold))
                    .foregroundStyle(AppStyle.mutedText)
                    .strikethrough()

                TaskMetadataView(
                    project: task.project,
                    tags: task.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
                    dueDate: task.dueDate,
                    recurrenceRule: task.recurrenceRule,
                    language: language,
                    showsProject: true
                )
            }

            Spacer()

            Button {
                TaskListViewModel(modelContext: modelContext).restore(task)
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(AppIconButtonStyle())
            .help(LocalizationService.text(.restore, language: language))
            .accessibilityIdentifier("completedTaskRestoreButton")
            .accessibilityLabel(LocalizationService.text(.restore, language: language))

            Button(role: .destructive) {
                deleteTask()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(AppIconButtonStyle(isDanger: true))
            .help(LocalizationService.text(.delete, language: language))
            .accessibilityIdentifier("completedTaskDeleteButton")
            .accessibilityLabel(LocalizationService.text(.delete, language: language))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isHovering ? AppStyle.rowHoverBackground : AppStyle.rowBackground, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("completedTaskRow")
        .accessibilityLabel(task.title)
        .onHover { isHovering = $0 }
    }

    private func deleteTask() {
        let viewModel = TaskListViewModel(modelContext: modelContext)
        let snapshot = viewModel.deleteWithSnapshot(task)
        onUndoAction(
            UndoAction(message: LocalizationService.text(.deletedTask, language: language)) {
                TaskListViewModel(modelContext: modelContext).restoreDeletedTask(
                    from: snapshot,
                    existingProjects: projects,
                    existingTags: tags
                )
            }
        )
    }
}
