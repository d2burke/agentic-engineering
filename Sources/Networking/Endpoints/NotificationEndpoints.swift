import Foundation

/// Endpoints for notification-related API operations.
public enum NotificationEndpoints {
    /// Fetches all notifications for the current user.
    ///
    /// - Returns: An endpoint configured for `GET /notifications`.
    public static var list: Endpoint {
        Endpoint(
            path: "/notifications",
            method: .get
        )
    }

    /// Marks a single notification as read.
    ///
    /// - Parameter id: The notification's unique identifier.
    /// - Returns: An endpoint configured for `PATCH /notifications/:id/read`.
    public static func markRead(id: UUID) -> Endpoint {
        Endpoint(
            path: "/notifications/\(id.uuidString)/read",
            method: .patch
        )
    }

    /// Marks all notifications as read for the current user.
    ///
    /// - Returns: An endpoint configured for `POST /notifications/read-all`.
    public static var markAllRead: Endpoint {
        Endpoint(
            path: "/notifications/read-all",
            method: .post
        )
    }

    /// Registers a device push notification token with the server.
    ///
    /// - Parameter token: The device push notification token.
    /// - Returns: An endpoint configured for `POST /notifications/devices`.
    public static func registerDevice(token: String) -> Endpoint {
        let body: [String: String] = ["device_token": token]
        return Endpoint(
            path: "/notifications/devices",
            method: .post,
            body: try? JSONEncoder().encode(body)
        )
    }
}
