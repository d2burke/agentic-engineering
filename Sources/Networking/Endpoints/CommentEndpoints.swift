import Foundation

/// Endpoints for comment-related API operations.
public enum CommentEndpoints {
    /// Fetches all comments for a given task.
    ///
    /// - Parameter taskId: The task's unique identifier.
    /// - Returns: An endpoint configured for `GET /tasks/:taskId/comments`.
    public static func list(taskId: UUID) -> Endpoint {
        Endpoint(
            path: "/tasks/\(taskId.uuidString)/comments",
            method: .get
        )
    }

    /// Creates a new comment on a task.
    ///
    /// - Parameters:
    ///   - taskId: The task's unique identifier.
    ///   - body: The comment text.
    /// - Returns: An endpoint configured for `POST /tasks/:taskId/comments`.
    public static func create(taskId: UUID, body: String) -> Endpoint {
        let payload: [String: String] = ["body": body]
        return Endpoint(
            path: "/tasks/\(taskId.uuidString)/comments",
            method: .post,
            body: try? JSONEncoder().encode(payload)
        )
    }

    /// Updates an existing comment.
    ///
    /// - Parameters:
    ///   - id: The comment's unique identifier.
    ///   - body: The updated comment text.
    /// - Returns: An endpoint configured for `PUT /comments/:id`.
    public static func update(id: UUID, body: String) -> Endpoint {
        let payload: [String: String] = ["body": body]
        return Endpoint(
            path: "/comments/\(id.uuidString)",
            method: .put,
            body: try? JSONEncoder().encode(payload)
        )
    }

    /// Deletes a comment.
    ///
    /// - Parameter id: The comment's unique identifier.
    /// - Returns: An endpoint configured for `DELETE /comments/:id`.
    public static func delete(id: UUID) -> Endpoint {
        Endpoint(
            path: "/comments/\(id.uuidString)",
            method: .delete
        )
    }
}
