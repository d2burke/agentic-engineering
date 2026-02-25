import Foundation
import Common

/// Protocol defining a generic persistence layer for storing and retrieving
/// `Codable` and `Identifiable` entities by their unique identifier.
///
/// Implementations must be `Sendable` to allow safe usage from concurrent
/// async tasks and actors. The persistence layer is entity-type-agnostic:
/// any conforming type can be stored and retrieved using its unique identifier.
///
/// This protocol complements `PersistenceManagerProtocol` (key-value based)
/// by providing identity-based CRUD operations suitable for domain entities.
public protocol EntityPersistence: Sendable {
    /// Saves an entity to the persistent store.
    ///
    /// If an entity with the same identifier already exists, it is overwritten.
    ///
    /// - Parameter item: The entity to save.
    /// - Throws: An error if encoding or storage fails.
    func save<T: Codable & Identifiable>(_ item: T) async throws where T.ID == UUID

    /// Fetches a single entity by its unique identifier.
    ///
    /// - Parameters:
    ///   - type: The expected entity type.
    ///   - id: The entity's unique identifier.
    /// - Returns: The entity if found, or `nil` if no entity with that identifier exists.
    /// - Throws: An error if decoding fails.
    func fetch<T: Codable & Identifiable>(_ type: T.Type, id: UUID) async throws -> T? where T.ID == UUID

    /// Fetches all entities of the given type from the persistent store.
    ///
    /// - Parameter type: The entity type to fetch.
    /// - Returns: An array of all stored entities of the given type.
    /// - Throws: An error if decoding fails.
    func fetchAll<T: Codable & Identifiable>(_ type: T.Type) async throws -> [T] where T.ID == UUID

    /// Deletes a single entity by its unique identifier.
    ///
    /// If no entity with the given identifier exists, this method completes
    /// without error (idempotent delete).
    ///
    /// - Parameters:
    ///   - type: The entity type.
    ///   - id: The entity's unique identifier.
    /// - Throws: An error if the deletion fails.
    func delete<T: Codable & Identifiable>(_ type: T.Type, id: UUID) async throws where T.ID == UUID
}

/// In-memory implementation of `EntityPersistence` for testing, previews,
/// and lightweight caching scenarios.
///
/// Data is stored as JSON-encoded `Data` blobs in a nested dictionary keyed
/// by type name and entity identifier. All data is lost when the actor is
/// deallocated.
public actor InMemoryPersistenceManager: EntityPersistence {
    /// Backing store: [TypeName: [EntityID: EncodedData]]
    private var store: [String: [String: Data]] = [:]

    /// JSON encoder used for serializing entities.
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// JSON decoder used for deserializing entities.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Creates a new empty in-memory persistence manager.
    public init() {}

    public func save<T: Codable & Identifiable>(_ item: T) async throws where T.ID == UUID {
        let typeName = String(describing: T.self)
        let idString = item.id.uuidString

        do {
            let data = try encoder.encode(item)
            if store[typeName] == nil {
                store[typeName] = [:]
            }
            store[typeName]?[idString] = data
            AppLogger.debug("Saved \(typeName) with id \(idString)", category: .persistence)
        } catch {
            AppLogger.error("Failed to encode \(typeName): \(error.localizedDescription)", category: .persistence)
            throw AppError.persistence("Failed to encode \(typeName): \(error.localizedDescription)")
        }
    }

    public func fetch<T: Codable & Identifiable>(_ type: T.Type, id: UUID) async throws -> T? where T.ID == UUID {
        let typeName = String(describing: T.self)
        let idString = id.uuidString

        guard let data = store[typeName]?[idString] else {
            AppLogger.debug("No \(typeName) found with id \(idString)", category: .persistence)
            return nil
        }

        do {
            let item = try decoder.decode(T.self, from: data)
            return item
        } catch {
            AppLogger.error("Failed to decode \(typeName): \(error.localizedDescription)", category: .persistence)
            throw AppError.persistence("Failed to decode \(typeName): \(error.localizedDescription)")
        }
    }

    public func fetchAll<T: Codable & Identifiable>(_ type: T.Type) async throws -> [T] where T.ID == UUID {
        let typeName = String(describing: T.self)

        guard let entries = store[typeName] else {
            return []
        }

        var results: [T] = []
        for (idString, data) in entries {
            do {
                let item = try decoder.decode(T.self, from: data)
                results.append(item)
            } catch {
                AppLogger.error(
                    "Failed to decode \(typeName) with id \(idString): \(error.localizedDescription)",
                    category: .persistence
                )
                throw AppError.persistence("Failed to decode \(typeName): \(error.localizedDescription)")
            }
        }

        return results
    }

    public func delete<T: Codable & Identifiable>(_ type: T.Type, id: UUID) async throws where T.ID == UUID {
        let typeName = String(describing: T.self)
        let idString = id.uuidString

        store[typeName]?.removeValue(forKey: idString)

        // Clean up empty type dictionaries
        if store[typeName]?.isEmpty == true {
            store.removeValue(forKey: typeName)
        }

        AppLogger.debug("Deleted \(typeName) with id \(idString)", category: .persistence)
    }
}
