import Foundation
import Analytics

/// A mock interaction tracker for use in unit and integration tests.
///
/// `MockInteractionTracker` conforms to `InteractionTracking` and records
/// all tracked events and registered detectors so tests can assert on
/// analytics behavior without side effects.
///
/// ## Usage
/// ```swift
/// let tracker = MockInteractionTracker()
/// viewModel.interactionTracker = tracker
/// viewModel.didTapButton()
/// XCTAssertEqual(tracker.trackedEvents.count, 1)
/// ```
public final class MockInteractionTracker: InteractionTracking, @unchecked Sendable {

    // MARK: - Recorded State

    /// All events that have been passed to `track(_:)`.
    public private(set) var trackedEvents: [InteractionEvent] = []

    /// All detectors that have been registered via `register(detector:)`.
    public private(set) var registeredDetectors: [any ExceptionalSignalDetector] = []

    // MARK: - Init

    public init() {}

    // MARK: - InteractionTracking Conformance

    /// Records the event for later inspection in tests.
    public func track(_ event: InteractionEvent) {
        trackedEvents.append(event)
    }

    /// Records the detector for later inspection in tests.
    public func register(detector: any ExceptionalSignalDetector) {
        registeredDetectors.append(detector)
    }

    // MARK: - Test Helpers

    /// Resets all recorded events and detectors.
    public func reset() {
        trackedEvents.removeAll()
        registeredDetectors.removeAll()
    }

    /// Returns all tracked events with the given type.
    public func events(ofType type: InteractionType) -> [InteractionEvent] {
        trackedEvents.filter { $0.type == type }
    }

    /// Returns all tracked events on the given screen.
    public func events(onScreen screen: String) -> [InteractionEvent] {
        trackedEvents.filter { $0.screen == screen }
    }

    /// Whether any event with the given type has been tracked.
    public func hasTracked(type: InteractionType) -> Bool {
        trackedEvents.contains { $0.type == type }
    }
}
