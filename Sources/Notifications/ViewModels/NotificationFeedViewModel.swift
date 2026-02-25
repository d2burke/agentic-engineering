import Foundation
import Models
import Common
import Analytics

// MARK: - NotificationFeedViewModel

/// View model managing the notification feed's state and user actions.
///
/// This class is `@Observable` for SwiftUI integration and `@MainActor`
/// to ensure all UI-related state mutations happen on the main thread.
/// It bridges user interactions to the repository layer and emits analytics
/// events for the experimentation pipeline.
@Observable
@MainActor
public final class NotificationFeedViewModel {

    // MARK: - Published State

    /// The list of notifications displayed in the feed.
    public private(set) var notifications: [NotificationItem] = []

    /// Whether a network request is currently in progress.
    public private(set) var isLoading: Bool = false

    /// An error message to display to the user, or `nil` if no error.
    public private(set) var errorMessage: String?

    /// The count of unread notifications.
    public private(set) var unreadCount: Int = 0

    // MARK: - Dependencies

    /// The repository providing notification data access.
    private let repository: any NotificationRepositoryProtocol

    /// The interaction tracker for analytics event emission.
    private let tracker: (any InteractionTracking)?

    // MARK: - Init

    /// Creates a new view model.
    ///
    /// - Parameters:
    ///   - repository: The notification data source.
    ///   - tracker: An optional interaction tracker for analytics. Pass `nil` to disable tracking.
    public init(
        repository: any NotificationRepositoryProtocol,
        tracker: (any InteractionTracking)? = nil
    ) {
        self.repository = repository
        self.tracker = tracker
    }

    // MARK: - Actions

    /// Loads notifications from the repository and updates the feed state.
    ///
    /// Emits a `notification_feed_view` analytics event upon successful load.
    public func loadNotifications() async {
        isLoading = true
        errorMessage = nil

        do {
            let items = try await repository.fetchNotifications()
            notifications = items
            unreadCount = items.filter { !$0.isRead }.count

            trackEvent(
                type: .navigate,
                screen: "NotificationFeed",
                metadata: [
                    "event_name": "notification_feed_view",
                    "notification_count": "\(items.count)",
                    "unread_count": "\(unreadCount)"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load notifications: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Marks a specific notification as read and updates the local state.
    ///
    /// Emits a `notification_mark_read` analytics event on success.
    ///
    /// - Parameter id: The identifier of the notification to mark as read.
    public func markAsRead(id: UUID) async {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        guard !notifications[index].isRead else { return }

        do {
            try await repository.markAsRead(id: id)
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count

            trackEvent(
                type: .tap,
                screen: "NotificationFeed",
                metadata: [
                    "event_name": "notification_mark_read",
                    "notification_id": id.uuidString,
                    "notification_type": notifications[index].type.rawValue
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to mark notification as read: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    /// Marks all notifications as read and updates the local state.
    ///
    /// Emits a `notification_mark_read` analytics event with `all` scope.
    public func markAllAsRead() async {
        do {
            try await repository.markAllAsRead()
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadCount = 0

            trackEvent(
                type: .tap,
                screen: "NotificationFeed",
                metadata: [
                    "event_name": "notification_mark_read",
                    "scope": "all"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to mark all notifications as read: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    /// Refreshes the notification feed by reloading from the repository.
    public func refresh() async {
        await loadNotifications()
    }

    /// Handles a tap on a specific notification.
    ///
    /// Emits a `notification_tap` analytics event with the notification type.
    ///
    /// - Parameter notification: The notification that was tapped.
    public func didTapNotification(_ notification: NotificationItem) async {
        trackEvent(
            type: .tap,
            screen: "NotificationFeed",
            metadata: [
                "event_name": "notification_tap",
                "notification_id": notification.id.uuidString,
                "notification_type": notification.type.rawValue,
                "related_task_id": notification.relatedTaskId?.uuidString ?? "",
                "related_project_id": notification.relatedProjectId?.uuidString ?? ""
            ]
        )

        if !notification.isRead {
            await markAsRead(id: notification.id)
        }
    }

    // MARK: - Private Helpers

    /// Emits an analytics event through the interaction tracker.
    private func trackEvent(
        type: InteractionType,
        screen: String,
        metadata: [String: String]
    ) {
        let event = InteractionEvent(
            type: type,
            screen: screen,
            metadata: metadata
        )
        tracker?.track(event)
    }
}
