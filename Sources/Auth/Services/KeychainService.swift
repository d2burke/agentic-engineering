import Foundation
import Security

// MARK: - KeychainServiceProtocol

/// Protocol defining secure storage operations for sensitive data such as authentication tokens.
///
/// Conforming types provide a thin abstraction over the system keychain,
/// enabling both production use (via Security framework) and in-memory
/// test doubles without touching the real keychain.
public protocol KeychainServiceProtocol: Sendable {
    /// Persist raw data under the given key, overwriting any existing value.
    ///
    /// - Parameters:
    ///   - key: A unique identifier within the service namespace.
    ///   - data: The binary payload to store.
    /// - Throws: An `AppError.auth` if the Security framework rejects the operation.
    func save(key: String, data: Data) throws

    /// Retrieve previously stored data for the given key.
    ///
    /// - Parameter key: The identifier used during the original `save` call.
    /// - Returns: The stored data, or `nil` if no entry exists for the key.
    /// - Throws: An `AppError.auth` if the Security framework returns an unexpected error.
    func load(key: String) throws -> Data?

    /// Remove the entry for the given key from the keychain.
    ///
    /// No error is thrown if the key does not exist — the postcondition
    /// (key absent) is already satisfied.
    ///
    /// - Parameter key: The identifier to delete.
    /// - Throws: An `AppError.auth` if the Security framework rejects the operation.
    func delete(key: String) throws
}

// MARK: - KeychainService

/// Production keychain wrapper backed by the iOS/macOS Security framework.
///
/// All items are stored under the service identifier `com.taskmanager.auth`,
/// scoped to `kSecClassGenericPassword`.
public struct KeychainService: KeychainServiceProtocol {

    // MARK: - Constants

    private static let serviceIdentifier = "com.taskmanager.auth"
    private static let tokenKey = "auth_token"

    // MARK: - Initializer

    public init() {}

    // MARK: - KeychainServiceProtocol

    public func save(key: String, data: Data) throws {
        // Delete any existing item first to avoid errSecDuplicateItem.
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status: status)
        }
    }

    public func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unableToLoad(status: status)
        }
    }

    public func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceIdentifier,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status: status)
        }
    }

    // MARK: - Token Convenience

    /// Save an authentication token string to the keychain.
    ///
    /// - Parameter token: The bearer token received from the authentication API.
    /// - Throws: An error if the keychain operation fails.
    public func saveToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(key: Self.tokenKey, data: data)
    }

    /// Load the stored authentication token, if any.
    ///
    /// - Returns: The token string, or `nil` if no token is stored.
    public func loadToken() -> String? {
        guard let data = try? load(key: Self.tokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete the stored authentication token.
    ///
    /// - Throws: An error if the keychain operation fails.
    public func deleteToken() throws {
        try delete(key: Self.tokenKey)
    }
}

// MARK: - KeychainError

/// Errors specific to keychain operations.
public enum KeychainError: Error, Equatable, Sendable {
    case unableToSave(status: OSStatus)
    case unableToLoad(status: OSStatus)
    case unableToDelete(status: OSStatus)
    case encodingFailed

    public var localizedDescription: String {
        switch self {
        case .unableToSave(let status):
            return "Keychain save failed with status \(status)."
        case .unableToLoad(let status):
            return "Keychain load failed with status \(status)."
        case .unableToDelete(let status):
            return "Keychain delete failed with status \(status)."
        case .encodingFailed:
            return "Failed to encode the value for keychain storage."
        }
    }
}
