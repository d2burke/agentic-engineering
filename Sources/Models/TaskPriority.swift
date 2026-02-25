import Foundation

/// Represents the priority level of a task, from low to critical.
///
/// Conforms to `CaseIterable` for iteration in filter pickers,
/// `Identifiable` for SwiftUI list usage, `Comparable` for sorting,
/// and `Codable`/`Sendable` for serialization and concurrency safety.
public enum TaskPriority: String, Codable, Sendable, CaseIterable, Comparable, Identifiable, Equatable, Hashable {
    case low
    case medium
    case high
    case critical

    public var id: String { rawValue }

    /// A human-readable label for display in the UI.
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    /// The SF Symbol name representing this priority level.
    public var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    /// Numeric sort order from lowest to highest urgency.
    public var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        let order: [TaskPriority] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
