import Foundation
import SwiftData

struct TaskSnapshot {
    let title: String
    let isCompleted: Bool
    let createdAt: Date
    let completedAt: Date?
    let dueDate: Date?
    let isPinned: Bool
    let orderIndex: Double
    let recurrenceRule: TaskRecurrenceRule?
    let projectName: String?
    let tagNames: [String]
}

@MainActor
struct TaskListViewModel {
    let modelContext: ModelContext

    static func completedTasksNewestFirst(from tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter(\.isCompleted)
            .sorted { left, right in
                (left.completedAt ?? .distantPast) > (right.completedAt ?? .distantPast)
            }
    }

    static func activeTasksSorted(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { left, right in
            if left.isPinned != right.isPinned {
                return left.isPinned
            }

            let leftOrder = effectiveOrderIndex(for: left)
            let rightOrder = effectiveOrderIndex(for: right)

            if leftOrder == rightOrder {
                return left.createdAt > right.createdAt
            }

            return leftOrder < rightOrder
        }
    }

    static func todayTasksSorted(_ tasks: [TaskItem], now: Date = .now, calendar: Calendar = .current) -> [TaskItem] {
        activeTasksSorted(tasks.filter { isDueTodayOrOverdue($0, now: now, calendar: calendar) })
    }

    static func isDueTodayOrOverdue(_ task: TaskItem, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !task.isCompleted, let dueDate = task.dueDate else { return false }
        return calendar.startOfDay(for: dueDate) <= calendar.startOfDay(for: now)
    }

    static func matchesSearch(_ task: TaskItem, searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let lowered = query.lowercased()
        if task.title.lowercased().contains(lowered) { return true }
        if task.project?.name.lowercased().contains(lowered) == true { return true }
        return task.tags.contains { $0.name.lowercased().contains(lowered) }
    }

    @discardableResult
    func addTask(
        rawText: String,
        project: Project?,
        existingTags: [TaskTag],
        existingProjects: [Project],
        fallbackDueDate: Date? = nil
    ) -> Bool {
        let parsed = TaskTextParser.parse(rawText)
        guard !parsed.title.isEmpty else { return false }

        let tags = parsed.tagNames.map { tagName in
            findOrCreateTag(named: tagName, existingTags: existingTags)
        }

        let resolvedProject = resolveProject(
            commandProjectName: parsed.projectName,
            fallbackProject: project,
            existingProjects: existingProjects
        )

        let task = TaskItem(
            title: parsed.title,
            dueDate: parsed.dueDate ?? fallbackDueDate,
            orderIndex: -Date().timeIntervalSinceReferenceDate,
            recurrenceRule: parsed.recurrenceRule,
            project: resolvedProject,
            tags: tags
        )
        modelContext.insert(task)
        save()
        return true
    }

    @discardableResult
    func complete(_ task: TaskItem, now: Date = .now) -> TaskItem? {
        task.isCompleted = true
        task.completedAt = now

        let nextTask = makeNextOccurrenceIfNeeded(for: task, now: now)
        if let nextTask {
            modelContext.insert(nextTask)
        }

        save()
        return nextTask
    }

    func toggleCompletion(for task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
        save()
    }

    func setDueDate(for task: TaskItem, dueDate: Date?) {
        task.dueDate = dueDate
        save()
    }

    func togglePinned(for task: TaskItem) {
        task.isPinned.toggle()
        save()
    }

    func setRecurrence(for task: TaskItem, recurrenceRule: TaskRecurrenceRule?) {
        task.recurrenceRule = recurrenceRule

        if recurrenceRule != nil, task.dueDate == nil {
            task.dueDate = Calendar.current.startOfDay(for: .now)
        }

        save()
    }

    func restore(_ task: TaskItem) {
        task.isCompleted = false
        task.completedAt = nil
        save()
    }

    func delete(_ task: TaskItem) {
        modelContext.delete(task)
        save()
    }

    func snapshot(for task: TaskItem) -> TaskSnapshot {
        TaskSnapshot(
            title: task.title,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            completedAt: task.completedAt,
            dueDate: task.dueDate,
            isPinned: task.isPinned,
            orderIndex: task.orderIndex,
            recurrenceRule: task.recurrenceRule,
            projectName: task.project?.name,
            tagNames: task.tags.map(\.name)
        )
    }

    func deleteWithSnapshot(_ task: TaskItem) -> TaskSnapshot {
        let snapshot = snapshot(for: task)
        delete(task)
        return snapshot
    }

