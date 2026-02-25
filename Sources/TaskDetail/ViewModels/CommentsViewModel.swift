import Foundation
import Models
import Common
import Networking
import Analytics

// MARK: - CommentsViewModel

/// View model managing the comments section of a task detail.
///
/// Handles loading, adding, and deleting comments. Emits interaction
/// events for comment operations to support the experimentation pipeline.
@Observable
@MainActor
public final class CommentsViewModel {
    // MARK: - Published State

    /// The list of comments for the current task.
    public private(set) var comments: [Comment] = []

    /// The text for a new comment being composed.
    public var newCommentText: String = ""

    /// Whether a load or save operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient: any APIClientProtocol
    private let interactionTracker: any InteractionTracking

    // MARK: - Init

    /// Creates a new comments view model.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for comment operations.
    ///   - interactionTracker: The interaction tracking service for analytics.
    public init(
        apiClient: any APIClientProtocol,
        interactionTracker: any InteractionTracking
    ) {
        self.apiClient = apiClient
        self.interactionTracker = interactionTracker
    }

    // MARK: - Actions

    /// Loads all comments for a task.
    ///
    /// - Parameter taskId: The UUID of the task to load comments for.
    public func loadComments(taskId: UUID) async {
        isLoading = true
        errorMessage = nil

        let endpoint = Endpoint(
            path: "/tasks/\(taskId.uuidString)/comments",
            method: .get
        )

        do {
            comments = try await apiClient.request(endpoint)
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load comments: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Adds a new comment to a task.
    ///
    /// Emits a `comment_add` interaction event on success.
    ///
    /// - Parameter taskId: The UUID of the task to comment on.
    public func addComment(taskId: UUID) async {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let body = try JSONEncoder().encode(AddCommentRequest(body: trimmed))
            let endpoint = Endpoint(
                path: "/tasks/\(taskId.uuidString)/comments",
                method: .post,
                body: body
            )
            let comment: Comment = try await apiClient.request(endpoint)
            comments.append(comment)
            newCommentText = ""

            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskDetail",
                metadata: [
                    "action": "comment_add",
                    "task_id": taskId.uuidString,
                    "comment_id": comment.id.uuidString
                ]
            ))
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to add comment: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Deletes a comment by its identifier.
    ///
    /// Emits a `comment_delete` interaction event on success.
    ///
    /// - Parameter id: The UUID of the comment to delete.
    public func deleteComment(id: UUID) async {
        let previousComments = comments
        comments.removeAll { $0.id == id }

        let endpoint = Endpoint(
            path: "/comments/\(id.uuidString)",
            method: .delete
        )

        do {
            try await apiClient.request(endpoint)

            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskDetail",
                metadata: [
                    "action": "comment_delete",
                    "comment_id": id.uuidString
                ]
            ))
        } catch {
            comments = previousComments
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to delete comment: \(error.localizedDescription)",
                category: .network
            )
        }
    }
}

// MARK: - Request DTOs

private struct AddCommentRequest: Encodable {
    let body: String
}
