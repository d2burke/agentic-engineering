import Foundation
import Analytics

/// A mock interaction tracker for use in unit and integration tests.
///
/// `MockInteractionTracker` conforms to `InteractionTracking` and records
/// all tracked events, registered detectors, and registered exporters
/// so tests can assert on analytics behavior without side effects.
///
/// ## Usage
/// ```swift
/// let tracker = MockInteractionTracker()
/// await tracker.track(InteractionEvent(type: .tap, screen: "Home"))
/// XCTAssertEqual(tracker.trackedEvents.count, 1)
/// ```
public actor MockInteractionTracker: InteractionTracking {

    // MARK: - Recorded State

    /// All events that have been passed to `track(_:)`.
    public private(set) var trackedEvents: [InteractionEvent] = []

    /// All detectors that have been registered via `registerDetector(_:)`.
    public private(set) var registeredDetectors: [any ExceptionalSignalDetector] = []

    /// All exporters that have been registered via `registerExporter(_:)`.
    public private(set) var registeredExporters: [any SignalExporter] = []

    // MARK: - Signal Stream

    private var signalContinuation: AsyncStream<ExceptionalSignal>.Continuation?

    /// An async stream of signals. In the mock, signals are only emitted
    /// when you explicitly call `emitSignal(_:)`.
    public nonisolated let signalStream: AsyncStream<ExceptionalSignal>

    // MARK: - Init

    public init() {
        var continuation: AsyncStream<ExceptionalSignal>.Continuation?
        self.signalStream = AsyncStream<ExceptionalSignal> { cont in
            continuation = cont
        }
        self.signalContinuation = continuation
    }

    // MARK: - InteractionTracking Conformance

    /// Records the event for later inspection in tests.
    public func track(_ event: InteractionEvent) async {
        trackedEvents.append(event)
    }

    /// Records the detector for later inspection in tests.
    public func registerDetector(_ detector: any ExceptionalSignalDetector) async {
        registeredDetectors.append(detector)
    }

    /// Records the exporter for later inspection in tests.
    public func registerExporter(_ exporter: any SignalExporter) async {
        registeredExporters.append(exporter)
    }

    // MARK: - Test Helpers

    /// Resets all recorded events, detectors, and exporters.
    public func reset() {
        trackedEvents.removeAll()
        registeredDetectors.removeAll()
        registeredExporters.removeAll()
    }

    /// Manually emit a signal into the `signalStream` for testing consumers.
    public func emitSignal(_ signal: ExceptionalSignal) {
        signalContinuation?.yield(signal)
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
