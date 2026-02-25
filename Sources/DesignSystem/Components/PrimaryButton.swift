import SwiftUI

/// A standard primary button following the TaskManager design system.
///
/// Provides consistent styling for primary call-to-action buttons
/// across the application, with loading state support.
public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? Color.gray : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(isDisabled || isLoading)
    }
}
