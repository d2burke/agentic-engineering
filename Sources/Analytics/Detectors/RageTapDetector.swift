import Foundation
import CoreGraphics

// MARK: - RageTapDetector

/// Detects rapid, repeated taps in the same screen region — a strong
/// indicator of user frustration ("rage tapping").
///
/// A rage tap is identified when `tapThreshold` or more `.tap` events
/// occur within `windowSeconds` and all fall within a circle of
/// `regionRadius` points from each other.
///
/// ## Thread Safety
/// Uses `NSLock` to protect the mutable event buffer, making this class
/// safe for concurrent `feed` / `detectSignals` calls from different
/// isolation domains.
public final class RageTapDetector: ExceptionalSignalDetector, @unchecked Sendable {

    // MARK: - Configuration

    /// Minimum number of taps to trigger a rage tap signal.
    public let tapThreshold: Int

    /// Time window (in seconds) within which taps must occur.
    public let windowSeconds: TimeInterval

    /// Maximum radius (in points) defining "same region".
    public let regionRadius: CGFloat

    // MARK: - State

    private let lock = NSLock()
    private var recentTaps: [InteractionEvent] = []

    // MARK: - Protocol Conformance

    public var signalType: SignalType { .rageTap }

    // MARK: - Init

    /// - Parameters:
    ///   - tapThreshold: Minimum tap count to trigger detection. Default is 3.
    ///   - windowSeconds: Time window in seconds. Default is 1.0.
    ///   - regionRadius: Spatial radius in points. Default is 44 (Apple's min tap target).
    public init(
        tapThreshold: Int = 3,
        windowSeconds: TimeInterval = 1.0,
        regionRadius: CGFloat = 44
    ) {
        self.tapThreshold = tapThreshold
        self.windowSeconds = windowSeconds
        self.regionRadius = regionRadius
    }

    // MARK: - Feed

    public func feed(_ event: InteractionEvent) {
        guard event.type == .tap else { return }

        lock.lock()
        defer { lock.unlock() }

        recentTaps.append(event)

        // Prune events outside the time window to keep memory bounded.
        let cutoff = event.timestamp.addingTimeInterval(-windowSeconds * 2)
        recentTaps.removeAll { $0.timestamp < cutoff }
    }

    // MARK: - Detect

    public func detectSignals() -> [ExceptionalSignal] {
        lock.lock()
        let snapshot = recentTaps
        lock.unlock()

        guard snapshot.count >= tapThreshold else { return [] }

        var signals: [ExceptionalSignal] = []
        var consumedIds: Set<UUID> = []

        // Scan for clusters: for each tap, look forward within the time
        // window for nearby taps that form a cluster >= threshold.
        for i in 0..<snapshot.count {
            let anchor = snapshot[i]
            guard !consumedIds.contains(anchor.id) else { continue }
            guard let anchorPoint = anchor.point else { continue }

            var cluster: [InteractionEvent] = [anchor]

            for j in (i + 1)..<snapshot.count {
                let candidate = snapshot[j]
                guard !consumedIds.contains(candidate.id) else { continue }

                let timeDelta = candidate.timestamp.timeIntervalSince(anchor.timestamp)
                guard timeDelta >= 0, timeDelta <= windowSeconds else { continue }

                guard let candidatePoint = candidate.point else { continue }

                let distance = hypot(
                    candidatePoint.x - anchorPoint.x,
                    candidatePoint.y - anchorPoint.y
                )
                if distance <= regionRadius {
                    cluster.append(candidate)
                }
            }

            if cluster.count >= tapThreshold {
                let eventIds = cluster.map(\.id)
                consumedIds.formUnion(eventIds)

                let signal = ExceptionalSignal(
                    type: .rageTap,
                    severity: cluster.count >= tapThreshold * 2 ? .high : .medium,
                    timestamp: Date(),
                    screen: anchor.screen,
                    triggeringEvents: eventIds,
                    description: "\(cluster.count) rapid taps detected within "
                        + "\(windowSeconds)s in a \(regionRadius)pt region on \(anchor.screen)"
                )
                signals.append(signal)
            }
        }

        // Remove consumed events from the buffer to prevent duplicate signals.
        if !consumedIds.isEmpty {
            lock.lock()
            recentTaps.removeAll { consumedIds.contains($0.id) }
            lock.unlock()
        }

        return signals
    }

    // MARK: - Reset

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        recentTaps.removeAll()
    }
}