    func clearCompleted(_ tasks: [TaskItem]) -> [TaskSnapshot] {
        let snapshots = tasks.map(snapshot(for:))

        for task in tasks {
            modelContext.delete(task)
        }

        save()
        return snapshots
    }

    func restoreDeletedTask(from snapshot: TaskSnapshot, existingProjects: [Project], existingTags: [TaskTag]) {
        let availableProjects = (try? modelContext.fetch(FetchDescriptor<Project>())) ?? existingProjects
        let availableTags = (try? modelContext.fetch(FetchDescriptor<TaskTag>())) ?? existingTags
        let restoredTags = snapshot.tagNames.map { tagName in
            findOrCreateTag(named: tagName, existingTags: availableTags)
        }
        let restoredProject = resolveProject(
            commandProjectName: snapshot.projectName,
            fallbackProject: nil,
            existingProjects: availableProjects
        )
        let task = TaskItem(
            title: snapshot.title,
            isCompleted: snapshot.isCompleted,
            createdAt: snapshot.createdAt,
            completedAt: snapshot.completedAt,
            dueDate: snapshot.dueDate,
            isPinned: snapshot.isPinned,
            orderIndex: snapshot.orderIndex,
            recurrenceRule: snapshot.recurrenceRule,
            project: restoredProject,
            tags: restoredTags
        )
        modelContext.insert(task)
        save()
    }

    func rename(_ task: TaskItem, title: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        task.title = cleanTitle
        save()
    }

    func update(task: TaskItem, rawText: String, existingTags: [TaskTag], existingProjects: [Project]) {
        let parsed = TaskTextParser.parse(rawText)
        guard !parsed.title.isEmpty else { return }

        task.title = parsed.title
        task.dueDate = parsed.dueDate
        task.recurrenceRule = parsed.recurrenceRule
        task.tags = parsed.tagNames.map { tagName in
            findOrCreateTag(named: tagName, existingTags: existingTags)
        }
        task.project = resolveProject(
            commandProjectName: parsed.projectName,
            fallbackProject: nil,
            existingProjects: existingProjects
        )
        save()
    }

    func move(_ task: TaskItem, to project: Project?) {
        task.project = project
        save()
    }

    func reorder(_ orderedTasks: [TaskItem]) {
        for (index, task) in orderedTasks.enumerated() {
            task.orderIndex = Double(index + 1)
        }

        save()
    }

    func editingText(for task: TaskItem, language: AppLanguage) -> String {
        var parts = [task.title]

        parts += task.tags
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { "#\($0.name)" }

        if let project = task.project {
            parts.append(TaskTextParser.projectCommandToken(for: project.name))
        }

        if let dueDate = task.dueDate {
            parts.append(TaskDueDateFormatter.commandToken(for: dueDate, language: language))
        }

        if let recurrenceRule = task.recurrenceRule {
            parts.append(TaskRecurrenceFormatter.commandToken(for: recurrenceRule, language: language))
        }

        return parts.joined(separator: " ")
    }

    private static func effectiveOrderIndex(for task: TaskItem) -> Double {
        task.orderIndex == 0 ? -task.createdAt.timeIntervalSinceReferenceDate : task.orderIndex
    }

    private func makeNextOccurrenceIfNeeded(for task: TaskItem, now: Date) -> TaskItem? {
        guard let recurrenceRule = task.recurrenceRule else { return nil }

        return TaskItem(
            title: task.title,
            dueDate: recurrenceRule.nextDueDate(after: task.dueDate, now: now),
            isPinned: task.isPinned,
            orderIndex: -now.timeIntervalSinceReferenceDate,
            recurrenceRule: recurrenceRule,
            project: task.project,
            tags: task.tags
        )
    }

    private func findOrCreateTag(named name: String, existingTags: [TaskTag]) -> TaskTag {
        if let tag = existingTags.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return tag
        }

        let tag = TaskTag(name: name)
        modelContext.insert(tag)
        return tag
    }

    private func resolveProject(commandProjectName: String?, fallbackProject: Project?, existingProjects: [Project]) -> Project? {
        guard let commandProjectName, !commandProjectName.isEmpty else {
            return fallbackProject
        }

        if let project = existingProjects.first(where: { $0.name.caseInsensitiveCompare(commandProjectName) == .orderedSame }) {
            return project
        }

        let project = Project(
            name: commandProjectName,
            colorIndex: AppStyle.projectColorIndex(for: commandProjectName)
        )
        modelContext.insert(project)
        return project
    }

    private func save() {
        try? modelContext.save()
    }
}
