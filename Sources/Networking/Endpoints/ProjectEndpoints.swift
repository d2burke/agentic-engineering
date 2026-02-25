import Foundation

/// Endpoints for project-related API operations.
public enum ProjectEndpoints {
    /// Fetches the list of all projects accessible to the current user.
    ///
    /// - Returns: An endpoint configured for `GET /projects`.
    public static var list: Endpoint {
        Endpoint(
            path: "/projects",
            method: .get
        )
    }

    /// Fetches a single project by its identifier.
    ///
    /// - Parameter id: The project's unique identifier.
    /// - Returns: An endpoint configured for `GET /projects/:id`.
    public static func get(id: UUID) -> Endpoint {
        Endpoint(
            path: "/projects/\(id.uuidString)",
            method: .get
        )
    }

    /// Creates a new project.
    ///
    /// - Parameters:
    ///   - name: The project name.
    ///   - description: An optional project description.
    /// - Returns: An endpoint configured for `POST /projects`.
    public static func create(name: String, description: String?) -> Endpoint {
        var body: [String: String] = ["name": name]
        if let description {
            body["description"] = description
        }
        return Endpoint(
            path: "/projects",
            method: .post,
            body: try? JSONEncoder().encode(body)
        )
    }

    /// Updates an existing project.
    ///
    /// - Parameters:
    ///   - id: The project's unique identifier.
    ///   - name: The updated project name.
    ///   - description: The updated project description, or `nil` to clear it.
    /// - Returns: An endpoint configured for `PUT /projects/:id`.
    public static func update(id: UUID, name: String, description: String?) -> Endpoint {
        var body: [String: String] = ["name": name]
        if let description {
            body["description"] = description
        }
        return Endpoint(
            path: "/projects/\(id.uuidString)",
            method: .put,
            body: try? JSONEncoder().encode(body)
        )
    }

    /// Deletes a project.
    ///
    /// - Parameter id: The project's unique identifier.
    /// - Returns: An endpoint configured for `DELETE /projects/:id`.
    public static func delete(id: UUID) -> Endpoint {
        Endpoint(
            path: "/projects/\(id.uuidString)",
            method: .delete
        )
    }

    /// Adds a member to a project.
    ///
    /// - Parameters:
    ///   - projectId: The project's unique identifier.
    ///   - userId: The user's unique identifier to add as a member.
    /// - Returns: An endpoint configured for `POST /projects/:id/members`.
    public static func addMember(projectId: UUID, userId: UUID) -> Endpoint {
        let body: [String: String] = ["user_id": userId.uuidString]
        return Endpoint(
            path: "/projects/\(projectId.uuidString)/members",
            method: .post,
            body: try? JSONEncoder().encode(body)
        )
    }
}
