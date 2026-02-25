import SwiftUI
import Models

/// A badge displaying a task priority level with an icon and color.
///
/// Uses SF Symbols and color coding to communicate urgency at a glance.
public struct PriorityBadge: View {
    private let priority: TaskPriority

    public init(priority: TaskPriority) {
        self.priority = priority
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: priority.iconName)
                .font(.caption2)
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(backgroundColor.opacity(0.12))
        .foregroundStyle(backgroundColor)
        .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .blue
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}
