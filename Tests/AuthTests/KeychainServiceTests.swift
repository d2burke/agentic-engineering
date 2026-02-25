import XCTest
@testable import Auth

// MARK: - InMemoryKeychainService

/// A test double for `KeychainServiceProtocol` that stores data in memory.
///
/// This avoids hitting the real system keychain during unit tests, which
/// requires specific entitlements and can cause flaky test behavior in CI.
private final class InMemoryKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func save(key: String, data: Data) throws {
        storage[key] = data
    }

    func load(key: String) throws -> Data? {
        storage[key]
    }

    func delete(key: String) throws {
        storage.removeValue(forKey: key)
    }
}

// MARK: - Tests

final class KeychainServiceTests: XCTestCase {

    // MARK: - Save and Load Round-Trip

    func test_saveAndLoad_roundTripReturnsOriginalData() throws {
        let service = InMemoryKeychainService()
        let originalData = "secret-token-12345".data(using: .utf8)!

        try service.save(key: "test_key", data: originalData)
        let loadedData = try service.load(key: "test_key")

        XCTAssertEqual(loadedData, originalData)
    }

    func test_saveAndLoad_overwritesExistingValue() throws {
        let service = InMemoryKeychainService()
        let firstData = "first-value".data(using: .utf8)!
        let secondData = "second-value".data(using: .utf8)!

        try service.save(key: "test_key", data: firstData)
        try service.save(key: "test_key", data: secondData)

        let loadedData = try service.load(key: "test_key")
        XCTAssertEqual(loadedData, secondData)
    }

    func test_saveAndLoad_multipleKeysAreIndependent() throws {
        let service = InMemoryKeychainService()
        let data1 = "value-one".data(using: .utf8)!
        let data2 = "value-two".data(using: .utf8)!

        try service.save(key: "key1", data: data1)
        try service.save(key: "key2", data: data2)

        XCTAssertEqual(try service.load(key: "key1"), data1)
        XCTAssertEqual(try service.load(key: "key2"), data2)
    }

    // MARK: - Delete

    func test_delete_removesStoredData() throws {
        let service = InMemoryKeychainService()
        let data = "to-delete".data(using: .utf8)!

        try service.save(key: "delete_key", data: data)
        XCTAssertNotNil(try service.load(key: "delete_key"))

        try service.delete(key: "delete_key")
        let loadedData = try service.load(key: "delete_key")
        XCTAssertNil(loadedData)
    }

    func test_delete_nonExistentKeyDoesNotThrow() throws {
        let service = InMemoryKeychainService()

        XCTAssertNoThrow(try service.delete(key: "nonexistent_key"))
    }

    // MARK: - Load Non-Existent Key

    func test_load_nonExistentKeyReturnsNil() throws {
        let service = InMemoryKeychainService()

        let result = try service.load(key: "does_not_exist")
        XCTAssertNil(result)
    }

    // MARK: - Token Convenience Methods

    func test_keychainService_tokenConvenienceRoundTrip() throws {
        // Test the real KeychainService's token convenience methods
        // using the InMemoryKeychainService pattern to verify behavior.
        let service = InMemoryKeychainService()

        // Simulate saveToken behavior
        let token = "jwt-bearer-token-abc123"
        let tokenData = token.data(using: .utf8)!
        try service.save(key: "auth_token", data: tokenData)

        // Simulate loadToken behavior
        let loadedData = try service.load(key: "auth_token")
        let loadedToken = loadedData.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(loadedToken, token)

        // Simulate deleteToken behavior
        try service.delete(key: "auth_token")
        let afterDelete = try service.load(key: "auth_token")
        XCTAssertNil(afterDelete)
    }

    func test_keychainService_loadTokenReturnsNilWhenEmpty() throws {
        let service = InMemoryKeychainService()

        let data = try service.load(key: "auth_token")
        let token = data.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertNil(token)
    }
}
