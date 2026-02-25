import Foundation

/// Represents a task within a project.
///
/// Conforms to `Codable` and `Sendable` for serialization and safe concurrency,
/// and `Identifiable` for SwiftUI list rendering and experimentation event tracking.
public struct TaskItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var taskDescription: String?
    public var status: TaskStatus
    public var priority: TaskPriority
    public var projectId: UUID
    public var assigneeId: UUID?
    public var reporterId: UUID
    public var tags: [String]
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var attachmentIds: [UUID]
    public var commentCount: Int

    public init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String? = nil,
        status: TaskStatus = .todo,
        priority: TaskPriority = .medium,
        projectId: UUID,
        assigneeId: UUID? = nil,
        reporterId: UUID,
        tags: [String] = [],
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        attachmentIds: [UUID] = [],
        commentCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.status = status
        self.priority = priority
        self.projectId = projectId
        self.assigneeId = assigneeId
        self.reporterId = reporterId
        self.tags = tags
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attachmentIds = attachmentIds
        self.commentCount = commentCount
    }
}
