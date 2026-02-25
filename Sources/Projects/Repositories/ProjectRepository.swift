import Foundation
import Models
import Common
import Networking
import Persistence

// MARK: - ProjectRepositoryProtocol

/// Defines the data access contract for project operations.
///
/// Abstracts the networking and persistence layers so that view models
/// remain testable and decoupled from infrastructure concerns.
public protocol ProjectRepositoryProtocol: Sendable {
    /// Fetches all projects the current user has access to.
    func fetchProjects() async throws -> [Project]

    /// Fetches a single project by its identifier.
    func fetchProject(id: UUID) async throws -> Project

    /// Creates a new project with the given name and optional description.
    func createProject(name: String, description: String?) async throws -> Project

    /// Updates an existing project with modified fields.
    func updateProject(_ project: Project) async throws -> Project

    /// Deletes a project by its identifier.
    func deleteProject(id: UUID) async throws
}

// MARK: - ProjectRepository

/// Production implementation of `ProjectRepositoryProtocol`.
///
/// Fetches data from the remote API and caches results in local persistence.
/// Create and update operations use optimistic persistence updates, rolling
/// back on API failure to maintain UI responsiveness.
public struct ProjectRepository: ProjectRepositoryProtocol {
    private let apiClient: any APIClientProtocol
    private let persistence: PersistenceManager

    private static let cacheKey = "cached_projects"

    /// Creates a new project repository.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for remote communication.
    ///   - persistence: The persistence manager for local caching.
    public init(apiClient: any APIClientProtocol, persistence: PersistenceManager) {
        self.apiClient = apiClient
        self.persistence = persistence
    }

    public func fetchProjects() async throws -> [Project] {
        let cachedProjects: [Project] = try await persistence.load(forKey: Self.cacheKey)

        let endpoint = Endpoint(path: "/projects", method: .get)

        do {
            let projects: [Project] = try await apiClient.request(endpoint)
            try await persistence.save(projects, forKey: Self.cacheKey)
            return projects
        } catch {
            if !cachedProjects.isEmpty {
                AppLogger.warning(
                    "API fetch failed, returning cached projects: \(error.localizedDescription)",
                    category: .network
                )
                return cachedProjects
            }
            throw error
        }
    }

    public func fetchProject(id: UUID) async throws -> Project {
        let cacheKey = "project_\(id.uuidString)"
        let endpoint = Endpoint(path: "/projects/\(id.uuidString)", method: .get)

        do {
            let project: Project = try await apiClient.request(endpoint)
            try await persistence.save(project, forKey: cacheKey)
            return project
        } catch {
            if let cached: Project = try await persistence.loadOne(forKey: cacheKey) {
                AppLogger.warning(
                    "API fetch failed for project \(id), returning cached: \(error.localizedDescription)",
                    category: .network
                )
                return cached
            }
            throw error
        }
    }

    public func createProject(name: String, description: String?) async throws -> Project {
        let optimisticProject = Project(
            name: name,
            projectDescription: description,
            ownerId: UUID(),
            memberIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        var cachedProjects: [Project] = try await persistence.load(forKey: Self.cacheKey)
        cachedProjects.append(optimisticProject)
        try await persistence.save(cachedProjects, forKey: Self.cacheKey)

        do {
            let body = try JSONEncoder().encode(
                CreateProjectRequest(name: name, description: description)
            )
            let endpoint = Endpoint(path: "/projects", method: .post, body: body)
            let createdProject: Project = try await apiClient.request(endpoint)

            cachedProjects = cachedProjects.filter { $0.id != optimisticProject.id }
            cachedProjects.append(createdProject)
            try await persistence.save(cachedProjects, forKey: Self.cacheKey)

            return createdProject
        } catch {
            let rolledBack = cachedProjects.filter { $0.id != optimisticProject.id }
            try await persistence.save(rolledBack, forKey: Self.cacheKey)
            AppLogger.error(
                "Create project failed, rolled back persistence: \(error.localizedDescription)",
                category: .persistence
            )
            throw error
        }
    }

    public func updateProject(_ project: Project) async throws -> Project {
        let cacheKey = "project_\(project.id.uuidString)"
        let previousProject: Project? = try await persistence.loadOne(forKey: cacheKey)

        try await persistence.save(project, forKey: cacheKey)

        var cachedProjects: [Project] = try await persistence.load(forKey: Self.cacheKey)
        if let index = cachedProjects.firstIndex(where: { $0.id == project.id }) {
            cachedProjects[index] = project
            try await persistence.save(cachedProjects, forKey: Self.cacheKey)
        }

        do {
            let body = try JSONEncoder().encode(project)
            let endpoint = Endpoint(
                path: "/projects/\(project.id.uuidString)",
                method: .put,
                body: body
            )
            let updatedProject: Project = try await apiClient.request(endpoint)
            try await persistence.save(updatedProject, forKey: cacheKey)
            return updatedProject
        } catch {
            if let previous = previousProject {
                try await persistence.save(previous, forKey: cacheKey)

                if let index = cachedProjects.firstIndex(where: { $0.id == project.id }) {
                    cachedProjects[index] = previous
                    try await persistence.save(cachedProjects, forKey: Self.cacheKey)
                }
            }
            AppLogger.error(
                "Update project failed, rolled back persistence: \(error.localizedDescription)",
                category: .persistence
            )
            throw error
        }
    }

    public func deleteProject(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "/projects/\(id.uuidString)",
            method: .delete
        )
        try await apiClient.request(endpoint) as Void

        var cachedProjects: [Project] = try await persistence.load(forKey: Self.cacheKey)
        cachedProjects.removeAll { $0.id == id }
        try await persistence.save(cachedProjects, forKey: Self.cacheKey)
        try await persistence.remove(forKey: "project_\(id.uuidString)")
    }
}

// MARK: - Request DTOs

private struct CreateProjectRequest: Encodable {
    let name: String
    let description: String?
}
