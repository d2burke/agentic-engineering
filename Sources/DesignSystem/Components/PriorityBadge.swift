import SwiftUI
import Models

// MARK: - PriorityBadge

/// A compact badge showing a task's priority level with an SF Symbol
/// icon and semantic color coding.
///
/// Color mapping:
/// - **Low** → green (safe / no rush)
/// - **Medium** → yellow (normal attention)
/// - **High** → orange (elevated urgency)
/// - **Critical** → red (immediate action required)
public struct PriorityBadge: View {
    private let priority: TaskPriority

    public init(priority: TaskPriority) {
        self.priority = priority
    }

    public var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: priority.iconName)
                .font(Typography.caption)
            Text(priority.displayName)
                .font(Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(priorityColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(priorityColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch priority {
        case .low:
            return ColorTokens.success
        case .medium:
            return ColorTokens.warning
        case .high:
            return .orange
        case .critical:
            return ColorTokens.error
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Priority Badges") {
    VStack(spacing: 12) {
        ForEach(TaskPriority.allCases) { priority in
            PriorityBadge(priority: priority)
        }
    }
    .padding()
}
#endif
