import Foundation

/// Protocol for tracking user interactions across the application.
/// Conformers record events, manage signal detectors, and feed
/// data into the experimentation pipeline.
public protocol InteractionTracking: AnyObject, Sendable {
    /// Records an interaction event.
    func track(_ event: InteractionEvent)

    /// Registers a detector for identifying exceptional interaction patterns.
    func register(detector: any ExceptionalSignalDetector)

    /// All registered exceptional signal detectors.
    var registeredDetectors: [any ExceptionalSignalDetector] { get }
}
