import SwiftUI

/// A reusable empty state view displayed when a list or collection has no content.
///
/// Shows a centered icon, title, optional message, and optional action button
/// to guide the user toward creating their first item.
public struct EmptyStateView: View {
    private let icon: String
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String? = nil,
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
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color(.tertiaryLabel))

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
