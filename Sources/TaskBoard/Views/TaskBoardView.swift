import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - TaskBoardView

/// The main Kanban board view displaying tasks organized in status columns.
///
/// Features a horizontal ScrollView of columns, a filter bar at the top,
/// search capability, and toolbar actions for switching to list view or
/// adding a new task. This is the PRIMARY target for interaction tracking
/// in the experimentation pipeline.
public struct TaskBoardView: View {
    @Bindable var viewModel: TaskBoardViewModel
    let projectId: UUID
    let onSelectTask: (TaskItem) -> Void
    let onCreateTask: () -> Void
    let onSwitchToList: (() -> Void)?

    @State private var showingCreateTask = false

    public init(
        viewModel: TaskBoardViewModel,
        projectId: UUID,
        onSelectTask: @escaping (TaskItem) -> Void,
        onCreateTask: @escaping () -> Void,
        onSwitchToList: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.projectId = projectId
        self.onSelectTask = onSelectTask
        self.onCreateTask = onCreateTask
        self.onSwitchToList = onSwitchToList
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !viewModel.activeFilters.isEmpty || !viewModel.allTasks.isEmpty {
                FilterBar(
                    activeFilters: viewModel.activeFilters,
                    onRemoveFilter: { viewModel.removeFilter($0) },
                    onClearAll: { viewModel.clearFilters() }
                )
            }

            if viewModel.columns.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "rectangle.3.group",
                    title: "No Tasks",
                    message: "Create your first task to populate the board.",
                    actionTitle: "Create Task"
                ) {
                    onCreateTask()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        ForEach(viewModel.columns) { column in
                            BoardColumnView(
                                column: column,
                                onTaskTap: { task in
                                    viewModel.trackTaskTap(taskId: task.id)
                                    onSelectTask(task)
                                },
                                onDropTask: { taskId in
                                    Task {
                                        await viewModel.moveTask(
                                            taskId: taskId,
                                            toStatus: column.status
                                        )
                                    }
                                },
                                onAddTask: onCreateTask
                            )
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        .overlay {
            LoadingOverlay(isShowing: viewModel.isLoading && viewModel.allTasks.isEmpty)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let onSwitchToList {
                    Button {
                        onSwitchToList()
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }

                Button {
                    onCreateTask()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.loadTasks(projectId: projectId)
        }
        .trackInteraction(screen: "TaskBoard")
    }
}
