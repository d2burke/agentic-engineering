import SwiftUI

// MARK: - LoadingOverlay

/// A semi-transparent overlay with a centered `ProgressView` that
/// blocks user interaction while an asynchronous operation is in flight.
///
/// Usage:
/// ```swift
/// ZStack {
///     MyContentView()
///     LoadingOverlay(isShowing: viewModel.isLoading)
/// }
/// ```
public struct LoadingOverlay: View {
    private let isShowing: Bool

    /// - Parameter isShowing: Controls visibility. When `false`, the
    ///   overlay is removed from the view hierarchy entirely.
    public init(isShowing: Bool) {
        self.isShowing = isShowing
    }

    public var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(ColorTokens.primary)
                }
                .padding(Spacing.xl)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
            .allowsHitTesting(true)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Loading Overlay") {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        Text("Content behind overlay")
        LoadingOverlay(isShowing: true)
    }
}
#endif
