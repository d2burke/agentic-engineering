import Foundation
import SwiftUI
import Models
import Common

// MARK: - DeepLinkHandler

/// Parses push notification payloads and manages pending deep link navigation.
///
/// When a push notification arrives, the `handle(userInfo:)` method extracts
/// the relevant identifiers (task, project, notification type) and stores them
/// as pending navigation targets. The app coordinator consults `pendingTaskId`
/// and `pendingProjectId` to route the user to the correct screen, then calls
/// `clearPending()` to reset the state.
///
/// This class is `@Observable` so that SwiftUI views can reactively respond
/// to deep link state changes.
@Observable
@MainActor
public final class DeepLinkHandler {

    // MARK: - Pending Navigation State

    /// The task ID extracted from the most recent notification payload, if any.
    public private(set) var pendingTaskId: UUID?

    /// The project ID extracted from the most recent notification payload, if any.
    public private(set) var pendingProjectId: UUID?

    /// The notification type extracted from the most recent notification payload, if any.
    public private(set) var pendingNotificationType: NotificationType?

    // MARK: - UserInfo Keys

    /// Keys expected in the notification's `userInfo` dictionary.
    private enum UserInfoKey {
        static let taskId = "task_id"
        static let projectId = "project_id"
        static let notificationType = "notification_type"
    }

    // MARK: - Init

    public init() {}

    // MARK: - Public API

    /// Parses a notification payload and stores any navigation targets.
    ///
    /// The method extracts `task_id`, `project_id`, and `notification_type`
    /// from the userInfo dictionary. Values that cannot be parsed are silently
    /// ignored, allowing partial payloads to still drive navigation.
    ///
    /// - Parameter userInfo: The notification's userInfo dictionary from APNs
    ///   or `UNNotificationResponse`.
    public func handle(userInfo: [AnyHashable: Any]) {
        // Extract task ID
        if let taskIdString = userInfo[UserInfoKey.taskId] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            pendingTaskId = taskId
        } else {
            pendingTaskId = nil
        }

        // Extract project ID
        if let projectIdString = userInfo[UserInfoKey.projectId] as? String,
           let projectId = UUID(uuidString: projectIdString) {
            pendingProjectId = projectId
        } else {
            pendingProjectId = nil
        }

        // Extract notification type
        if let typeString = userInfo[UserInfoKey.notificationType] as? String,
           let type = NotificationType(rawValue: typeString) {
            pendingNotificationType = type
        } else {
            pendingNotificationType = nil
        }

        if pendingTaskId != nil || pendingProjectId != nil {
            AppLogger.info(
                "Deep link parsed - taskId: \(pendingTaskId?.uuidString ?? "nil"), "
                + "projectId: \(pendingProjectId?.uuidString ?? "nil"), "
                + "type: \(pendingNotificationType?.rawValue ?? "nil")",
                category: .ui
            )
        }
    }

    /// Clears all pending navigation state.
    ///
    /// Call this after the app coordinator has consumed the deep link
    /// and navigated the user to the target screen.
    public func clearPending() {
        pendingTaskId = nil
        pendingProjectId = nil
        pendingNotificationType = nil
    }

    /// Whether there is any pending deep link navigation to process.
    public var hasPendingNavigation: Bool {
        pendingTaskId != nil || pendingProjectId != nil
    }
}
