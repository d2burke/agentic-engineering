import SwiftUI

// MARK: - InteractionTrackerKey

/// Environment key for injecting the `InteractionTracking` instance
/// into the SwiftUI environment.
public struct InteractionTrackerKey: EnvironmentKey {
    public static let defaultValue: (any InteractionTracking)? = nil
}

public extension EnvironmentValues {
    /// The current interaction tracker, if one has been provided.
    var interactionTracker: (any InteractionTracking)? {
        get { self[InteractionTrackerKey.self] }
        set { self[InteractionTrackerKey.self] = newValue }
    }
}

// MARK: - TrackInteractionModifier

/// A SwiftUI `ViewModifier` that automatically tracks navigation and
/// tap interaction events for the analytics pipeline.
///
/// When the modified view appears, a `.navigate` event is recorded.
/// A transparent tap gesture overlay captures `.tap` events with
/// screen coordinates, enabling spatial pattern detection (e.g., rage taps).
///
/// ## Usage
/// ```swift
/// MyView()
///     .trackInteraction(screen: "TaskDetail")
///     .environment(\.interactionTracker, tracker)
/// ```
public struct TrackInteractionModifier: ViewModifier {
    /// The screen name to associate with tracked events.
    public let screen: String

    @Environment(\.interactionTracker) private var tracker

    public init(screen: String) {
        self.screen = screen
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                let event = InteractionEvent(
                    type: .navigate,
                    screen: screen,
                    metadata: ["action": "screen_appeared"]
                )
                Task {
                    await tracker?.track(event)
                }
            }
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let event = InteractionEvent(
                            type: .tap,
                            screen: screen,
                            point: CGPoint(x: value.location.x, y: value.location.y),
                            metadata: ["action": "tap"]
                        )
                        Task {
                            await tracker?.track(event)
                        }
                    }
            )
    }
}

// MARK: - View Extension

public extension View {
    /// Track user interactions on this view for analytics.
    ///
    /// - Parameter screen: A stable identifier for the screen/view.
    /// - Returns: The modified view with interaction tracking enabled.
    func trackInteraction(screen: String) -> some View {
        modifier(TrackInteractionModifier(screen: screen))
    }
}
