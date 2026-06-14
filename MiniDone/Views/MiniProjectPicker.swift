import SwiftUI

struct MiniProjectPicker: View {
    @Binding var selectedProjectName: String?
    let projects: [Project]
    let language: AppLanguage

    var body: some View {
        Menu {
            Button(LocalizationService.text(.allTasks, language: language)) {
                selectedProjectName = nil
            }

            ForEach(projects) { project in
                Button(project.name) {
                    selectedProjectName = project.name
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
                    .frame(width: 16)

                Text(selectedTitle)
                    .font(AppStyle.font(12, .semibold))
                    .foregroundStyle(AppStyle.primaryText)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppStyle.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .appFieldBackground(cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }

    private var selectedTitle: String {
        selectedProjectName ?? LocalizationService.text(.allTasks, language: language)
    }
}
