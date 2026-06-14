import Foundation
import SwiftData

@Model
final class TaskTag {
    var name: String
    var createdAt: Date
    var tasks: [TaskItem]

    init(name: String, createdAt: Date = .now, tasks: [TaskItem] = []) {
        self.name = name
        self.createdAt = createdAt
        self.tasks = tasks
    }
}
