import Testing
import Foundation
@testable import Notifications
@testable import Models
import Common
import Analytics

// MARK: - MockNotificationRepository

/// A mock implementation of `NotificationRepositoryProtocol` for testing.
///
/// Stores notifications in memory and tracks method calls to verify
/// view model behavior without network dependencies.
@MainActor
final class MockNotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {
    /// The notifications to return from `fetchNotifications()`.
    var stubbedNotifications: [NotificationItem] = []

    /// Error to throw from any method, if set.
    var stubbedError: Error?

    /// Tracks which notification IDs were marked as read.
    var markedAsReadIds: [UUID] = []

    /// Whether `markAllAsRead()` was called.
    var didMarkAllAsRead = false

    func fetchNotifications() async throws -> [NotificationItem] {
        if let error = stubbedError {
            throw error
        }
        return stubbedNotifications
    }

    func markAsRead(id: UUID) async throws {
        if let error = stubbedError {
            throw error
        }
        markedAsReadIds.append(id)
    }

    func markAllAsRead() async throws {
        if let error = stubbedError {
            throw error
        }
        didMarkAllAsRead = true
    }

    var unreadCount: Int {
        get async {
            stubbedNotifications.filter { !$0.isRead }.count
        }
    }
}

// MARK: - MockInteractionTracker

/// A mock interaction tracker that records tracked events for assertion.
actor MockInteractionTracker: InteractionTracking {
    var trackedEvents: [InteractionEvent] = []

    nonisolated let signalStream: AsyncStream<ExceptionalSignal>
    private let continuation: AsyncStream<ExceptionalSignal>.Continuation

    init() {
        var cont: AsyncStream<ExceptionalSignal>.Continuation!
        self.signalStream = AsyncStream { c in cont = c }
        self.continuation = cont
    }

    func track(_ event: InteractionEvent) async {
        trackedEvents.append(event)
    }

    func registerDetector(_ detector: any ExceptionalSignalDetector) async {}
    func registerExporter(_ exporter: any SignalExporter) async {}

    func eventCount() -> Int {
        trackedEvents.count
    }
}

// MARK: - Test Helpers

/// Creates a sample `NotificationItem` for testing.
private func makeNotification(
    id: UUID = UUID(),
    type: NotificationType = .taskAssigned,
    title: String = "Test Notification",
    body: String = "Test body",
    isRead: Bool = false,
    createdAt: Date = Date()
) -> NotificationItem {
    NotificationItem(
        id: id,
        userId: UUID(),
        type: type,
        title: title,
        body: body,
        relatedTaskId: UUID(),
        relatedProjectId: UUID(),
        isRead: isRead,
        createdAt: createdAt
    )
}

// MARK: - Tests

@Suite("NotificationFeedViewModel Tests")
@MainActor
struct NotificationFeedViewModelTests {

    // MARK: - loadNotifications

