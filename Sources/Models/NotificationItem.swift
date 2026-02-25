import Foundation

/// An in-app notification delivered to a user.
///
/// Conforms to `Codable` and `Sendable` for serialization and safe concurrency,
/// and `Identifiable` for SwiftUI list rendering and experimentation tracking.
public struct NotificationItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let type: NotificationType
    public let title: String
    public let body: String
    public let relatedTaskId: UUID?
    public let relatedProjectId: UUID?
    public var isRead: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        userId: UUID,
        type: NotificationType,
        title: String,
        body: String,
        relatedTaskId: UUID? = nil,
        relatedProjectId: UUID? = nil,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.relatedTaskId = relatedTaskId
        self.relatedProjectId = relatedProjectId
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

/// The kind of notification event.
public enum NotificationType: String, Codable, Sendable, CaseIterable, Identifiable, Equatable, Hashable {
    case taskAssigned = "task_assigned"
    case taskUpdated = "task_updated"
    case commentAdded = "comment_added"
    case mentioned = "mentioned"
    case projectInvite = "project_invite"

    public var id: String { rawValue }

    /// A human-readable label for the notification type.
    public var displayName: String {
        switch self {
        case .taskAssigned: return "Task Assigned"
        case .taskUpdated: return "Task Updated"
        case .commentAdded: return "Comment Added"
        case .mentioned: return "Mentioned"
        case .projectInvite: return "Project Invite"
        }
    }
}
