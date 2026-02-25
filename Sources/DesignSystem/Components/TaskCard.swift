import SwiftUI
import Models

// MARK: - TaskCard

/// A card component displaying a task summary with status, priority,
/// assignee, due date, and comment count.
///
/// Used in board columns, list views, and search results. The card
/// uses the design system's color tokens, typography, and spacing
/// for visual consistency.
public struct TaskCard: View {
    private let title: String
    private let status: TaskStatus
    private let priority: TaskPriority
    private let assigneeName: String?
    private let dueDate: Date?
    private let commentCount: Int

    /// - Parameters:
    ///   - title: The task title.
    ///   - status: Current lifecycle status.
    ///   - priority: Task priority level.
    ///   - assigneeName: Optional name of the assigned user.
    ///   - dueDate: Optional due date.
    ///   - commentCount: Number of comments on the task.
    public init(
        title: String,
        status: TaskStatus,
        priority: TaskPriority,
        assigneeName: String? = nil,
        dueDate: Date? = nil,
        commentCount: Int = 0
    ) {
        self.title = title
        self.status = status
        self.priority = priority
        self.assigneeName = assigneeName
        self.dueDate = dueDate
        self.commentCount = commentCount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Title
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(2)

            // Status + Priority row
            HStack(spacing: Spacing.sm) {
                StatusBadge(status: status)
                PriorityBadge(priority: priority)
                Spacer()
            }

            // Bottom row: assignee, due date, comments
            HStack(spacing: Spacing.sm) {
                if let assigneeName = assigneeName {
                    AvatarView(name: assigneeName, size: 24)
                    Text(assigneeName)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if let dueDate = dueDate {
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

                if commentCount > 0 {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "bubble.left")
                            .font(Typography.caption)
                        Text("\(commentCount)")
                            .font(Typography.caption)
                    }
                    .foregroundStyle(ColorTokens.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Task Card") {
    VStack(spacing: 16) {
        TaskCard(
            title: "Implement user authentication flow",
            status: .inProgress,
            priority: .high,
            assigneeName: "Alice Johnson",
            dueDate: Date().addingTimeInterval(86400 * 3),
            commentCount: 5
        )

        TaskCard(
            title: "Fix login page crash on iPad",
            status: .todo,
            priority: .critical,
            dueDate: Date().addingTimeInterval(-86400),
            commentCount: 2
        )

        TaskCard(
            title: "Update README documentation",
            status: .done,
            priority: .low
        )
    }
    .padding()
}
#endif
