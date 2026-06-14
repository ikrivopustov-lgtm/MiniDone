import Foundation
import SwiftData

@MainActor
struct ProjectViewModel {
    let modelContext: ModelContext

    func addProject(named rawName: String, existingProjects: [Project]) -> Bool {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }

        let alreadyExists = existingProjects.contains {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }

        guard !alreadyExists else { return false }

        modelContext.insert(Project(name: name, colorIndex: AppStyle.projectColorIndex(for: name)))
        save()
        return true
    }

    func deleteProject(_ project: Project, allTasks: [TaskItem]) {
        for task in allTasks where task.project?.name == project.name {
            task.project = nil
        }

        modelContext.delete(project)
        save()
    }

    func renameProject(_ project: Project, to rawName: String, existingProjects: [Project]) -> Bool {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }

        let alreadyExists = existingProjects.contains {
            $0 !== project && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }

        guard !alreadyExists else { return false }

        project.name = name
        save()
        return true
    }

    func cycleColor(for project: Project) {
        project.colorIndex = AppStyle.normalizedProjectColorIndex(project.colorIndex + 1)
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}
