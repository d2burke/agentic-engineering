import SwiftUI
import Models
import DesignSystem

// MARK: - BoardColumnView

/// A single Kanban column displaying tasks in a given status.
///
/// Features a header with status name and task count, a vertical list
/// of task cards, and drag-and-drop support using iOS 17's `.draggable`
/// and `.dropDestination` modifiers. An "Add task" button at the bottom
/// provides quick task creation within the column.
public struct BoardColumnView: View {
    let column: BoardColumn
    let onTaskTap: (TaskItem) -> Void
    let onDropTask: (UUID) -> Void
    let onAddTask: () -> Void

    private let columnWidth: CGFloat = 280

    public init(
        column: BoardColumn,
        onTaskTap: @escaping (TaskItem) -> Void,
        onDropTask: @escaping (UUID) -> Void,
        onAddTask: @escaping () -> Void
    ) {
        self.column = column
        self.onTaskTap = onTaskTap
        self.onDropTask = onDropTask
        self.onAddTask = onAddTask
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader
            taskList
            addTaskButton
        }
        .frame(width: columnWidth)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(ColorTokens.backgroundTertiary)
        )
        .dropDestination(for: String.self) { items, _ in
            guard let taskIdString = items.first,
                  let taskId = UUID(uuidString: taskIdString) else {
                return false
            }
            onDropTask(taskId)
            return true
        }
    }

    // MARK: - Header

    private var columnHeader: some View {
        HStack {
            StatusBadge(status: column.status)

            Spacer()

            Text("\(column.tasks.count)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(ColorTokens.backgroundSecondary)
                )
        }
        .padding(Spacing.md)
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(column.tasks) { task in
                    TaskCard(
                        title: task.title,
                        status: task.status,
                        priority: task.priority,
                        assigneeName: task.assigneeId != nil ? "Assignee" : nil,
                        dueDate: task.dueDate,
                        commentCount: task.commentCount
                    )
                    .draggable(task.id.uuidString)
                    .onTapGesture {
                        onTaskTap(task)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .frame(minHeight: 200)
    }

    // MARK: - Add Task Button

    private var addTaskButton: some View {
        Button {
            onAddTask()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(Typography.caption)
                Text("Add Task")
                    .font(Typography.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
}
