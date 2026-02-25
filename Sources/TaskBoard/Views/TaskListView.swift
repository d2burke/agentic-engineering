import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - TaskListView

/// An alternative list layout for viewing tasks grouped by status.
///
/// Provides the same data as the Kanban board but in a vertical list
/// format, grouped by task status sections. Useful for users who prefer
/// a more compact, linear view of their tasks.
public struct TaskListView: View {
    @Bindable var viewModel: TaskBoardViewModel
    let projectId: UUID
    let onSelectTask: (TaskItem) -> Void
    let onCreateTask: () -> Void
    let onSwitchToBoard: (() -> Void)?

    public init(
        viewModel: TaskBoardViewModel,
        projectId: UUID,
        onSelectTask: @escaping (TaskItem) -> Void,
        onCreateTask: @escaping () -> Void,
        onSwitchToBoard: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.projectId = projectId
        self.onSelectTask = onSelectTask
        self.onCreateTask = onCreateTask
        self.onSwitchToBoard = onSwitchToBoard
    }

    public var body: some View {
        Group {
            if viewModel.allTasks.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "checklist",
                    title: "No Tasks",
                    message: "Create your first task to get started.",
                    actionTitle: "Create Task"
                ) {
                    onCreateTask()
                }
            } else {
                List {
                    ForEach(viewModel.columns) { column in
                        if !column.tasks.isEmpty {
                            Section {
                                ForEach(column.tasks) { task in
                                    TaskListRowView(task: task)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.trackTaskTap(taskId: task.id)
                                            onSelectTask(task)
                                        }
                                }
                            } header: {
                                HStack {
                                    StatusBadge(status: column.status)
                                    Spacer()
                                    Text("\(column.tasks.count)")
                                        .font(Typography.caption)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    if let projectId = viewModel.projectId {
                        await viewModel.loadTasks(projectId: projectId)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        .overlay {
            LoadingOverlay(isShowing: viewModel.isLoading && viewModel.allTasks.isEmpty)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let onSwitchToBoard {
                    Button {
                        onSwitchToBoard()
                    } label: {
                        Image(systemName: "rectangle.3.group")
                    }
                }

                Button {
                    onCreateTask()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadTasks(projectId: projectId)
        }
        .trackInteraction(screen: "TaskList")
    }
}

// MARK: - TaskListRowView

/// A single row in the task list view showing task details in a compact format.
struct TaskListRowView: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(task.title)
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                PriorityBadge(priority: task.priority)

                if let dueDate = task.dueDate {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar")
                            .font(Typography.caption)
                        Text(dueDate, style: .date)
                            .font(Typography.caption)
                    }
                    .foregroundStyle(
                        dueDate < Date() ? ColorTokens.error : ColorTokens.textSecondary
                    )
                }

                Spacer()

                if task.commentCount > 0 {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "bubble.left")
                            .font(Typography.caption2)
                        Text("\(task.commentCount)")
                            .font(Typography.caption2)
                    }
                    .foregroundStyle(ColorTokens.textTertiary)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}
