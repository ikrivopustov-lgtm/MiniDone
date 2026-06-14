import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Binding var selection: SidebarSelection
    @Binding var draggedTask: TaskItem?
    let language: AppLanguage

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Project.name)]) private var projects: [Project]
    @Query private var tasks: [TaskItem]
    @State private var isSettingsHovering = false

    private var activeTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    private var completedTasksCount: Int {
        tasks.filter(\.isCompleted).count
    }

    private var todayTasksCount: Int {
        tasks.filter { TaskListViewModel.isDueTodayOrOverdue($0) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        SidebarSectionTitle(LocalizationService.text(.tasks, language: language))

                        SidebarButton(
                            selection: $selection,
                            target: .allTasks,
                            title: LocalizationService.text(.allTasks, language: language),
                            systemImage: "list.bullet",
                            count: activeTasksCount,
                            accessibilityIdentifier: "sidebarAllTasks"
                        )

                        SidebarButton(
                            selection: $selection,
                            target: .today,
                            title: LocalizationService.text(.today, language: language),
                            systemImage: "calendar",
                            count: todayTasksCount > 0 ? todayTasksCount : nil,
                            accessibilityIdentifier: "sidebarToday"
                        )

                        SidebarButton(
                            selection: $selection,
                            target: .completed,
                            title: LocalizationService.text(.completed, language: language),
                            systemImage: "checkmark",
                            count: completedTasksCount > 0 ? completedTasksCount : nil,
                            accessibilityIdentifier: "sidebarCompleted"
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        SidebarSectionTitle(LocalizationService.text(.projects, language: language))

                        if projects.isEmpty {
                            Text(LocalizationService.text(.emptyProjects, language: language))
                                .font(AppStyle.font(12, .medium))
                                .foregroundStyle(AppStyle.secondaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(projects) { project in
                                ProjectSidebarRow(
                                    selection: $selection,
                                    draggedTask: $draggedTask,
                                    project: project,
                                    tasks: tasks,
                                    language: language
                                )
                            }
                        }
                    }
                }
                .padding(12)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity, alignment: .top)

            ProjectListView(language: language, existingProjects: projects)
                .padding(12)

            Divider()
                .overlay(AppStyle.divider)

            HStack {
                Button {
                    selection = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection == .settings ? AppStyle.primaryText : AppStyle.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(selection == .settings ? AppStyle.selectionBackground : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSettingsHovering && selection != .settings ? AppStyle.fieldBorder.opacity(0.65) : Color.clear, lineWidth: 0.8)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isSettingsHovering = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .help(LocalizationService.text(.settings, language: language))
                .accessibilityIdentifier("sidebarSettings")
                .accessibilityLabel(LocalizationService.text(.settings, language: language))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(AppStyle.sidebarBackground)
    }
}

private struct ProjectSidebarRow: View {
    @Binding var selection: SidebarSelection
    @Binding var draggedTask: TaskItem?
    let project: Project
    let tasks: [TaskItem]
    let language: AppLanguage

    @Environment(\.modelContext) private var modelContext
    @State private var isDropTargeted = false

    private var activeCount: Int {
        tasks.filter { !$0.isCompleted && $0.project?.name == project.name }.count
    }

    private var accessibilityIdentifier: String {
        "sidebarProject-\(project.name)"
    }

    var body: some View {
        SidebarButton(
            selection: $selection,
            target: .project(project.name),
            title: project.name,
            projectColor: AppStyle.projectColor(for: project),
            count: activeCount > 0 ? activeCount : nil,
            accessibilityIdentifier: accessibilityIdentifier,
            isDropTargeted: isDropTargeted,
            onProjectColorTap: {
                ProjectViewModel(modelContext: modelContext).cycleColor(for: project)
            }
        )
        .onDrop(of: [.plainText], isTargeted: $isDropTargeted, perform: moveDraggedTaskToProject)
        .contextMenu {
            Button(role: .destructive) {
                ProjectViewModel(modelContext: modelContext)
                    .deleteProject(project, allTasks: tasks)

                if selection == .project(project.name) {
                    selection = .allTasks
                }
            } label: {
                Label(LocalizationService.text(.deleteProject, language: language), systemImage: "trash")
            }
        }
    }

    private func moveDraggedTaskToProject(_ providers: [NSItemProvider]) -> Bool {
        guard let draggedTask else { return false }

        TaskListViewModel(modelContext: modelContext).move(draggedTask, to: project)
        self.draggedTask = nil
        selection = .project(project.name)
        return true
    }
}

private struct SidebarSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(AppStyle.font(11, .semibold))
            .foregroundStyle(AppStyle.mutedText)
            .padding(.horizontal, 10)
            .padding(.bottom, 2)
    }
}

private struct SidebarButton: View {
    @Binding var selection: SidebarSelection
    let target: SidebarSelection
    let title: String
    var systemImage: String?
    var projectColor: Color?
    let count: Int?
    let accessibilityIdentifier: String?
    var isDropTargeted = false
    var onProjectColorTap: (() -> Void)?
    @State private var isHovering = false

    init(
        selection: Binding<SidebarSelection>,
        target: SidebarSelection,
        title: String,
        systemImage: String? = nil,
        projectColor: Color? = nil,
        count: Int?,
        accessibilityIdentifier: String? = nil,
        isDropTargeted: Bool = false,
        onProjectColorTap: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.target = target
        self.title = title
        self.systemImage = systemImage
        self.projectColor = projectColor
        self.count = count
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isDropTargeted = isDropTargeted
        self.onProjectColorTap = onProjectColorTap
    }

    private var isSelected: Bool {
        selection == target
    }

    var body: some View {
        Button {
            selection = target
        } label: {
            HStack(spacing: 10) {
                icon

                Text(title)
                    .font(AppStyle.font(14, isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? AppStyle.primaryText : AppStyle.secondaryText)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if let count {
                    Text("\(count)")
                        .font(AppStyle.font(13, .semibold))
                        .foregroundStyle(isSelected ? AppStyle.primaryText : AppStyle.secondaryText)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(rowBorder, lineWidth: isDropTargeted ? 1.2 : 0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            updateCursor(isHovering: hovering)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
        .accessibilityLabel(Text(title))
        .accessibilityValue(count.map { "\($0)" } ?? "")
    }

    private var rowBackground: Color {
        if isSelected || isDropTargeted {
            return AppStyle.selectionBackground
        }

        return .clear
    }

    private var rowBorder: Color {
        if isDropTargeted {
            return AppStyle.fieldFocusedBorder.opacity(0.9)
        }

        if isHovering && !isSelected {
            return AppStyle.fieldBorder.opacity(0.65)
        }

        return .clear
    }

    @ViewBuilder
    private var icon: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? AppStyle.primaryText : AppStyle.secondaryText)
                .frame(width: 18)
        } else if let projectColor {
            Circle()
                .fill(projectColor)
                .frame(width: 8, height: 8)
                .frame(width: 18)
                .contentShape(Circle())
                .highPriorityGesture(TapGesture().onEnded {
                    onProjectColorTap?()
                })
        }
    }

    private func updateCursor(isHovering: Bool) {
        if isHovering {
            NSCursor.pointingHand.push()
        } else {
            NSCursor.pop()
        }
    }
}
