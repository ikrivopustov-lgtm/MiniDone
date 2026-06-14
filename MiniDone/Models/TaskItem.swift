import Foundation
import SwiftData

enum TaskRecurrenceRule: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String {
        rawValue
    }

    func nextDueDate(after dueDate: Date?, now: Date = .now, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        var candidate = calendar.startOfDay(for: dueDate ?? today)

        repeat {
            guard let nextDate = nextDate(after: candidate, calendar: calendar) else {
                return today
            }
            candidate = nextDate
        } while candidate <= today

        return candidate
    }

    private func nextDate(after date: Date, calendar: Calendar) -> Date? {
        switch self {
        case .daily:
            calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
}

@Model
final class TaskItem {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var isPinned: Bool = false
    var orderIndex: Double = 0
    var recurrenceRuleRawValue: String?
    @Relationship(inverse: \Project.tasks) var project: Project?
    @Relationship(inverse: \TaskTag.tasks) var tags: [TaskTag]

    var recurrenceRule: TaskRecurrenceRule? {
        get {
            recurrenceRuleRawValue.flatMap(TaskRecurrenceRule.init(rawValue:))
        }
        set {
            recurrenceRuleRawValue = newValue?.rawValue
        }
    }

    init(
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        isPinned: Bool = false,
        orderIndex: Double = 0,
        recurrenceRule: TaskRecurrenceRule? = nil,
        project: Project? = nil,
        tags: [TaskTag] = []
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.isPinned = isPinned
        self.orderIndex = orderIndex
        self.recurrenceRuleRawValue = recurrenceRule?.rawValue
        self.project = project
        self.tags = tags
    }
}
