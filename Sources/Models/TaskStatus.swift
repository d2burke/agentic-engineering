import Foundation

/// Represents the lifecycle status of a task.
///
/// Conforms to `CaseIterable` for iteration in filter pickers,
/// `Identifiable` for SwiftUI list usage, and `Codable`/`Sendable`
/// for serialization and concurrency safety.
public enum TaskStatus: String, Codable, Sendable, CaseIterable, Identifiable, Equatable, Hashable {
    case todo
    case inProgress
    case inReview
    case done
    case archived

    public var id: String { rawValue }

    /// A human-readable label for display in the UI.
    public var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        case .done: return "Done"
        case .archived: return "Archived"
        }
    }

    /// Numeric sort order reflecting the natural workflow progression.
    public var sortOrder: Int {
        switch self {
        case .todo: return 0
        case .inProgress: return 1
        case .inReview: return 2
        case .done: return 3
        case .archived: return 4
        }
    }
}
