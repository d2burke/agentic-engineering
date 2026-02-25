import Foundation
import Models
import Common
import Networking

// MARK: - UserRepositoryProtocol

/// Protocol defining user data access operations.
///
/// Conforming types abstract over the networking layer, providing a
/// clean data-access boundary for the Profile feature module. Implementations
/// must be `Sendable` for safe usage from async contexts.
public protocol UserRepositoryProtocol: Sendable {
    /// Fetch the currently authenticated user's profile.
    ///
    /// - Returns: The current `User`.
    /// - Throws: An error if the network request or decoding fails.
    func fetchCurrentUser() async throws -> User

    /// Update the current user's profile fields.
    ///
    /// - Parameters:
    ///   - displayName: The updated display name, or `nil` to leave unchanged.
    ///   - avatarURL: The updated avatar URL, or `nil` to leave unchanged.
    /// - Returns: The updated `User` as returned by the server.
    /// - Throws: An error if the network request or decoding fails.
    func updateProfile(displayName: String?, avatarURL: URL?) async throws -> User

    /// Fetch a specific user by their unique identifier.
    ///
    /// - Parameter id: The UUID of the user to fetch.
    /// - Returns: The requested `User`.
    /// - Throws: An error if the user is not found or the network request fails.
    func fetchUser(id: UUID) async throws -> User
}

// MARK: - UserRepository

/// Production user repository backed by the API client.
///
/// Translates high-level profile operations into API endpoint calls
/// via `APIClientProtocol`, keeping the networking layer decoupled
/// from view model logic.
public struct UserRepository: UserRepositoryProtocol {

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    // MARK: - Initializer

    /// Creates a `UserRepository` with the given API client.
    ///
    /// - Parameter apiClient: The API client for making network requests.
    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - UserRepositoryProtocol

    public func fetchCurrentUser() async throws -> User {
        AppLogger.debug("Fetching current user profile", category: .network)
        let user: User = try await apiClient.request(UserEndpoints.me)
        AppLogger.info("Fetched profile for user \(user.id)", category: .network)
        return user
    }

    public func updateProfile(displayName: String?, avatarURL: URL?) async throws -> User {
        AppLogger.debug("Updating user profile", category: .network)
        let endpoint = UserEndpoints.updateProfile(displayName: displayName, avatarURL: avatarURL)
        let user: User = try await apiClient.request(endpoint)
        AppLogger.info("Updated profile for user \(user.id)", category: .network)
        return user
    }

    public func fetchUser(id: UUID) async throws -> User {
        AppLogger.debug("Fetching user \(id)", category: .network)
        let endpoint = UserEndpoints.get(id: id)
        let user: User = try await apiClient.request(endpoint)
        AppLogger.info("Fetched user \(user.id)", category: .network)
        return user
    }
}
