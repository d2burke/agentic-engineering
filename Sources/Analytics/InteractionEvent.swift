import Foundation
import CoreGraphics

// MARK: - InteractionType

/// Categorizes the kind of user interaction captured by the analytics system.
///
/// Each case carries semantic meaning used by signal detectors to identify
/// behavioral patterns (e.g., rapid `.tap` events in the same region indicate rage taps).
public enum InteractionType: String, Codable, Sendable, CaseIterable {
    case tap
    case scroll
    case navigate
    case error
    case longPress
    case drag
    case swipe
}

// MARK: - CodableCGPoint

/// A Codable wrapper for CGPoint, encoding the x/y coordinates as Doubles.
private struct CodableCGPoint: Codable, Sendable {
    let x: Double
    let y: Double

    init(_ point: CGPoint) {
        self.x = Double(point.x)
        self.y = Double(point.y)
    }

    var cgPoint: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

// MARK: - InteractionEvent

/// A single user interaction captured by the analytics system.
///
/// Events carry rich metadata — screen name, tap coordinates, timing, and
/// arbitrary key-value pairs — so that downstream signal detectors have
/// enough context to identify behavioral patterns without additional lookups.
public struct InteractionEvent: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this event.
    public let id: UUID

    /// The type of interaction captured.
    public let type: InteractionType

    /// When the interaction occurred.
    public let timestamp: Date

    /// The screen or view where the interaction took place.
    public let screen: String

    /// The tap/gesture location, if applicable (screen coordinates).
    public let point: CGPoint?

    /// Arbitrary key-value metadata providing additional context
    /// (e.g., element identifiers, accessibility labels, view hierarchy info).
    public let metadata: [String: String]

    /// Duration of the interaction in seconds (e.g., for long press or drag).
    public let duration: TimeInterval?

    public init(
        id: UUID = UUID(),
        type: InteractionType,
        timestamp: Date = Date(),
        screen: String,
        point: CGPoint? = nil,
        metadata: [String: String] = [:],
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.screen = screen
        self.point = point
        self.metadata = metadata
        self.duration = duration
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, type, timestamp, screen, point, metadata, duration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(InteractionType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        screen = try container.decode(String.self, forKey: .screen)
        metadata = try container.decode([String: String].self, forKey: .metadata)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)

        if let codablePoint = try container.decodeIfPresent(CodableCGPoint.self, forKey: .point) {
            point = codablePoint.cgPoint
        } else {
            point = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(screen, forKey: .screen)
        try container.encode(metadata, forKey: .metadata)
        try container.encodeIfPresent(duration, forKey: .duration)

        if let point = point {
            try container.encode(CodableCGPoint(point), forKey: .point)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: InteractionEvent, rhs: InteractionEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.timestamp == rhs.timestamp
            && lhs.screen == rhs.screen
            && lhs.point == rhs.point
            && lhs.metadata == rhs.metadata
            && lhs.duration == rhs.duration
    }
}
