import Foundation

/// Represents a project that contains tasks and members.
///
/// Conforms to `Codable` and `Sendable` for serialization and safe concurrency,
/// and `Identifiable` for SwiftUI integration and experimentation tracking.
public struct Project: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var projectDescription: String?
    public var ownerId: UUID
    public var memberIds: [UUID]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        projectDescription: String? = nil,
        ownerId: UUID,
        memberIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
