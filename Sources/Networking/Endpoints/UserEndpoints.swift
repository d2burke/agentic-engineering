import Foundation

/// Endpoints for user-related API operations.
public enum UserEndpoints {
    /// Fetches the currently authenticated user's profile.
    ///
    /// - Returns: An endpoint configured for `GET /users/me`.
    public static var me: Endpoint {
        Endpoint(
            path: "/users/me",
            method: .get
        )
    }

    /// Fetches a user by their unique identifier.
    ///
    /// - Parameter id: The user's unique identifier.
    /// - Returns: An endpoint configured for `GET /users/:id`.
    public static func get(id: UUID) -> Endpoint {
        Endpoint(
            path: "/users/\(id.uuidString)",
            method: .get
        )
    }

    /// Updates the current user's profile.
    ///
    /// - Parameters:
    ///   - displayName: The updated display name, or `nil` to leave unchanged.
    ///   - avatarURL: The updated avatar URL, or `nil` to leave unchanged.
    /// - Returns: An endpoint configured for `PATCH /users/me`.
    public static func updateProfile(displayName: String?, avatarURL: URL?) -> Endpoint {
        var body: [String: String] = [:]
        if let displayName {
            body["display_name"] = displayName
        }
        if let avatarURL {
            body["avatar_url"] = avatarURL.absoluteString
        }
        return Endpoint(
            path: "/users/me",
            method: .patch,
            body: try? JSONEncoder().encode(body)
        )
    }
}