    @Test("loadNotifications populates the notifications list")
    func loadNotificationsPopulatesList() async {
        let repo = MockNotificationRepository()
        let n1 = makeNotification(title: "First")
        let n2 = makeNotification(title: "Second")
        repo.stubbedNotifications = [n1, n2]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()

        #expect(viewModel.notifications.count == 2)
        #expect(viewModel.notifications[0].title == "First")
        #expect(viewModel.notifications[1].title == "Second")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("loadNotifications sets error message on failure")
    func loadNotificationsHandlesError() async {
        let repo = MockNotificationRepository()
        repo.stubbedError = AppError.network("Connection failed")

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()

        #expect(viewModel.notifications.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - markAsRead

    @Test("markAsRead updates notification state to read")
    func markAsReadUpdatesState() async {
        let repo = MockNotificationRepository()
        let notificationId = UUID()
        let notification = makeNotification(id: notificationId, isRead: false)
        repo.stubbedNotifications = [notification]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()
        #expect(viewModel.notifications[0].isRead == false)

        await viewModel.markAsRead(id: notificationId)

        #expect(viewModel.notifications[0].isRead == true)
        #expect(repo.markedAsReadIds.contains(notificationId))
    }

    @Test("markAsRead does nothing for already-read notification")
    func markAsReadSkipsAlreadyRead() async {
        let repo = MockNotificationRepository()
        let notificationId = UUID()
        let notification = makeNotification(id: notificationId, isRead: true)
        repo.stubbedNotifications = [notification]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()
        await viewModel.markAsRead(id: notificationId)

        #expect(repo.markedAsReadIds.isEmpty)
    }

    @Test("markAsRead sets error message on failure")
    func markAsReadHandlesError() async {
        let repo = MockNotificationRepository()
        let notificationId = UUID()
        let notification = makeNotification(id: notificationId, isRead: false)
        repo.stubbedNotifications = [notification]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()

        // Set error after initial load succeeds
        repo.stubbedError = AppError.network("Failed")
        await viewModel.markAsRead(id: notificationId)

        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - markAllAsRead

    @Test("markAllAsRead marks all notifications as read and resets unread count")
    func markAllAsReadClearsUnread() async {
        let repo = MockNotificationRepository()
        let n1 = makeNotification(isRead: false)
        let n2 = makeNotification(isRead: false)
        let n3 = makeNotification(isRead: true)
        repo.stubbedNotifications = [n1, n2, n3]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()
        #expect(viewModel.unreadCount == 2)

        await viewModel.markAllAsRead()

        #expect(viewModel.unreadCount == 0)
        #expect(viewModel.notifications.allSatisfy(\.isRead))
        #expect(repo.didMarkAllAsRead == true)
    }

    @Test("markAllAsRead sets error message on failure")
    func markAllAsReadHandlesError() async {
        let repo = MockNotificationRepository()
        repo.stubbedNotifications = [makeNotification(isRead: false)]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()

        repo.stubbedError = AppError.network("Server error")
        await viewModel.markAllAsRead()

        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - unreadCount

    @Test("unreadCount is computed correctly after load")
    func unreadCountComputedCorrectly() async {
        let repo = MockNotificationRepository()
        repo.stubbedNotifications = [
            makeNotification(isRead: false),
            makeNotification(isRead: true),
            makeNotification(isRead: false),
            makeNotification(isRead: true),
            makeNotification(isRead: false),
        ]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()

        #expect(viewModel.unreadCount == 3)
    }

    @Test("unreadCount updates after marking individual notification as read")
    func unreadCountUpdatesAfterMarkAsRead() async {
        let repo = MockNotificationRepository()
        let id1 = UUID()
        let id2 = UUID()
        repo.stubbedNotifications = [
            makeNotification(id: id1, isRead: false),
            makeNotification(id: id2, isRead: false),
        ]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()
        #expect(viewModel.unreadCount == 2)

        await viewModel.markAsRead(id: id1)
        #expect(viewModel.unreadCount == 1)

        await viewModel.markAsRead(id: id2)
        #expect(viewModel.unreadCount == 0)
    }

    // MARK: - refresh

    @Test("refresh reloads notifications from repository")
    func refreshReloadsData() async {
        let repo = MockNotificationRepository()
        repo.stubbedNotifications = [makeNotification(title: "Initial")]

        let viewModel = NotificationFeedViewModel(repository: repo)

        await viewModel.loadNotifications()
        #expect(viewModel.notifications.count == 1)

        // Update the stub
        repo.stubbedNotifications = [
            makeNotification(title: "Updated 1"),
            makeNotification(title: "Updated 2"),
        ]

        await viewModel.refresh()

        #expect(viewModel.notifications.count == 2)
        #expect(viewModel.notifications[0].title == "Updated 1")
    }

    // MARK: - Analytics Events

    @Test("loadNotifications emits notification_feed_view event")
    func loadEmitsAnalyticsEvent() async {
        let repo = MockNotificationRepository()
        repo.stubbedNotifications = [makeNotification()]
        let tracker = MockInteractionTracker()

        let viewModel = NotificationFeedViewModel(
            repository: repo,
            tracker: tracker
        )

        await viewModel.loadNotifications()

        // Allow the Task in trackEvent to complete
        try? await Task.sleep(for: .milliseconds(50))

        let eventCount = await tracker.eventCount()
        #expect(eventCount >= 1)
    }

    @Test("didTapNotification emits notification_tap event")
    func tapEmitsAnalyticsEvent() async {
        let repo = MockNotificationRepository()
        let notification = makeNotification(isRead: true)
        repo.stubbedNotifications = [notification]
        let tracker = MockInteractionTracker()

        let viewModel = NotificationFeedViewModel(
            repository: repo,
            tracker: tracker
        )

        await viewModel.loadNotifications()
        await viewModel.didTapNotification(notification)

        // Allow the Task in trackEvent to complete
        try? await Task.sleep(for: .milliseconds(50))

        let eventCount = await tracker.eventCount()
        #expect(eventCount >= 2) // feed_view + notification_tap
    }
}
