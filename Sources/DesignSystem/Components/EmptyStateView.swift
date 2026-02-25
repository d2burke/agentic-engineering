import SwiftUI

// MARK: - EmptyStateView

/// A centered placeholder view displayed when a list or collection
/// has no content.
///
/// Shows an SF Symbol icon, a title, a descriptive message, and an
/// optional call-to-action button to guide the user toward their
/// next step.
public struct EmptyStateView: View {
    private let icon: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    /// - Parameters:
    ///   - icon: An SF Symbol name displayed prominently above the title.
    ///   - title: The primary empty-state headline.
    ///   - message: A supporting description explaining why the view is empty.
    ///   - actionTitle: Optional label for a call-to-action button.
    ///   - action: Optional closure executed when the action button is tapped.
    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(ColorTokens.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(message)
                    .font(Typography.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typography.headline)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(ColorTokens.primary)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.lg)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "No Tasks Yet",
        message: "Create your first task to get started with project management.",
        actionTitle: "Create Task"
    ) {
        // Action
    }
}
#endif
