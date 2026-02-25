import SwiftUI
import Models
import DesignSystem

// MARK: - ActivityEntry

/// Represents a single entry in the task activity timeline.
struct ActivityEntry: Identifiable {
    let id = UUID()
    let icon: String
    let description: String
    let timestamp: Date
    let actorName: String
}

// MARK: - ActivityLogView

/// A timeline view showing the history of changes made to a task.
///
/// Displays status changes, assignments, comment additions, and other
/// significant task events in reverse chronological order. Each entry
/// includes an icon, description, timestamp, and the actor's name.
public struct ActivityLogView: View {
    let task: TaskItem?

    public init(task: TaskItem?) {
        self.task = task
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let task {
                let entries = buildActivityEntries(for: task)

                if entries.isEmpty {
                    Text("No activity yet")
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .padding(.vertical, Spacing.sm)
                } else {
                    ForEach(entries) { entry in
                        ActivityRowView(entry: entry, isLast: entry.id == entries.last?.id)
                    }
                }
            } else {
                Text("No activity available")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .padding(.vertical, Spacing.sm)
            }
        }
    }

    // MARK: - Build Entries

    private func buildActivityEntries(for task: TaskItem) -> [ActivityEntry] {
        var entries: [ActivityEntry] = []

        entries.append(ActivityEntry(
            icon: "plus.circle.fill",
            description: "Task created",
            timestamp: task.createdAt,
            actorName: "Creator"
        ))

        if task.createdAt != task.updatedAt {
            entries.append(ActivityEntry(
                icon: "pencil.circle.fill",
                description: "Task updated",
                timestamp: task.updatedAt,
                actorName: "Editor"
            ))
        }

        if task.status != .todo {
            entries.append(ActivityEntry(
                icon: "arrow.right.circle.fill",
                description: "Status changed to \(task.status.displayName)",
                timestamp: task.updatedAt,
                actorName: "Editor"
            ))
        }

        if task.assigneeId != nil {
            entries.append(ActivityEntry(
                icon: "person.circle.fill",
                description: "Task assigned",
                timestamp: task.updatedAt,
                actorName: "Manager"
            ))
        }

        if task.commentCount > 0 {
            entries.append(ActivityEntry(
                icon: "bubble.left.circle.fill",
                description: "\(task.commentCount) comment(s) added",
                timestamp: task.updatedAt,
                actorName: "Team"
            ))
        }

        return entries.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - ActivityRowView

/// A single row in the activity timeline.
struct ActivityRowView: View {
    let entry: ActivityEntry
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(spacing: 0) {
                Image(systemName: entry.icon)
                    .font(Typography.body)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(width: 28, height: 28)

                if !isLast {
                    Rectangle()
                        .fill(ColorTokens.border)
                        .frame(width: 2)
                        .frame(minHeight: 24)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(entry.description)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textPrimary)

                HStack(spacing: Spacing.xs) {
                    Text(entry.actorName)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textSecondary)

                    Text(entry.timestamp, style: .relative)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}
