import SwiftUI
import Models

/// A badge displaying a task status with a colored background.
///
/// Provides visual differentiation between task lifecycle states
/// using color-coded pill-shaped badges.
public struct StatusBadge: View {
    private let status: TaskStatus

    public init(status: TaskStatus) {
        self.status = status
    }

    public var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .todo:
            return .gray
        case .inProgress:
            return .blue
        case .inReview:
            return .orange
        case .done:
            return .green
        case .archived:
            return .secondary
        }
    }
}
