import SwiftData
import SwiftUI

struct AddTaskView: View {
    let project: Project?
    let existingTags: [TaskTag]
    let existingProjects: [Project]
    let language: AppLanguage
    var compact = false
    var fallbackDueDate: Date?

    @Environment(\.modelContext) private var modelContext
    @State private var taskText = ""
    @State private var inputResetID = UUID()
    @FocusState private var isFocused: Bool

    private var suggestions: [TaskInputSuggestion] {
        guard isFocused, let token = currentCommandToken else { return [] }

        if token.hasPrefix("#") {
            let prefix = String(token.dropFirst()).lowercased()
            return existingTags
                .map(\.name)
                .filter { prefix.isEmpty || $0.lowercased().hasPrefix(prefix) }
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                .prefix(5)
                .map { TaskInputSuggestion(label: "#\($0)", replacement: "#\($0)") }
        }

        if token.hasPrefix("/") {
            let prefix = TaskTextParser.normalizeProjectName(String(token.dropFirst())).lowercased()
            return existingProjects
                .map(\.name)
                .filter { prefix.isEmpty || $0.lowercased().hasPrefix(prefix) }
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                .prefix(5)
                .map {
                    TaskInputSuggestion(
                        label: $0,
                        replacement: TaskTextParser.projectCommandToken(for: $0)
                    )
                }
        }

        if token.hasPrefix("!") {
            let prefix = TaskTextParser.normalizeDueDateCommand(String(token.dropFirst()))
            return dateAndRepeatSuggestions
                .filter { prefix.isEmpty || TaskTextParser.normalizeDueDateCommand(String($0.replacement.dropFirst())).hasPrefix(prefix) }
                .prefix(7)
                .map { $0 }
        }

        return []
    }

    private var dateAndRepeatSuggestions: [TaskInputSuggestion] {
        let weekdayToken = language == .russian ? "!пн" : "!mon"
        let relativeToken = language == .russian ? "!+3" : "!+3"

        return [
            TaskInputSuggestion(label: language == .russian ? "!сегодня" : "!today", replacement: language == .russian ? "!сегодня" : "!today"),
            TaskInputSuggestion(label: language == .russian ? "!завтра" : "!tomorrow", replacement: language == .russian ? "!завтра" : "!tomorrow"),
            TaskInputSuggestion(label: weekdayToken, replacement: weekdayToken),
            TaskInputSuggestion(label: relativeToken, replacement: relativeToken),
            TaskInputSuggestion(label: TaskRecurrenceFormatter.commandToken(for: .daily, language: language), replacement: TaskRecurrenceFormatter.commandToken(for: .daily, language: language)),
            TaskInputSuggestion(label: TaskRecurrenceFormatter.commandToken(for: .weekly, language: language), replacement: TaskRecurrenceFormatter.commandToken(for: .weekly, language: language)),
            TaskInputSuggestion(label: TaskRecurrenceFormatter.commandToken(for: .monthly, language: language), replacement: TaskRecurrenceFormatter.commandToken(for: .monthly, language: language))
        ]
    }

    private var currentCommandToken: String? {
        let trimmedText = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let token = trimmedText.split(separator: " ").last else { return nil }
        let value = String(token)
        return value.hasPrefix("#") || value.hasPrefix("/") || value.hasPrefix("!") ? value : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 9) {
                Button {
                    if taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        isFocused = true
                    } else {
                        addTask()
                    }
                } label: {
                    Image(systemName: compact ? "plus" : "plus.circle")
                        .font(.system(size: compact ? 14 : 16, weight: .medium))
                        .foregroundStyle(AppStyle.secondaryText)
                        .frame(width: compact ? 18 : 20, height: compact ? 18 : 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("addTaskButton")
                .accessibilityLabel(LocalizationService.text(.newTaskPlaceholder, language: language))

                TextField(
                    LocalizationService.text(.newTaskPlaceholder, language: language),
                    text: $taskText,
                    onCommit: addTask
                )
                    .id(inputResetID)
                    .textFieldStyle(.plain)
                    .font(AppStyle.font(compact ? 13 : 14, .medium))
                    .foregroundStyle(AppStyle.primaryText)
                    .focused($isFocused)
                    .accessibilityIdentifier("addTaskField")
                    .accessibilityLabel(LocalizationService.text(.newTaskPlaceholder, language: language))

                if !compact {
                    Image(systemName: "return")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppStyle.mutedText)
                }
            }
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, compact ? 7 : 9)
            .appFieldBackground(isFocused: isFocused, cornerRadius: compact ? 8 : 9)

            if !suggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(suggestions) { suggestion in
                            Button {
                                applySuggestion(suggestion)
                            } label: {
                                Text(suggestion.label)
                                    .font(AppStyle.font(compact ? 10 : 11, .semibold))
                                    .lineLimit(1)
                                    .padding(.horizontal, compact ? 7 : 8)
                                    .padding(.vertical, compact ? 3 : 4)
                                    .background(AppStyle.panelBackground, in: RoundedRectangle(cornerRadius: 6))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(AppStyle.fieldBorder, lineWidth: 0.6)
                                    }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(AppStyle.secondaryText)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func addTask() {
        let didAdd = TaskListViewModel(modelContext: modelContext)
            .addTask(
                rawText: taskText,
                project: project,
                existingTags: existingTags,
                existingProjects: existingProjects,
                fallbackDueDate: fallbackDueDate
            )

        if didAdd {
            taskText = ""
            inputResetID = UUID()
            isFocused = true
        }
    }

    private func applySuggestion(_ suggestion: TaskInputSuggestion) {
        guard let token = currentCommandToken else { return }

        let trimmedText = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = trimmedText.range(of: token, options: .backwards) else { return }

        taskText = trimmedText.replacingCharacters(in: range, with: suggestion.replacement) + " "
        isFocused = true
    }
}

private struct TaskInputSuggestion: Identifiable {
    let id = UUID()
    let label: String
    let replacement: String
}
