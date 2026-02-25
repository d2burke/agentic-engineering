import Foundation

// MARK: - ExceptionalSignalDetector

/// A pluggable detector that analyzes a stream of `InteractionEvent`s and
/// produces `ExceptionalSignal`s when behavioral anomalies are identified.
///
/// Detectors are registered at runtime with the `InteractionTracker`, enabling
/// the experimentation agent to dynamically compose detection strategies
/// without recompilation. Each detector focuses on a single signal type
/// and maintains its own internal state.
///
/// ## Thread Safety
/// Conforming types must be `Sendable`. Implementations should use
/// appropriate synchronization (e.g., `NSLock`, serial `DispatchQueue`,
/// or actor isolation) to protect mutable state.
///
/// ## Lifecycle
/// 1. `feed(_:)` is called for every interaction event.
/// 2. `detectSignals()` is called after each event to check for new signals.
/// 3. `reset()` clears internal state (e.g., on screen transition or session end).
public protocol ExceptionalSignalDetector: Sendable {
    /// The type of signal this detector is responsible for identifying.
    var signalType: SignalType { get }

    /// Ingest a new interaction event into the detector's internal buffer.
    ///
    /// Implementations should store only the events relevant to their
    /// detection logic and discard others early.
    func feed(_ event: InteractionEvent)

    /// Scan the internal buffer and return any signals detected since
    /// the last call. Detected events should be consumed (removed from
    /// the buffer) to avoid duplicate signal emission.
    func detectSignals() -> [ExceptionalSignal]

    /// Clear all internal state, discarding any buffered events.
    func reset()
}
