import Foundation
import Models
import Common
import Networking

// MARK: - Auth Response Types

/// Server response for a successful login request.
public struct LoginResponse: Codable, Sendable {
    public let user: User
    public let token: String

    public init(user: User, token: String) {
        self.user = user
        self.token = token
    }
}

/// Server response for a successful sign-up request.
public struct SignUpResponse: Codable, Sendable {
    public let user: User
    public let token: String

    public init(user: User, token: String) {
        self.user = user
        self.token = token
    }
}

// MARK: - Endpoint

/// Represents an API endpoint with all the information needed to construct a URL request.
public struct Endpoint: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let body: Data?
    public let headers: [String: String]

    public init(
        path: String,
        method: HTTPMethod = .get,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.headers = headers
    }
}

// MARK: - APIClientProtocol

/// Protocol defining the contract for making network requests to the backend API.
///
/// Conforming types handle request construction, serialization, and
/// response deserialization. Feature modules depend only on this protocol,
/// allowing test doubles to replace real networking.
public protocol APIClientProtocol: Sendable {
    /// Execute an API request and decode the response into the specified type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint specification (path, method, body, headers).
    ///   - type: The expected response type to decode.
    /// - Returns: The decoded response object.
    /// - Throws: An `AppError` if the network request or decoding fails.
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T

    /// Set the authorization token for subsequent requests.
    ///
    /// - Parameter token: The bearer token, or `nil` to clear authorization.
    func setAuthToken(_ token: String?) async
}

// MARK: - AuthEndpoints

/// Factory for authentication-related API endpoints.
public enum AuthEndpoints {
    /// Login endpoint with email/password credentials.
    public static func login(email: String, password: String) -> Endpoint {
        let body = try? JSONEncoder().encode(["email": email, "password": password])
        return Endpoint(path: "/api/v1/auth/login", method: .post, body: body)
    }

    /// Sign-up endpoint with email, password, and display name.
    public static func signUp(email: String, password: String, displayName: String) -> Endpoint {
        let body = try? JSONEncoder().encode([
            "email": email,
            "password": password,
            "displayName": displayName,
        ])
        return Endpoint(path: "/api/v1/auth/signup", method: .post, body: body)
    }

    /// Logout endpoint (invalidates the current session server-side).
    public static func logout() -> Endpoint {
        Endpoint(path: "/api/v1/auth/logout", method: .post)
    }

    /// Endpoint to fetch the currently authenticated user's profile.
    public static func currentUser() -> Endpoint {
        Endpoint(path: "/api/v1/auth/me", method: .get)
    }
}

// MARK: - UserEndpoints

/// Factory for user-related API endpoints.
public enum UserEndpoints {
    /// Fetch the current user's profile.
    public static func me() -> Endpoint {
        Endpoint(path: "/api/v1/users/me", method: .get)
    }

    /// Update the current user's profile.
    public static func updateProfile(displayName: String?, avatarURL: URL?) -> Endpoint {
        var params: [String: String] = [:]
        if let displayName { params["displayName"] = displayName }
        if let avatarURL { params["avatarURL"] = avatarURL.absoluteString }
        let body = try? JSONEncoder().encode(params)
        return Endpoint(path: "/api/v1/users/me", method: .put, body: body)
    }

    /// Fetch a specific user by ID.
    public static func user(id: UUID) -> Endpoint {
        Endpoint(path: "/api/v1/users/\(id.uuidString)", method: .get)
    }
}

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
        let response = try await apiClient.request(endpoint, as: LoginResponse.self)

        try persistSession(token: response.token)
        await apiClient.setAuthToken(response.token)
        _currentUser = response.user

        AppLogger.info("Login successful for user \(response.user.id)", category: .auth)
        return response.user
    }

    public func signUp(email: String, password: String, displayName: String) async throws -> User {
        AppLogger.info("Attempting sign-up for \(email)", category: .auth)

        let endpoint = AuthEndpoints.signUp(email: email, password: password, displayName: displayName)
        let response = try await apiClient.request(endpoint, as: SignUpResponse.self)

        try persistSession(token: response.token)
        await apiClient.setAuthToken(response.token)
        _currentUser = response.user

        AppLogger.info("Sign-up successful for user \(response.user.id)", category: .auth)
        return response.user
    }

    public func logout() async throws {
        AppLogger.info("Logging out current user", category: .auth)

        let endpoint = AuthEndpoints.logout()
        _ = try? await apiClient.request(endpoint, as: EmptyResponse.self)

        clearSession()
        await apiClient.setAuthToken(nil)
        _currentUser = nil

        AppLogger.info("Logout complete", category: .auth)
    }

    /// Attempt to restore a previous session from the keychain.
    ///
    /// If a valid token is found, it sets the auth header and fetches
    /// the current user profile from the server.
    public func restoreSession() async {
        guard let token = loadPersistedToken() else {
            AppLogger.debug("No persisted token found", category: .auth)
            return
        }

        await apiClient.setAuthToken(token)

        do {
            let endpoint = AuthEndpoints.currentUser()
            let user = try await apiClient.request(endpoint, as: User.self)
            _currentUser = user
            AppLogger.info("Session restored for user \(user.id)", category: .auth)
        } catch {
            AppLogger.warning("Failed to restore session: \(error.localizedDescription)", category: .auth)
            clearSession()
            await apiClient.setAuthToken(nil)
        }
    }

    // MARK: - Private Helpers

    private func persistSession(token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw AppError.auth("Failed to encode token.")
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

// MARK: - EmptyResponse

/// A decodable type for API responses that carry no meaningful payload.
struct EmptyResponse: Decodable, Sendable {}
