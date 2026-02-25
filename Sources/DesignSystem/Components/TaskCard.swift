import SwiftUI
import Models

/// A card component displaying a task's key information in a compact layout.
///
/// Used in both the Kanban board columns and list views. Displays the task title,
/// priority badge, assignee avatar, and optional due date indicator.
public struct TaskCard: View {
    private let task: TaskItem
    private let onTap: (() -> Void)?

    public init(task: TaskItem, onTap: (() -> Void)? = nil) {
        self.task = task
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.label))
                        .lineLimit(2)
                    Spacer()
                }

                HStack(spacing: 6) {
                    PriorityBadge(priority: task.priority)

                    if !task.tags.isEmpty {
                        Text(task.tags.first ?? "")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(Color.blue)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if let dueDate = task.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption2)
                        }
                        .foregroundStyle(dueDate < Date() ? Color.red : Color(.secondaryLabel))
                    }
                }

                if task.assigneeId != nil {
                    HStack(spacing: 4) {
                        AvatarView(name: "Assignee", size: 20)
                        if task.commentCount > 0 {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "bubble.left")
                                    .font(.caption2)
                                Text("\(task.commentCount)")
                                    .font(.caption2)
                            }
                            .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
