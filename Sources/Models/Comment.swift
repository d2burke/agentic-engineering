import Foundation

/// A comment attached to a task, supporting team discussion threads.
///
/// Conforms to `Codable` and `Sendable` for serialization and safe concurrency,
/// and `Identifiable` for SwiftUI list rendering and analytics event correlation.
public struct Comment: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let taskId: UUID
    public let authorId: UUID
    public var body: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        taskId: UUID,
        authorId: UUID,
        body: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.authorId = authorId
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
