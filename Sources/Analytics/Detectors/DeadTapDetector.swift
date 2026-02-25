import Foundation

// MARK: - DeadTapDetector

/// Detects taps that receive no corresponding navigation or state-change
/// event within a configurable response window.
///
/// A "dead tap" suggests that a UI element looks tappable but is not —
/// a common source of user confusion and frustration.
///
/// ## Detection Logic
/// 1. Each `.tap` event is stored with its timestamp.
/// 2. When a `.navigate` event arrives, any pending tap on the same screen
///    within the response window is considered "answered" and removed.
/// 3. On `detectSignals()`, any tap whose response window has elapsed
///    without a matching navigate is reported as a dead tap.
///
/// ## Thread Safety
/// Uses `NSLock` to protect mutable state.
public final class DeadTapDetector: ExceptionalSignalDetector, @unchecked Sendable {

    // MARK: - Configuration

    /// Time window (in seconds) to wait for a response after a tap.
    public let responseWindowMs: TimeInterval

    // MARK: - State

    private let lock = NSLock()
    private var pendingTaps: [InteractionEvent] = []

    // MARK: - Protocol Conformance

    public var signalType: SignalType { .deadTap }

    // MARK: - Init

    /// - Parameter responseWindowMs: Seconds to wait for a navigate/state-change
    ///   event after a tap. Default is 0.3 (300ms).
    public init(responseWindowMs: TimeInterval = 0.3) {
        self.responseWindowMs = responseWindowMs
    }

    // MARK: - Feed

    public func feed(_ event: InteractionEvent) {
        lock.lock()
        defer { lock.unlock() }

        switch event.type {
        case .tap:
            pendingTaps.append(event)

        case .navigate:
            // A navigate event "answers" any pending tap on the same screen
            // that occurred within the response window.
            pendingTaps.removeAll { tap in
                tap.screen == event.screen
                    && event.timestamp.timeIntervalSince(tap.timestamp) <= responseWindowMs
                    && event.timestamp.timeIntervalSince(tap.timestamp) >= 0
            }

        default:
            break
        }
    }

    // MARK: - Detect

    public func detectSignals() -> [ExceptionalSignal] {
        lock.lock()
        let snapshot = pendingTaps
        lock.unlock()

        let now = Date()
        var signals: [ExceptionalSignal] = []
        var expiredIds: Set<UUID> = []

        for tap in snapshot {
            let elapsed = now.timeIntervalSince(tap.timestamp)
            if elapsed > responseWindowMs {
                expiredIds.insert(tap.id)
                let signal = ExceptionalSignal(
                    type: .deadTap,
                    severity: .low,
                    timestamp: now,
                    screen: tap.screen,
                    triggeringEvents: [tap.id],
                    description: "Tap on \(tap.screen) received no response within "
                        + "\(Int(responseWindowMs * 1000))ms"
                )
                signals.append(signal)
            }
        }

        if !expiredIds.isEmpty {
            lock.lock()
            pendingTaps.removeAll { expiredIds.contains($0.id) }
            lock.unlock()
        }

        return signals
    }

    // MARK: - Reset

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        pendingTaps.removeAll()
    }
}
