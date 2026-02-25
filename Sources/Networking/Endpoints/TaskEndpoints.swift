import Foundation
import Models

/// Endpoints for task-related API operations.
public enum TaskEndpoints {
    /// Fetches all tasks belonging to a project.
    ///
    /// - Parameter projectId: The project's unique identifier.
    /// - Returns: An endpoint configured for `GET /projects/:projectId/tasks`.
    public static func list(projectId: UUID) -> Endpoint {
        Endpoint(
            path: "/projects/\(projectId.uuidString)/tasks",
            method: .get
        )
    }

    /// Fetches a single task by its identifier.
    ///
    /// - Parameter id: The task's unique identifier.
    /// - Returns: An endpoint configured for `GET /tasks/:id`.
    public static func get(id: UUID) -> Endpoint {
        Endpoint(
            path: "/tasks/\(id.uuidString)",
            method: .get
        )
    }

    /// Creates a new task within a project.
    ///
    /// - Parameters:
    ///   - title: The task title.
    ///   - taskDescription: An optional description of the task.
    ///   - status: The initial task status.
    ///   - priority: The task priority level.
    ///   - projectId: The parent project's identifier.
    ///   - assigneeId: The optional assignee's user identifier.
    ///   - dueDate: The optional due date.
    ///   - tags: Tags associated with the task.
    /// - Returns: An endpoint configured for `POST /tasks`.
    public static func create(
        title: String,
        taskDescription: String?,
        status: TaskStatus,
        priority: TaskPriority,
        projectId: UUID,
        assigneeId: UUID?,
        dueDate: Date?,
        tags: [String]
    ) -> Endpoint {
        var body: [String: Any] = [
            "title": title,
            "status": status.rawValue,
            "priority": priority.rawValue,
            "project_id": projectId.uuidString,
            "tags": tags
        ]

        if let taskDescription {
            body["description"] = taskDescription
        }
        if let assigneeId {
            body["assignee_id"] = assigneeId.uuidString
        }
        if let dueDate {
            body["due_date"] = ISO8601DateFormatter().string(from: dueDate)
        }

        let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])

        return Endpoint(
            path: "/tasks",
            method: .post,
            body: data
        )
    }

    /// Updates an existing task.
    ///
    /// - Parameters:
    ///   - id: The task's unique identifier.
    ///   - title: The updated task title.
    ///   - taskDescription: The updated description, or `nil`.
    ///   - status: The updated status.
    ///   - priority: The updated priority.
    ///   - assigneeId: The updated assignee, or `nil`.
    ///   - dueDate: The updated due date, or `nil`.
    ///   - tags: The updated tags.
    /// - Returns: An endpoint configured for `PUT /tasks/:id`.
    public static func update(
        id: UUID,
        title: String,
        taskDescription: String?,
        status: TaskStatus,
        priority: TaskPriority,
        assigneeId: UUID?,
        dueDate: Date?,
        tags: [String]
    ) -> Endpoint {
        var body: [String: Any] = [
            "title": title,
            "status": status.rawValue,
            "priority": priority.rawValue,
            "tags": tags
        ]

        if let taskDescription {
            body["description"] = taskDescription
        }
        if let assigneeId {
            body["assignee_id"] = assigneeId.uuidString
        }
        if let dueDate {
            body["due_date"] = ISO8601DateFormatter().string(from: dueDate)
        }

        let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])

        return Endpoint(
            path: "/tasks/\(id.uuidString)",
            method: .put,
            body: data
        )
    }

    /// Deletes a task.
    ///
    /// - Parameter id: The task's unique identifier.
    /// - Returns: An endpoint configured for `DELETE /tasks/:id`.
    public static func delete(id: UUID) -> Endpoint {
        Endpoint(
            path: "/tasks/\(id.uuidString)",
            method: .delete
        )
    }

    /// Updates only the status of a task.
    ///
    /// - Parameters:
    ///   - id: The task's unique identifier.
    ///   - status: The new task status.
    /// - Returns: An endpoint configured for `PATCH /tasks/:id/status`.
    public static func updateStatus(id: UUID, status: TaskStatus) -> Endpoint {
        let body: [String: String] = ["status": status.rawValue]
        return Endpoint(
            path: "/tasks/\(id.uuidString)/status",
            method: .patch,
            body: try? JSONEncoder().encode(body)
        )
    }
}
