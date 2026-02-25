import SwiftUI

// MARK: - TrackedScreenKey

/// Environment key for the current tracked screen name.
///
/// This is used by the DesignSystem layer to propagate screen context
/// through the SwiftUI environment. The Analytics module's
/// `TrackInteractionModifier` provides the full tracking implementation
/// with event recording and gesture capture.
private struct TrackedScreenKey: EnvironmentKey {
    static let defaultValue: String = ""
}

public extension EnvironmentValues {
    /// The current tracked screen name for interaction analytics.
    var trackedScreen: String {
        get { self[TrackedScreenKey.self] }
        set { self[TrackedScreenKey.self] = newValue }
    }
}

// MARK: - ScreenNameModifier

/// A lightweight view modifier that sets the tracked screen name
/// in the SwiftUI environment without performing any analytics
/// tracking itself.
///
/// For full interaction tracking (navigation events, tap capture,
/// signal detection), use the Analytics module's `.trackInteraction(screen:)`
/// modifier instead.
public struct ScreenNameModifier: ViewModifier {
    let screen: String

    public init(screen: String) {
        self.screen = screen
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.trackedScreen, screen)
    }
}

// MARK: - View Extension

public extension View {
    /// Sets the tracked screen name in the environment for analytics context.
    ///
    /// - Parameter screen: The screen name used when recording interaction events.
    /// - Returns: A modified view with the screen name set in the environment.
    func screenName(_ screen: String) -> some View {
        modifier(ScreenNameModifier(screen: screen))
    }
}
