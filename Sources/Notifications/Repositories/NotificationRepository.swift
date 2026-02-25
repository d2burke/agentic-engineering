import Foundation
import Models
import Common
import Networking

// MARK: - NotificationRepositoryProtocol

/// Defines the data access contract for notification operations.
///
/// This protocol abstracts the notification data source so that the
/// view model layer can be tested with in-memory or mock implementations.
public protocol NotificationRepositoryProtocol: Sendable {
    /// Fetches all notifications for the current user, ordered by creation date (newest first).
    ///
    /// - Throws: An error if the network request or decoding fails.
    /// - Returns: An array of `NotificationItem` instances.
    func fetchNotifications() async throws -> [NotificationItem]

    /// Marks a single notification as read.
    ///
    /// - Parameter id: The unique identifier of the notification to mark.
    /// - Throws: An error if the network request fails.
    func markAsRead(id: UUID) async throws

    /// Marks all notifications for the current user as read.
    ///
    /// - Throws: An error if the network request fails.
    func markAllAsRead() async throws

    /// The number of unread notifications for the current user.
    var unreadCount: Int { get async }
}

// MARK: - NotificationEndpoints

/// API endpoint definitions for notification-related requests.
public enum NotificationEndpoints {
    /// Fetches the list of notifications for the current user.
    public static func list() -> Endpoint {
        Endpoint(path: "/notifications", method: .get)
    }

    /// Marks a specific notification as read.
    ///
    /// - Parameter id: The notification identifier.
    public static func markRead(id: UUID) -> Endpoint {
        Endpoint(path: "/notifications/\(id.uuidString)/read", method: .put)
    }

    /// Marks all notifications as read for the current user.
    public static func markAllRead() -> Endpoint {
        Endpoint(path: "/notifications/read-all", method: .put)
    }

    /// Retrieves only the unread notification count.
    public static func unreadCount() -> Endpoint {
        Endpoint(path: "/notifications/unread-count", method: .get)
    }

    /// Registers a device token for push notifications.
    ///
    /// - Parameter tokenData: The encoded device token payload.
    public static func registerDevice(body: Data) -> Endpoint {
        Endpoint(path: "/notifications/devices", method: .post, body: body)
    }
}

// MARK: - NotificationRepository

/// Production implementation of `NotificationRepositoryProtocol` backed
/// by the remote API via `APIClientProtocol`.
public struct NotificationRepository: NotificationRepositoryProtocol {

    /// The API client used to execute network requests.
    private let apiClient: any APIClientProtocol

    /// Creates a new notification repository.
    ///
    /// - Parameter apiClient: The API client to use for network communication.
    public init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - NotificationRepositoryProtocol

    public func fetchNotifications() async throws -> [NotificationItem] {
        let endpoint = NotificationEndpoints.list()
        let notifications: [NotificationItem] = try await apiClient.request(endpoint)
        return notifications.sorted { $0.createdAt > $1.createdAt }
    }

    public func markAsRead(id: UUID) async throws {
        let endpoint = NotificationEndpoints.markRead(id: id)
        try await apiClient.request(endpoint)
    }

    public func markAllAsRead() async throws {
        let endpoint = NotificationEndpoints.markAllRead()
        try await apiClient.request(endpoint)
    }

    public var unreadCount: Int {
        get async {
            do {
                let endpoint = NotificationEndpoints.unreadCount()
                let response: UnreadCountResponse = try await apiClient.request(endpoint)
                return response.count
            } catch {
                AppLogger.error(
                    "Failed to fetch unread count: \(error.localizedDescription)",
                    category: .network
                )
                return 0
            }
        }
    }
}

// MARK: - Response Types

/// Response body for the unread-count endpoint.
private struct UnreadCountResponse: Decodable, Sendable {
    let count: Int
}
