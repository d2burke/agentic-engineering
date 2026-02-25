import Foundation
import Models

/// Response returned by the login endpoint.
public struct LoginResponse: Codable, Sendable, Equatable {
    /// The JWT authentication token.
    public let token: String
    /// The authenticated user.
    public let user: User

    public init(token: String, user: User) {
        self.token = token
        self.user = user
    }
}

/// Response returned by the sign-up endpoint.
public struct SignUpResponse: Codable, Sendable, Equatable {
    /// The JWT authentication token for the newly created account.
    public let token: String
    /// The newly registered user.
    public let user: User

    public init(token: String, user: User) {
        self.token = token
        self.user = user
    }
}

/// Endpoints for authentication-related API operations.
public enum AuthEndpoints {
    /// Authenticates a user with email and password credentials.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: An endpoint configured for `POST /auth/login`.
    public static func login(email: String, password: String) -> Endpoint {
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        return Endpoint(
            path: "/auth/login",
            method: .post,
            body: try? JSONEncoder().encode(body)
        )
    }

    /// Registers a new user account.
    ///
    /// - Parameters:
    ///   - email: The desired email address.
    ///   - password: The desired password.
    ///   - displayName: The user's display name.
    /// - Returns: An endpoint configured for `POST /auth/signup`.
    public static func signUp(email: String, password: String, displayName: String) -> Endpoint {
        let body: [String: String] = [
            "email": email,
            "password": password,
            "display_name": displayName
        ]
        return Endpoint(
            path: "/auth/signup",
            method: .post,
            body: try? JSONEncoder().encode(body)
        )
    }

    /// Refreshes an expired authentication token.
    ///
    /// - Parameter token: The current refresh token.
    /// - Returns: An endpoint configured for `POST /auth/refresh`.
    public static func refreshToken(token: String) -> Endpoint {
        let body: [String: String] = [
            "refresh_token": token
        ]
        return Endpoint(
            path: "/auth/refresh",
            method: .post,
            body: try? JSONEncoder().encode(body)
        )
    }

    /// Logs out the current user, invalidating their session.
    ///
    /// - Returns: An endpoint configured for `POST /auth/logout`.
    public static var logout: Endpoint {
        Endpoint(
            path: "/auth/logout",
            method: .post
        )
    }
}
