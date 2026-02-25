import Foundation
import Models
import Common
import Networking

// MARK: - AuthServiceProtocol

/// Protocol defining authentication operations.
///
/// Conforming types manage the full authentication lifecycle: login, sign-up,
/// session persistence (via tokens), and logout. The protocol is `Sendable`
/// so it can be safely shared across concurrency domains.
public protocol AuthServiceProtocol: Sendable {
    /// Authenticate a user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: The authenticated `User`.
    /// - Throws: An `AppError` on network failure, invalid credentials, or decoding error.
    func login(email: String, password: String) async throws -> User

    /// Register a new user account.
    ///
    /// - Parameters:
    ///   - email: The desired email address.
    ///   - password: The desired password.
    ///   - displayName: The user's display name.
    /// - Returns: The newly created `User`.
    /// - Throws: An `AppError` on network failure or validation error.
    func signUp(email: String, password: String, displayName: String) async throws -> User

    /// Sign out the current user and invalidate the session.
    ///
    /// - Throws: An `AppError` if the server-side logout fails.
    func logout() async throws

    /// The currently authenticated user, or `nil` if not authenticated.
    var currentUser: User? { get async }

    /// Whether a user is currently authenticated (i.e., has a valid session token).
    var isAuthenticated: Bool { get async }
}

// MARK: - AuthService

/// Actor-isolated authentication service that coordinates API calls,
/// token persistence via keychain, and in-memory user session state.
///
/// ## Design
/// - **Actor isolation** ensures all mutable state (`_currentUser`) is
///   accessed safely without external locking.
/// - **Keychain storage** persists the auth token across app launches.
/// - **API client token** is set after login/signup so that all subsequent
///   requests carry the Bearer header automatically.
public actor AuthService: AuthServiceProtocol {

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol
    private let keychainService: KeychainServiceProtocol

    // MARK: - State

    private var _currentUser: User?

    // MARK: - Initializer

    /// Creates an `AuthService` with the given dependencies.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for making network requests.
    ///   - keychainService: The keychain service for persisting auth tokens.
    public init(apiClient: APIClientProtocol, keychainService: KeychainServiceProtocol) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    // MARK: - AuthServiceProtocol

    public var currentUser: User? {
        _currentUser
    }

    public var isAuthenticated: Bool {
        _currentUser != nil
    }

    public func login(email: String, password: String) async throws -> User {
        AppLogger.info("Attempting login for \(email)", category: .auth)

        let endpoint = AuthEndpoints.login(email: email, password: password)
        let response: LoginResponse = try await apiClient.request(endpoint)

        try persistToken(response.token)
        await apiClient.setAuthToken(response.token)
        _currentUser = response.user

        AppLogger.info("Login successful for user \(response.user.id)", category: .auth)
        return response.user
    }

    public func signUp(email: String, password: String, displayName: String) async throws -> User {
        AppLogger.info("Attempting sign-up for \(email)", category: .auth)

        let endpoint = AuthEndpoints.signUp(email: email, password: password, displayName: displayName)
        let response: SignUpResponse = try await apiClient.request(endpoint)

        try persistToken(response.token)
        await apiClient.setAuthToken(response.token)
        _currentUser = response.user

        AppLogger.info("Sign-up successful for user \(response.user.id)", category: .auth)
        return response.user
    }

    public func logout() async throws {
        AppLogger.info("Logging out current user", category: .auth)

        // Attempt server-side logout; ignore errors since we clear locally regardless.
        do {
            try await apiClient.request(AuthEndpoints.logout)
        } catch {
            AppLogger.warning("Server-side logout failed: \(error.localizedDescription)", category: .auth)
        }

        clearSession()
        await apiClient.setAuthToken(nil)
        _currentUser = nil

        AppLogger.info("Logout complete", category: .auth)
    }

    /// Attempt to restore a previous session from the keychain.
    ///
    /// If a valid token is found, it sets the auth header on the API client
    /// and fetches the current user profile from the server.
    public func restoreSession() async {
        guard let token = loadPersistedToken() else {
            AppLogger.debug("No persisted token found", category: .auth)
            return
        }

        await apiClient.setAuthToken(token)

        do {
            let user: User = try await apiClient.request(UserEndpoints.me)
            _currentUser = user
            AppLogger.info("Session restored for user \(user.id)", category: .auth)
        } catch {
            AppLogger.warning("Failed to restore session: \(error.localizedDescription)", category: .auth)
            clearSession()
            await apiClient.setAuthToken(nil)
        }
    }

    // MARK: - Private Helpers

    private func persistToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw AppError.auth("Failed to encode token for keychain storage.")
        }
        try keychainService.save(key: "auth_token", data: data)
    }

    private func loadPersistedToken() -> String? {
        guard let data = try? keychainService.load(key: "auth_token") else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func clearSession() {
        try? keychainService.delete(key: "auth_token")
    }
}
