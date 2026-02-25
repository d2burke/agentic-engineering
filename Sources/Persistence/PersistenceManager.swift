import Foundation
import Models

/// Protocol defining the contract for local data persistence.
///
/// Provides CRUD operations for caching API responses locally,
/// enabling offline-first behavior and optimistic UI updates.
public protocol PersistenceManagerProtocol: Sendable {
    /// Saves an array of `Codable` objects under the given key.
    func save<T: Codable & Sendable>(_ items: [T], forKey key: String) async throws

    /// Saves a single `Codable` object under the given key.
    func save<T: Codable & Sendable>(_ item: T, forKey key: String) async throws

    /// Loads an array of `Codable` objects from the given key.
    func load<T: Codable & Sendable>(forKey key: String) async throws -> [T]

    /// Loads a single `Codable` object from the given key.
    func loadOne<T: Codable & Sendable>(forKey key: String) async throws -> T?

    /// Removes the data stored under the given key.
    func remove(forKey key: String) async throws
}

/// Production implementation of `PersistenceManagerProtocol` using file-based storage.
public actor PersistenceManager: PersistenceManagerProtocol {
    private let directoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a new persistence manager.
    ///
    /// - Parameter directoryName: The subdirectory name within the app's documents folder.
    public init(directoryName: String = "TaskManagerCache") {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directoryURL = documentsURL.appendingPathComponent(directoryName)
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    public func save<T: Codable & Sendable>(_ items: [T], forKey key: String) async throws {
        let data = try encoder.encode(items)
        let fileURL = directoryURL.appendingPathComponent(key)
        try data.write(to: fileURL)
    }

    public func save<T: Codable & Sendable>(_ item: T, forKey key: String) async throws {
        let data = try encoder.encode(item)
        let fileURL = directoryURL.appendingPathComponent(key)
        try data.write(to: fileURL)
    }

    public func load<T: Codable & Sendable>(forKey key: String) async throws -> [T] {
        let fileURL = directoryURL.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([T].self, from: data)
    }

    public func loadOne<T: Codable & Sendable>(forKey key: String) async throws -> T? {
        let fileURL = directoryURL.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(T.self, from: data)
    }

    public func remove(forKey key: String) async throws {
        let fileURL = directoryURL.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
