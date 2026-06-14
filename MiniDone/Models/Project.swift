import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date
    var colorIndex: Int = 0
    var tasks: [TaskItem]

    init(name: String, createdAt: Date = .now, colorIndex: Int = 0, tasks: [TaskItem] = []) {
        self.name = name
        self.createdAt = createdAt
        self.colorIndex = colorIndex
        self.tasks = tasks
    }
}
