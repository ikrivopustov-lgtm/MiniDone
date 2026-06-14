import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct UndoAction: Identifiable {
    let id = UUID()
    let message: String
    let action: () -> Void
}

struct TaskListView: View {
    let title: String
    let project: Project?
    let showsAllActiveTasks: Bool
    var showsTodayTasks = false
    @Binding var draggedTask: TaskItem?
    let language: AppLanguage
    var onProjectRenamed: ((String) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TaskItem.createdAt, order: .reverse)]) private var tasks: [TaskItem]
    @Query(sort: [SortDescriptor(\TaskTag.name)]) private var tags: [TaskTag]
    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]
    @State private var isShowingProjectTitleEditor = false
    @State private var projectTitleText = ""
    @State private var isHeaderHovering = false
    @State private var isShowingSearch = false
    @State private var searchText = ""
    @State private var undoAction: UndoAction?
    @State private var selectedTagName: String?
    @FocusState private var isProjectTitleFocused: Bool
    @FocusState private var isSearchFocused: Bool

    private var scopedActiveTasks: [TaskItem] {
        tasks.filter { task in
            guard !task.isCompleted else { return false }

            if showsTodayTasks {
                return TaskListViewModel.isDueTodayOrOverdue(task)
            }

            if showsAllActiveTasks {
                return true
            }

            return task.project?.name == project?.name
        }
    }

    private var searchedActiveTasks: [TaskItem] {
        scopedActiveTasks.filter { TaskListViewModel.matchesSearch($0, searchText: searchText) }
    }

    private var availableTagNames: [String] {
        Array(Set(searchedActiveTasks.flatMap { $0.tags.map(\.name) }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var activeTasks: [TaskItem] {
        let filtered = searchedActiveTasks.filter { task in
            guard let selectedTagName else { return true }
            return task.tags.contains { $0.name.caseInsensitiveCompare(selectedTagName) == .orderedSame }
        }

        return showsTodayTasks
            ? TaskListViewModel.todayTasksSorted(filtered)
            : TaskListViewModel.activeTasksSorted(filtered)
    }

    private var completedProjectTasks: [TaskItem] {
        guard let project, !showsAllActiveTasks else { return [] }

        return tasks
            .filter { $0.isCompleted && $0.project?.name == project.name }
            .filter { TaskListViewModel.matchesSearch($0, searchText: searchText) }
            .filter { task in
                guard let selectedTagName else { return true }
                return task.tags.contains { $0.name.caseInsensitiveCompare(selectedTagName) == .orderedSame }
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var showsTagFilter: Bool {
        !availableTagNames.isEmpty || selectedTagName != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if isShowingSearch {
                searchField
            }

            AddTaskView(
                project: project,
                existingTags: tags,
                existingProjects: projects,
                language: language,
                fallbackDueDate: showsTodayTasks ? Calendar.current.startOfDay(for: .now) : nil
            )

            if showsTagFilter {
                TaskTagFilterBar(
                    tagNames: availableTagNames,
                    selectedTagName: $selectedTagName,
                    language: language
                )
            }

            if activeTasks.isEmpty && completedProjectTasks.isEmpty {
                Spacer()
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: LocalizationService.text(.emptyTasks, language: language)
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        LazyVStack(spacing: 8) {
                            ForEach(activeTasks) { task in
                                TaskRowView(
                                    task: task,
                                    language: language,
                                    showsProject: showsAllActiveTasks,
                                    onUndoAction: presentUndo
                                )
                                .onDrag {
                                    draggedTask = task
                                    return NSItemProvider(object: Constants.DragPayload.task as NSString)
                                }
                                .onDrop(
                                    of: [.plainText],
                                    delegate: TaskReorderDropDelegate(
                                        targetTask: task,
                                        visibleTasks: activeTasks,
                                        draggedTask: $draggedTask,
                                        modelContext: modelContext
                                    )
                                )
                            }
                        }

                        if !completedProjectTasks.isEmpty {
                            DisclosureGroup {
                                LazyVStack(spacing: 8) {
                                    ForEach(completedProjectTasks) { task in
                                        TaskRowView(
                                            task: task,
                                            language: language,
                                            onUndoAction: presentUndo
                                        )
                                    }
                                }
                                .padding(.top, 8)
                            } label: {
                                Text("\(LocalizationService.text(.completed, language: language)) · \(completedProjectTasks.count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppStyle.secondaryText)
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }
            }
        }
        .padding(24)
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
        .onChange(of: availableTagNames) { _, tagNames in
            if let selectedTagName, !tagNames.contains(where: { $0.caseInsensitiveCompare(selectedTagName) == .orderedSame }) {
                self.selectedTagName = nil
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let project {
            if isShowingProjectTitleEditor {
                TextField("", text: $projectTitleText)
                    .textFieldStyle(.plain)
                    .font(AppStyle.font(20, .semibold))
                    .focused($isProjectTitleFocused)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .appFieldBackground(isFocused: isProjectTitleFocused)
                    .frame(maxWidth: 380, alignment: .leading)
                    .onSubmit {
                        saveProjectTitle(project)
                    }
                    .onChange(of: isProjectTitleFocused) { _, isFocused in
                        if !isFocused {
                            saveProjectTitle(project)
                        }
                    }
                    .onAppear {
                        projectTitleText = project.name
                        isProjectTitleFocused = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            NSApp.sendAction(#selector(NSText.moveToEndOfDocument(_:)), to: nil, from: nil)
                        }
                    }
            } else {
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(AppStyle.font(20, .semibold))

                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppStyle.secondaryText)
                        .opacity(isHeaderHovering ? 1 : 0)

                    Spacer()
                }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onHover { isHeaderHovering = $0 }
                    .onTapGesture {
                        beginProjectTitleRename(project)
                    }
                    .help(LocalizationService.text(.rename, language: language))
            }
        } else {
            HStack(spacing: 8) {
                Text(title)
                    .font(AppStyle.font(20, .semibold))

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
            }
        }
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

    private func beginProjectTitleRename(_ project: Project) {
        projectTitleText = project.name
        isShowingProjectTitleEditor = true
    }

    private func saveProjectTitle(_ project: Project) {
        guard isShowingProjectTitleEditor else { return }

        let didRename = ProjectViewModel(modelContext: modelContext)
            .renameProject(project, to: projectTitleText, existingProjects: projects)

        if didRename {
            onProjectRenamed?(project.name)
        }

        isShowingProjectTitleEditor = false
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

struct TaskTagFilterBar: View {
    let tagNames: [String]
    @Binding var selectedTagName: String?
    let language: AppLanguage

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                TaskTagFilterChip(
                    title: LocalizationService.text(.filterAllTags, language: language),
                    isSelected: selectedTagName == nil,
                    foreground: AppStyle.secondaryText,
                    background: AppStyle.panelBackground
                ) {
                    selectedTagName = nil
                }
                .accessibilityIdentifier("tagFilterAll")

                ForEach(tagNames, id: \.self) { tagName in
                    TaskTagFilterChip(
                        title: "#\(tagName)",
                        isSelected: selectedTagName?.caseInsensitiveCompare(tagName) == .orderedSame,
                        foreground: AppStyle.tagForeground(for: tagName),
                        background: AppStyle.tagBackground(for: tagName)
                    ) {
                        selectedTagName = selectedTagName?.caseInsensitiveCompare(tagName) == .orderedSame ? nil : tagName
                    }
                    .accessibilityIdentifier("tagFilter-\(tagName)")
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }
}

private struct TaskTagFilterChip: View {
    let title: String
    let isSelected: Bool
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppStyle.font(11, .semibold))
                .lineLimit(1)
                .foregroundStyle(isSelected ? AppStyle.primaryText : foreground)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(isSelected ? AppStyle.selectionBackground : background, in: RoundedRectangle(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isSelected ? AppStyle.fieldFocusedBorder : AppStyle.fieldBorder.opacity(0.7), lineWidth: isSelected ? 1 : 0.6)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct UndoBannerView: View {
    let action: UndoAction
    let language: AppLanguage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(action.message)
                .font(AppStyle.font(12, .medium))
                .foregroundStyle(AppStyle.primaryText)
                .lineLimit(1)

            Button(LocalizationService.text(.undo, language: language)) {
                action.action()
                onDismiss()
            }
            .buttonStyle(.plain)
            .font(AppStyle.font(12, .semibold))
            .foregroundStyle(AppStyle.fieldFocusedBorder)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppStyle.panelBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppStyle.fieldBorder, lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }
}

struct TaskReorderDropDelegate: DropDelegate {
    let targetTask: TaskItem
    let visibleTasks: [TaskItem]
    @Binding var draggedTask: TaskItem?
    let modelContext: ModelContext

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedTask,
              draggedTask !== targetTask,
              let fromIndex = visibleTasks.firstIndex(where: { $0 === draggedTask }),
              let toIndex = visibleTasks.firstIndex(where: { $0 === targetTask }) else {
            return
        }

        var reorderedTasks = visibleTasks
        reorderedTasks.move(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
        TaskListViewModel(modelContext: modelContext).reorder(reorderedTasks)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedTask = nil
        return true
    }
}
