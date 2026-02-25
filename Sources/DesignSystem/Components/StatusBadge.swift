import SwiftUI
import Models

// MARK: - StatusBadge

/// A colored pill badge displaying a task's lifecycle status.
///
/// Color mapping provides instant visual recognition:
/// - **To Do** → gray (neutral, not started)
/// - **In Progress** → blue (active work)
/// - **In Review** → orange (awaiting feedback)
/// - **Done** → green (completed)
/// - **Archived** → secondary (historical)
public struct StatusBadge: View {
    private let status: TaskStatus

    public init(status: TaskStatus) {
        self.status = status
    }

    public var body: some View {
        Text(status.displayName)
            .font(Typography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .todo:
            return .gray
        case .inProgress:
            return ColorTokens.info
        case .inReview:
            return ColorTokens.warning
        case .done:
            return ColorTokens.success
        case .archived:
            return ColorTokens.secondary
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Status Badges") {
    VStack(spacing: 12) {
        ForEach(TaskStatus.allCases) { status in
            StatusBadge(status: status)
        }
    }
    .padding()
}
#endif
