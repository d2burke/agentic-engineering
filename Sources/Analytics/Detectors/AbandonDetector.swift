import Foundation

// MARK: - AbandonDetector

/// Detects when a user navigates to a screen and leaves without
/// meaningful interaction — an "abandon" signal.
///
/// An abandon occurs when:
/// 1. A `.navigate` event is recorded for screen A.
/// 2. Fewer than `minimumInteractions` non-navigate events occur on screen A.
/// 3. A subsequent `.navigate` event to a **different** screen arrives
///    within `abandonThresholdSeconds`.
///
/// This pattern often indicates confusing navigation, misleading labels,
/// or content that does not match user expectations.
///
/// ## Thread Safety
/// Uses `NSLock` to protect mutable state.
public final class AbandonDetector: ExceptionalSignalDetector, @unchecked Sendable {

    // MARK: - Configuration

    /// Maximum seconds on a screen before navigation away triggers abandon detection.
    public let abandonThresholdSeconds: TimeInterval

    /// Minimum number of non-navigate interactions required to consider
    /// the visit "meaningful" (i.e., not an abandon).
    public let minimumInteractions: Int

    // MARK: - Internal Tracking

    private struct ScreenVisit {
        let navigateEvent: InteractionEvent
        var interactionCount: Int = 0
    }

    // MARK: - State

    private let lock = NSLock()
    private var currentVisit: ScreenVisit?
    private var detectedAbandons: [ExceptionalSignal] = []

    // MARK: - Protocol Conformance

    public var signalType: SignalType { .abandon }

    // MARK: - Init

    /// - Parameters:
    ///   - abandonThresholdSeconds: Max visit duration to count as abandon. Default is 3.0.
    ///   - minimumInteractions: Min interactions for a "meaningful" visit. Default is 1.
    public init(
        abandonThresholdSeconds: TimeInterval = 3.0,
        minimumInteractions: Int = 1
    ) {
        self.abandonThresholdSeconds = abandonThresholdSeconds
        self.minimumInteractions = minimumInteractions
    }

    // MARK: - Feed

    public func feed(_ event: InteractionEvent) {
        lock.lock()
        defer { lock.unlock() }

        if event.type == .navigate {
            // Check if the previous screen visit qualifies as an abandon.
            if let visit = currentVisit {
                let duration = event.timestamp.timeIntervalSince(visit.navigateEvent.timestamp)
                if duration <= abandonThresholdSeconds
                    && duration >= 0
                    && visit.interactionCount < minimumInteractions
                    && visit.navigateEvent.screen != event.screen
                {
                    let signal = ExceptionalSignal(
                        type: .abandon,
                        severity: .medium,
                        timestamp: event.timestamp,
                        screen: visit.navigateEvent.screen,
                        triggeringEvents: [visit.navigateEvent.id, event.id],
                        description: "User abandoned \(visit.navigateEvent.screen) after "
                            + String(format: "%.1f", duration) + "s with "
                            + "\(visit.interactionCount) interaction(s) "
                            + "(threshold: \(minimumInteractions))"
                    )
                    detectedAbandons.append(signal)
                }
            }

            // Start tracking the new screen.
            currentVisit = ScreenVisit(navigateEvent: event)
        } else {
            // Non-navigate event on the current screen increments the counter.
            if var visit = currentVisit, visit.navigateEvent.screen == event.screen {
                visit.interactionCount += 1
                currentVisit = visit
            }
        }
    }

    // MARK: - Detect

    public func detectSignals() -> [ExceptionalSignal] {
        lock.lock()
        let signals = detectedAbandons
        detectedAbandons.removeAll()
        lock.unlock()
        return signals
    }

    // MARK: - Reset

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        currentVisit = nil
        detectedAbandons.removeAll()
    }
}
