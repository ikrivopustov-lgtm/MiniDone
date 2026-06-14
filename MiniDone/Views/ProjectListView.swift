import SwiftData
import SwiftUI

struct ProjectListView: View {
    let language: AppLanguage
    let existingProjects: [Project]

    @Environment(\.modelContext) private var modelContext
    @State private var projectName = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    isFocused = true
                } else {
                    addProject()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("projectCreateButton")
            .accessibilityLabel(LocalizationService.text(.addProject, language: language))

            TextField(
                LocalizationService.text(.newProjectPlaceholder, language: language),
                text: $projectName,
                onCommit: addProject
            )
                .textFieldStyle(.plain)
                .font(AppStyle.font(13, .medium))
                .foregroundStyle(AppStyle.primaryText)
                .focused($isFocused)
                .accessibilityIdentifier("projectCreateField")
                .accessibilityLabel(LocalizationService.text(.newProjectPlaceholder, language: language))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .appFieldBackground(isFocused: isFocused)
    }

    private func addProject() {
        if ProjectViewModel(modelContext: modelContext)
            .addProject(named: projectName, existingProjects: existingProjects) {
            projectName = ""
        }
    }
}
