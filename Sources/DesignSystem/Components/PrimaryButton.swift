import SwiftUI

// MARK: - PrimaryButton

/// A full-width primary call-to-action button following the TaskManager
/// design system.
///
/// Supports an optional leading SF Symbol icon, loading state with
/// a `ProgressView`, and a disabled state with reduced opacity.
public struct PrimaryButton: View {
    private let title: String
    private let icon: String?
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    /// - Parameters:
    ///   - title: The button label text.
    ///   - icon: Optional SF Symbol name displayed before the title.
    ///   - isLoading: When `true`, shows a spinner and disables interaction.
    ///   - isDisabled: When `true`, reduces opacity and disables interaction.
    ///   - action: The closure executed on tap.
    public init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(Typography.body)
                }
                Text(title)
                    .font(Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(ColorTokens.primary)
            )
            .foregroundStyle(.white)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Primary Buttons") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Create Task", icon: "plus") {
            // Action
        }

        PrimaryButton(title: "Loading...", isLoading: true) {
            // Action
        }

        PrimaryButton(title: "Disabled", isDisabled: true) {
            // Action
        }
    }
    .padding()
}
#endif
