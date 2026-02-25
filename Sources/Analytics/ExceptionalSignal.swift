import Foundation

// MARK: - SignalType

/// Categorizes the kind of exceptional behavioral signal detected.
///
/// Each signal type maps to a specific user frustration or UX anomaly
/// that the experimentation pipeline can act upon.
public enum SignalType: String, Codable, Sendable, CaseIterable {
    /// Multiple rapid taps in the same region, indicating frustration.
    case rageTap

    /// A tap that produced no observable response or navigation.
    case deadTap

    /// A burst of error events in a short time window.
    case errorBurst

    /// User navigated to a screen and left without meaningful interaction.
    case abandon

    /// An unusually long press suggesting confusion or frustration.
    case longPressFrustration

    /// Excessive scrolling without settling, indicating content findability issues.
    case excessiveScroll

    /// A latency spike detected between interaction and response.
    case latencySpike
}

// MARK: - Severity

/// The severity level of a detected signal, used to prioritize
/// alerting and experimentation responses.
public enum Severity: String, Codable, Sendable, Comparable, CaseIterable {
    case low
    case medium
    case high
    case critical

    private var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - ExceptionalSignal

/// Represents a detected behavioral anomaly derived from one or more
/// `InteractionEvent`s. This is the primary data feed for the
/// experimentation pipeline.
///
/// Each signal includes the IDs of the triggering events so the
/// experimentation agent can trace back to the raw interaction data
/// and perform deeper analysis.
public struct ExceptionalSignal: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this signal.
    public let id: UUID

    /// The category of behavioral anomaly detected.
    public let type: SignalType

    /// How severe this signal is — drives prioritization in the experimentation pipeline.
    public let severity: Severity

    /// When this signal was generated.
    public let timestamp: Date

    /// The screen where the signal was detected.
    public let screen: String

    /// IDs of the `InteractionEvent`s that contributed to this signal.
    public let triggeringEvents: [UUID]

    /// Optional correlation ID for grouping related signals across a user session.
    public let correlationId: String?

    /// A human-readable description of what was detected.
    public let description: String

    public init(
        id: UUID = UUID(),
        type: SignalType,
        severity: Severity,
        timestamp: Date = Date(),
        screen: String,
        triggeringEvents: [UUID],
        correlationId: String? = nil,
        description: String
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.timestamp = timestamp
        self.screen = screen
        self.triggeringEvents = triggeringEvents
        self.correlationId = correlationId
        self.description = description
    }
}
