import Foundation

/// The type of mutation an offline operation represents.
public enum OperationType: String, Codable, Sendable, Equatable {
    /// A new entity was created while offline.
    case create
    /// An existing entity was updated while offline.
    case update
    /// An entity was deleted while offline.
    case delete
}

/// Represents a pending mutation that was performed while the device was offline.
///
/// Offline operations are queued and replayed against the server when connectivity
/// is restored. Each operation tracks its retry count to prevent infinite retry loops.
public struct OfflineOperation: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this operation.
    public let id: UUID

    /// The type of mutation (create, update, or delete).
    public let type: OperationType

    /// The name of the entity type being mutated (e.g., "TaskItem", "Comment").
    public let entityType: String

    /// The identifier of the entity being mutated.
    public let entityId: UUID

    /// The JSON-encoded payload for the mutation, if applicable.
    /// For delete operations this may be `nil`.
    public let payload: Data?

    /// The date and time the operation was created.
    public let createdAt: Date

    /// The number of times this operation has been retried.
    public var retryCount: Int

    /// The maximum number of retry attempts before the operation is discarded.
    public let maxRetries: Int

    /// Creates a new offline operation.
    ///
    /// - Parameters:
    ///   - id: A unique identifier. Defaults to a new UUID.
    ///   - type: The mutation type.
    ///   - entityType: The entity type name.
    ///   - entityId: The entity identifier.
    ///   - payload: The optional encoded mutation payload.
    ///   - createdAt: The creation timestamp. Defaults to now.
    ///   - retryCount: The initial retry count. Defaults to 0.
    ///   - maxRetries: The maximum retries allowed. Defaults to 3.
    public init(
        id: UUID = UUID(),
        type: OperationType,
        entityType: String,
        entityId: UUID,
        payload: Data? = nil,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        maxRetries: Int = 3
    ) {
        self.id = id
        self.type = type
        self.entityType = entityType
        self.entityId = entityId
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.maxRetries = maxRetries
    }
}
