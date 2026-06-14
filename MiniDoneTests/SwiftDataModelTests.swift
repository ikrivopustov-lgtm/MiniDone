import SwiftData
import XCTest
@testable import MiniDone

@MainActor
final class SwiftDataModelTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            TaskItem.self,
            Project.self,
            TaskTag.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    func testCreatesTask() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)

        viewModel.addTask(rawText: "Write tests", project: nil, existingTags: [], existingProjects: [])

        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Write tests")
        XCTAssertFalse(try XCTUnwrap(tasks.first).isCompleted)
    }

    func testCreatesTaskWithCommandProjectTagsAndDeadline() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)

        viewModel.addTask(rawText: "Обновить семантику #SEO /Changellenge !завтра", project: nil, existingTags: [], existingProjects: [])

        let task = try XCTUnwrap(try context.fetch(FetchDescriptor<TaskItem>()).first)
        XCTAssertEqual(task.title, "Обновить семантику")
        XCTAssertEqual(task.project?.name, "Changellenge")
        XCTAssertEqual(task.tags.map(\.name), ["seo"])
        XCTAssertNotNil(task.dueDate)
    }

    func testCreatesRecurringTaskFromCommandText() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)

        viewModel.addTask(rawText: "Оплатить сервер !monthly", project: nil, existingTags: [], existingProjects: [])

        let task = try XCTUnwrap(try context.fetch(FetchDescriptor<TaskItem>()).first)
        XCTAssertEqual(task.title, "Оплатить сервер")
        XCTAssertEqual(task.recurrenceRule, .monthly)
        XCTAssertNotNil(task.dueDate)
    }

    func testDeletesTaskPermanently() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let task = TaskItem(title: "Delete me")
        context.insert(task)
        try context.save()

        viewModel.delete(task)

        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertTrue(tasks.isEmpty)
    }

    func testCompletesTask() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let task = TaskItem(title: "Finish")
        context.insert(task)
        try context.save()

        viewModel.toggleCompletion(for: task)

        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    func testCompletingRecurringTaskCreatesNextOccurrence() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))
        let today = calendar.startOfDay(for: now)
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: today))
        let project = Project(name: "Ops")
        let tag = TaskTag(name: "billing")
        let task = TaskItem(
            title: "Pay invoice",
            dueDate: today,
            recurrenceRule: .daily,
            project: project,
            tags: [tag]
        )
        context.insert(project)
        context.insert(tag)
        context.insert(task)
        try context.save()

        let nextTask = viewModel.complete(task, now: now)

        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(nextTask?.title, "Pay invoice")
        XCTAssertEqual(nextTask?.dueDate, tomorrow)
        XCTAssertEqual(nextTask?.recurrenceRule, .daily)
        XCTAssertEqual(nextTask?.project?.name, "Ops")
        XCTAssertEqual(nextTask?.tags.map(\.name), ["billing"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskItem>()).count, 2)
    }

    func testRestoresCompletedTask() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let task = TaskItem(title: "Restore", isCompleted: true, completedAt: .now)
        context.insert(task)
        try context.save()

        viewModel.restore(task)

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
    }

    func testAssignsTaskToProject() throws {
        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        try context.save()

        TaskListViewModel(modelContext: context)
            .addTask(rawText: "Project task", project: project, existingTags: [], existingProjects: [project])

        let task = try XCTUnwrap(try context.fetch(FetchDescriptor<TaskItem>()).first)
        XCTAssertEqual(task.project?.name, "Work")
    }

    func testCreatesProject() throws {
        let context = try makeContext()
        let viewModel = ProjectViewModel(modelContext: context)

        XCTAssertTrue(viewModel.addProject(named: "Personal", existingProjects: []))

        let projects = try context.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(projects.map(\.name), ["Personal"])
    }

    func testBlocksDuplicateProjectNamesCaseInsensitively() throws {
        let context = try makeContext()
        let viewModel = ProjectViewModel(modelContext: context)

        XCTAssertTrue(viewModel.addProject(named: "Work", existingProjects: []))
        let projects = try context.fetch(FetchDescriptor<Project>())
        XCTAssertFalse(viewModel.addProject(named: " work ", existingProjects: projects))

        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 1)
    }

    func testDeletingProjectMovesTasksToInbox() throws {
        let context = try makeContext()
        let project = Project(name: "Work")
        let task = TaskItem(title: "Move me", project: project)
        context.insert(project)
        context.insert(task)
        try context.save()

        ProjectViewModel(modelContext: context).deleteProject(project, allTasks: [task])

        XCTAssertNil(task.project)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Project>()).isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskItem>()).count, 1)
    }

    func testCreatesAndReusesTags() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)

        viewModel.addTask(rawText: "First #SEO", project: nil, existingTags: [], existingProjects: [])
        let existingTags = try context.fetch(FetchDescriptor<TaskTag>())
        viewModel.addTask(rawText: "Second #seo", project: nil, existingTags: existingTags, existingProjects: [])

        let tags = try context.fetch(FetchDescriptor<TaskTag>())
        let tasks = try context.fetch(FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.title)]
        ))
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags.first?.name, "seo")
        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks.map(\.title), ["First", "Second"])
        XCTAssertEqual(tasks.map { $0.tags.map(\.name) }, [["seo"], ["seo"]])
    }

    func testCompletedTasksAreSortedNewestCompletionFirst() throws {
        let context = try makeContext()
        let oldTask = TaskItem(
            title: "Old",
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 100)
        )
        let activeTask = TaskItem(title: "Active")
        let newTask = TaskItem(
            title: "New",
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 200)
        )
        [oldTask, activeTask, newTask].forEach(context.insert)
        try context.save()

        let sorted = TaskListViewModel.completedTasksNewestFirst(
            from: try context.fetch(FetchDescriptor<TaskItem>())
        )

        XCTAssertEqual(sorted.map(\.title), ["New", "Old"])
    }

    func testUpdatesExistingTaskFromCommandText() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let project = Project(name: "Work")
        let task = TaskItem(title: "Draft")
        context.insert(project)
        context.insert(task)
        try context.save()

        viewModel.update(task: task, rawText: "Final title #ml /Work !завтра", existingTags: [], existingProjects: [project])

        XCTAssertEqual(task.title, "Final title")
        XCTAssertEqual(task.project?.name, "Work")
        XCTAssertEqual(task.tags.map(\.name), ["ml"])
        XCTAssertNotNil(task.dueDate)
    }

    func testEditingTextAndUpdatePreserveProjectNamesWithSpaces() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let project = Project(name: "Мой проект")
        let task = TaskItem(title: "Черновик", project: project)
        context.insert(project)
        context.insert(task)
        try context.save()

        let editingText = viewModel.editingText(for: task, language: .russian)
        XCTAssertEqual(editingText, "Черновик /\"Мой проект\"")

        viewModel.update(
            task: task,
            rawText: "Готовый текст #seo /\"Мой проект\"",
            existingTags: [],
            existingProjects: [project]
        )

        XCTAssertEqual(task.title, "Готовый текст")
        XCTAssertEqual(task.project?.name, "Мой проект")
        XCTAssertEqual(task.tags.map(\.name), ["seo"])
    }

    func testEditingTextIncludesRecurringCommand() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let task = TaskItem(title: "Оплатить сервер", recurrenceRule: .monthly)
        context.insert(task)
        try context.save()

        XCTAssertEqual(viewModel.editingText(for: task, language: .russian), "Оплатить сервер !ежемесячно")
        XCTAssertEqual(viewModel.editingText(for: task, language: .english), "Оплатить сервер !monthly")
    }

    func testReordersTasks() throws {
        let context = try makeContext()
        let viewModel = TaskListViewModel(modelContext: context)
        let first = TaskItem(title: "First")
        let second = TaskItem(title: "Second")
        let third = TaskItem(title: "Third")
        [first, second, third].forEach(context.insert)
        try context.save()

        viewModel.reorder([third, first, second])

        XCTAssertEqual(third.orderIndex, 1)
        XCTAssertEqual(first.orderIndex, 2)
        XCTAssertEqual(second.orderIndex, 3)
        XCTAssertEqual(TaskListViewModel.activeTasksSorted([first, second, third]).map(\.title), ["Third", "First", "Second"])
    }

    func testPinnedTasksSortBeforeRegularTasks() throws {
        let regular = TaskItem(title: "Regular", createdAt: Date(timeIntervalSince1970: 200))
        let pinned = TaskItem(title: "Pinned", createdAt: Date(timeIntervalSince1970: 100), isPinned: true)

        XCTAssertEqual(TaskListViewModel.activeTasksSorted([regular, pinned]).map(\.title), ["Pinned", "Regular"])
    }

    func testTodayFilterIncludesOverdueAndTodayTasks() throws {
        let calendar = Calendar.current
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 12)))
        let yesterday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 11)))
        let today = calendar.startOfDay(for: now)
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: today))
        let overdue = TaskItem(title: "Overdue", dueDate: yesterday)
        let todayTask = TaskItem(title: "Today", dueDate: today)
        let tomorrowTask = TaskItem(title: "Tomorrow", dueDate: tomorrow)

        XCTAssertTrue(TaskListViewModel.isDueTodayOrOverdue(overdue, now: now))
        XCTAssertTrue(TaskListViewModel.isDueTodayOrOverdue(todayTask, now: now))
        XCTAssertFalse(TaskListViewModel.isDueTodayOrOverdue(tomorrowTask, now: now))
    }

    func testSearchMatchesTitleProjectAndTags() throws {
        let project = Project(name: "Work")
        let tag = TaskTag(name: "seo")
        let task = TaskItem(title: "Update core", project: project, tags: [tag])

        XCTAssertTrue(TaskListViewModel.matchesSearch(task, searchText: "core"))
        XCTAssertTrue(TaskListViewModel.matchesSearch(task, searchText: "work"))
        XCTAssertTrue(TaskListViewModel.matchesSearch(task, searchText: "seo"))
        XCTAssertFalse(TaskListViewModel.matchesSearch(task, searchText: "home"))
    }

    func testDeleteSnapshotCanRestoreTask() throws {
        let context = try makeContext()
        let project = Project(name: "Work")
        let tag = TaskTag(name: "seo")
        let task = TaskItem(title: "Restore deleted", dueDate: .now, isPinned: true, project: project, tags: [tag])
        context.insert(project)
        context.insert(tag)
        context.insert(task)
        try context.save()

        let viewModel = TaskListViewModel(modelContext: context)
        let snapshot = viewModel.deleteWithSnapshot(task)
        XCTAssertTrue(try context.fetch(FetchDescriptor<TaskItem>()).isEmpty)

        viewModel.restoreDeletedTask(from: snapshot, existingProjects: [project], existingTags: [tag])
        let restored = try XCTUnwrap(try context.fetch(FetchDescriptor<TaskItem>()).first)
        XCTAssertEqual(restored.title, "Restore deleted")
        XCTAssertTrue(restored.isPinned)
        XCTAssertEqual(restored.project?.name, "Work")
        XCTAssertEqual(restored.tags.map(\.name), ["seo"])
    }

    func testClearCompletedDeletesOnlyCompletedTasks() throws {
        let context = try makeContext()
        let completed = TaskItem(title: "Done", isCompleted: true, completedAt: .now)
        let active = TaskItem(title: "Active")
        [completed, active].forEach(context.insert)
        try context.save()

        let snapshots = TaskListViewModel(modelContext: context).clearCompleted([completed])
        let remaining = try context.fetch(FetchDescriptor<TaskItem>())

        XCTAssertEqual(snapshots.map(\.title), ["Done"])
        XCTAssertEqual(remaining.map(\.title), ["Active"])
    }

    func testCyclesProjectColor() throws {
        let context = try makeContext()
        let project = Project(name: "Work", colorIndex: 0)
        context.insert(project)
        try context.save()

        ProjectViewModel(modelContext: context).cycleColor(for: project)

        XCTAssertEqual(project.colorIndex, 1)
    }
}
