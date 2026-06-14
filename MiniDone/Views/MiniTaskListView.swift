import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MiniTaskListView: View {
    let activeTasks: [TaskItem]
    let showsProject: Bool
    let language: AppLanguage
    var onUndoAction: (UndoAction) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @State private var draggedTask: TaskItem?

    var body: some View {
        Group {
            if activeTasks.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        systemImage: "tray",
                        title: LocalizationService.text(.emptyMiniTasks, language: language)
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(activeTasks) { task in
                            MiniTaskRowView(
                                task: task,
                                language: language,
                                showsProject: showsProject,
                                onUndoAction: onUndoAction
                            )
                            .onDrag {
                                draggedTask = task
                                return NSItemProvider(object: Constants.DragPayload.task as NSString)
                            }
                            .onDrop(
                                of: [.plainText],
                                delegate: TaskReorderDropDelegate(
                                    targetTask: task,
                                    visibleTasks: activeTasks,
                                    draggedTask: $draggedTask,
                                    modelContext: modelContext
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.windowBackground)
    }
}
