import Foundation
import Models
import Common
import Networking
import Persistence
import Analytics

// MARK: - TaskDetailRepositoryProtocol

/// A protocol defining task data access operations needed by the TaskDetail module.
///
/// Mirrors the relevant subset of `TaskRepositoryProtocol` from the TaskBoard
/// module, allowing TaskDetail to remain decoupled while sharing the same
/// repository implementation at the composition root.
public protocol TaskDetailRepositoryProtocol: Sendable {
    /// Fetches a single task by its identifier.
    func fetchTask(id: UUID) async throws -> TaskItem

    /// Updates an existing task with modified fields.
    func updateTask(_ task: TaskItem) async throws -> TaskItem

    /// Updates only the status of a task.
    func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem
}

// MARK: - TaskDetailViewModel

/// View model for the task detail screen.
///
/// Manages the full task lifecycle view including task data, comments,
/// attachments, and edit mode. Emits interaction events for the
/// experimentation analytics pipeline.
@Observable
@MainActor
public final class TaskDetailViewModel {
    // MARK: - Published State

    /// The loaded task, or `nil` if not yet loaded.
    public private(set) var task: TaskItem?

    /// The task's comments.
    public private(set) var comments: [Comment] = []

    /// The task's attachments.
    public private(set) var attachments: [Attachment] = []

    /// Whether a load operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public var errorMessage: String?

    /// Whether the task is currently in edit mode.
    public var isEditing = false

    // MARK: - Dependencies

    private let repository: any TaskDetailRepositoryProtocol
    private let apiClient: any APIClientProtocol
    private let interactionTracker: any InteractionTracking

    // MARK: - Init

    /// Creates a new task detail view model.
    ///
    /// - Parameters:
    ///   - repository: The task data repository.
    ///   - apiClient: The API client for comments and attachments.
    ///   - interactionTracker: The interaction tracking service for analytics.
    public init(
        repository: any TaskDetailRepositoryProtocol,
        apiClient: any APIClientProtocol,
        interactionTracker: any InteractionTracking
    ) {
        self.repository = repository
        self.apiClient = apiClient
        self.interactionTracker = interactionTracker
    }

    // MARK: - Actions

    /// Loads a task by its identifier.
    ///
    /// Emits a `task_detail_view` interaction event on successful load.
    ///
    /// - Parameter id: The UUID of the task to load.
    public func loadTask(id: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            task = try await repository.fetchTask(id: id)

            await interactionTracker.track(InteractionEvent(
                type: .navigate,
                screen: "TaskDetail",
                metadata: [
                    "action": "task_detail_view",
                    "task_id": id.uuidString
                ]
            ))
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load task \(id): \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Updates the task with modified fields.
    ///
    /// Emits a `task_edit` interaction event on success.
    ///
    /// - Parameter updatedTask: The task with modified fields.
    public func updateTask(_ updatedTask: TaskItem) async {
        do {
            task = try await repository.updateTask(updatedTask)
            isEditing = false

            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskDetail",
                metadata: [
                    "action": "task_edit",
                    "task_id": updatedTask.id.uuidString
                ]
            ))
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to update task: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    /// Updates only the task's status.
    ///
    /// Emits a `task_status_change` interaction event with previous and new status.
    ///
    /// - Parameter status: The new status to set.
    public func updateStatus(_ status: TaskStatus) async {
        guard let currentTask = task else { return }
        let previousStatus = currentTask.status

        do {
            task = try await repository.updateTaskStatus(
                id: currentTask.id,
                status: status
            )

            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskDetail",
                metadata: [
                    "action": "task_status_change",
                    "task_id": currentTask.id.uuidString,
                    "from_status": previousStatus.rawValue,
                    "to_status": status.rawValue
                ]
            ))
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to update status: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    /// Loads comments for the current task.
    ///
    /// Emits a `comment_view` interaction event on successful load.
    public func loadComments() async {
        guard let taskId = task?.id else { return }

        let endpoint = Endpoint(
            path: "/tasks/\(taskId.uuidString)/comments",
            method: .get
        )

        do {
            comments = try await apiClient.request(endpoint)

            await interactionTracker.track(InteractionEvent(
                type: .navigate,
                screen: "TaskDetail",
                metadata: [
                    "action": "comment_view",
                    "task_id": taskId.uuidString,
                    "comment_count": "\(comments.count)"
                ]
            ))
        } catch {
            AppLogger.warning(
                "Failed to load comments: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    /// Loads attachments for the current task.
    public func loadAttachments() async {
        guard let taskId = task?.id else { return }

        let endpoint = Endpoint(
            path: "/tasks/\(taskId.uuidString)/attachments",
            method: .get
        )

        do {
            attachments = try await apiClient.request(endpoint)
        } catch {
            AppLogger.warning(
                "Failed to load attachments: \(error.localizedDescription)",
                category: .network
            )
        }
    }
}
