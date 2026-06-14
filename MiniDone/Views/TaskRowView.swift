import AppKit
import SwiftData
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let language: AppLanguage
    var showsProject = false
    var onUndoAction: (UndoAction) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]
    @Query(sort: [SortDescriptor(\TaskTag.name)]) private var tags: [TaskTag]
    @State private var isHovering = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isCompleting = false
    @FocusState private var isRenameFieldFocused: Bool

    private var sortedTags: [TaskTag] {
        task.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var displayedCompleted: Bool {
        task.isCompleted || isCompleting
    }

    private var hasVisibleMetadata: Bool {
        (showsProject && task.project != nil) || task.dueDate != nil || task.recurrenceRule != nil || !sortedTags.isEmpty
    }

    var body: some View {
        HStack(alignment: hasVisibleMetadata ? .top : .center, spacing: 10) {
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: displayedCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(displayedCompleted ? AppStyle.green : AppStyle.mutedText)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(isCompleting)
            .accessibilityIdentifier("taskCompleteButton")
            .accessibilityLabel(displayedCompleted ? LocalizationService.text(.restore, language: language) : LocalizationService.text(.completed, language: language))
            .padding(.top, hasVisibleMetadata ? 1 : 0)

            VStack(alignment: .leading, spacing: 4) {
                if isRenaming {
                    TextField("", text: $renameText)
                        .textFieldStyle(.plain)
                        .font(AppStyle.font(14, .medium))
                        .focused($isRenameFieldFocused)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .appFieldBackground(isFocused: isRenameFieldFocused, cornerRadius: 7)
                        .onSubmit(commitRename)
                        .onExitCommand(perform: cancelRename)
                        .onChange(of: isRenameFieldFocused) { _, isFocused in
                            if !isFocused {
                                commitRename()
                            }
                        }
                        .onAppear(perform: focusRenameField)
                } else {
                    HStack(spacing: 6) {
                        if task.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppStyle.secondaryText)
                                .accessibilityLabel(LocalizationService.text(.pinned, language: language))
                        }

                        Text(task.title)
                            .font(AppStyle.font(14, .medium))
                            .foregroundStyle(displayedCompleted ? AppStyle.secondaryText : AppStyle.primaryText)
                            .strikethrough(displayedCompleted)
                            .animation(.easeInOut(duration: 0.18), value: displayedCompleted)
                            .accessibilityIdentifier(task.title)
                    }
                }

                TaskMetadataView(
                    project: task.project,
                    tags: sortedTags,
                    dueDate: task.dueDate,
                    recurrenceRule: task.recurrenceRule,
                    language: language,
                    showsProject: showsProject,
                    compact: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())

            Button(role: .destructive) {
                deleteTask()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(AppIconButtonStyle(isDanger: true))
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
            .help(LocalizationService.text(.delete, language: language))
            .accessibilityIdentifier("taskDeleteButton")
            .accessibilityLabel(LocalizationService.text(.delete, language: language))
            .accessibilityHidden(!isHovering)
            .padding(.top, hasVisibleMetadata ? -2 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isHovering ? AppStyle.rowHoverBackground : AppStyle.rowBackground, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(perform: beginRename)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taskRow")
        .accessibilityLabel(task.title)
        .contextMenu {
            Button {
                TaskListViewModel(modelContext: modelContext).togglePinned(for: task)
            } label: {
                Label(
                    LocalizationService.text(task.isPinned ? .unpinTask : .pinTask, language: language),
                    systemImage: task.isPinned ? "pin.slash" : "pin"
                )
            }

            Menu(LocalizationService.text(.moveToProject, language: language)) {
                Button(LocalizationService.text(.inbox, language: language)) {
                    TaskListViewModel(modelContext: modelContext).move(task, to: nil)
                }

                ForEach(projects) { project in
                    Button(project.name) {
                        TaskListViewModel(modelContext: modelContext).move(task, to: project)
                    }
                }
            }

            Menu(LocalizationService.text(.deadline, language: language)) {
                Button(LocalizationService.text(.today, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setDueDate(for: task, dueDate: dueDate(daysFromToday: 0))
                }

                Button(LocalizationService.text(.tomorrow, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setDueDate(for: task, dueDate: dueDate(daysFromToday: 1))
                }

                Button(LocalizationService.text(.noDeadline, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setDueDate(for: task, dueDate: nil)
                }
            }

            Menu(LocalizationService.text(.repeatTask, language: language)) {
                Button(LocalizationService.text(.noRepeat, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setRecurrence(for: task, recurrenceRule: nil)
                }

                Divider()

                Button(LocalizationService.text(.repeatDaily, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setRecurrence(for: task, recurrenceRule: .daily)
                }

                Button(LocalizationService.text(.repeatWeekly, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setRecurrence(for: task, recurrenceRule: .weekly)
                }

                Button(LocalizationService.text(.repeatMonthly, language: language)) {
                    TaskListViewModel(modelContext: modelContext).setRecurrence(for: task, recurrenceRule: .monthly)
                }
            }

            Button {
                beginRename()
            } label: {
                Label(LocalizationService.text(.rename, language: language), systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                deleteTask()
            } label: {
                Label(LocalizationService.text(.delete, language: language), systemImage: "trash")
            }
        }
        .onHover { isHovering = $0 }
    }

    private func beginRename() {
        guard !isRenaming else { return }

        renameText = TaskListViewModel(modelContext: modelContext).editingText(for: task, language: language)
        isRenaming = true
    }

    private func focusRenameField() {
        isRenameFieldFocused = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.sendAction(#selector(NSText.moveToEndOfDocument(_:)), to: nil, from: nil)
        }
    }

    private func commitRename() {
        guard isRenaming else { return }

        TaskListViewModel(modelContext: modelContext).update(
            task: task,
            rawText: renameText,
            existingTags: tags,
            existingProjects: projects
        )
        isRenaming = false
    }

    private func cancelRename() {
        isRenaming = false
        isRenameFieldFocused = false
    }

    private func toggleCompletion() {
        if task.isCompleted {
            TaskListViewModel(modelContext: modelContext).toggleCompletion(for: task)
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            isCompleting = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let viewModel = TaskListViewModel(modelContext: modelContext)
            let nextTask = viewModel.complete(task)
            onUndoAction(
                UndoAction(message: LocalizationService.text(.completedTask, language: language)) {
                    if let nextTask {
                        TaskListViewModel(modelContext: modelContext).delete(nextTask)
                    }
                    TaskListViewModel(modelContext: modelContext).restore(task)
                }
            )
            isCompleting = false
        }
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

    private func dueDate(daysFromToday days: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .day, value: days, to: today) ?? today
    }
}

struct TaskMetadataView: View {
    let project: Project?
    let tags: [TaskTag]
    let dueDate: Date?
    let recurrenceRule: TaskRecurrenceRule?
    let language: AppLanguage
    let showsProject: Bool
    var compact = false

    private var hasMetadata: Bool {
        (showsProject && project != nil) || dueDate != nil || recurrenceRule != nil || !tags.isEmpty
    }

    var body: some View {
        if hasMetadata {
            ViewThatFits(in: .horizontal) {
                chipRow

                ScrollView(.horizontal) {
                    chipRow
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var chipRow: some View {
        HStack(spacing: compact ? 4 : 6) {
            if showsProject, let project {
                MetadataChip(
                    title: project.name,
                    foreground: AppStyle.secondaryText,
                    background: AppStyle.panelBackground,
                    hasBorder: true,
                    compact: compact
                )
            }

            if let dueDate {
                let isOverdue = TaskDueDateFormatter.isOverdue(dueDate)
                MetadataChip(
                    title: TaskDueDateFormatter.label(for: dueDate, language: language),
                    systemImage: "calendar",
                    foreground: isOverdue ? AppStyle.warningText : AppStyle.secondaryText,
                    background: isOverdue ? AppStyle.warningBackground : AppStyle.panelBackground,
                    hasBorder: !isOverdue,
                    compact: compact
                )
            }

            if let recurrenceRule {
                MetadataChip(
                    title: TaskRecurrenceFormatter.label(for: recurrenceRule, language: language),
                    systemImage: "arrow.triangle.2.circlepath",
                    foreground: AppStyle.secondaryText,
                    background: AppStyle.panelBackground,
                    hasBorder: true,
                    compact: compact
                )
            }

            ForEach(tags) { tag in
                MetadataChip(
                    title: "#\(tag.name)",
                    foreground: AppStyle.tagForeground(for: tag.name),
                    background: AppStyle.tagBackground(for: tag.name),
                    hasBorder: false,
                    compact: compact
                )
            }
        }
    }
}

private struct MetadataChip: View {
    let title: String
    var systemImage: String?
    let foreground: Color
    let background: Color
    let hasBorder: Bool
    let compact: Bool

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: compact ? 8 : 9, weight: .semibold))
                    .accessibilityHidden(true)
            }

            Text(title)
                .lineLimit(1)
                .accessibilityIdentifier(title)
        }
        .font(AppStyle.font(compact ? 10 : 11, .semibold))
        .foregroundStyle(foreground)
        .padding(.horizontal, compact ? 6 : 7)
        .padding(.vertical, compact ? 2 : 3)
        .background(background, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            if hasBorder {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppStyle.fieldBorder, lineWidth: 0.6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(title)
        .accessibilityLabel(title)
    }
}
