import Foundation
import Models
import Common
import Networking
import Persistence

// MARK: - TaskDetailRepository

/// Production implementation of `TaskDetailRepositoryProtocol`.
///
/// Provides task data access for the TaskDetail module using the API client
/// and local persistence. Shares the same caching strategy as the TaskBoard
/// repository to ensure data consistency.
public struct TaskDetailRepository: TaskDetailRepositoryProtocol {
    private let apiClient: any APIClientProtocol
    private let persistence: PersistenceManager

    /// Creates a new task detail repository.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for remote communication.
    ///   - persistence: The persistence manager for local caching.
    public init(apiClient: any APIClientProtocol, persistence: PersistenceManager) {
        self.apiClient = apiClient
        self.persistence = persistence
    }

    public func fetchTask(id: UUID) async throws -> TaskItem {
        let cacheKey = "task_\(id.uuidString)"
        let endpoint = Endpoint(path: "/tasks/\(id.uuidString)", method: .get)

        do {
            let task: TaskItem = try await apiClient.request(endpoint)
            try await persistence.save(task, forKey: cacheKey)
            return task
        } catch {
            if let cached: TaskItem = try await persistence.loadOne(forKey: cacheKey) {
                AppLogger.warning(
                    "API fetch failed for task \(id), returning cached: \(error.localizedDescription)",
                    category: .network
                )
                return cached
            }
            throw error
        }
    }

    public func updateTask(_ task: TaskItem) async throws -> TaskItem {
        let cacheKey = "task_\(task.id.uuidString)"
        let previousTask: TaskItem? = try await persistence.loadOne(forKey: cacheKey)

        try await persistence.save(task, forKey: cacheKey)

        do {
            let body = try JSONEncoder().encode(task)
            let endpoint = Endpoint(
                path: "/tasks/\(task.id.uuidString)",
                method: .put,
                body: body
            )
            let updatedTask: TaskItem = try await apiClient.request(endpoint)
            try await persistence.save(updatedTask, forKey: cacheKey)
            return updatedTask
        } catch {
            if let previous = previousTask {
                try await persistence.save(previous, forKey: cacheKey)
            }
            throw error
        }
    }

    public func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem {
        let cacheKey = "task_\(id.uuidString)"
        let body = try JSONEncoder().encode(["status": status.rawValue])
        let endpoint = Endpoint(
            path: "/tasks/\(id.uuidString)/status",
            method: .patch,
            body: body
        )
        let updatedTask: TaskItem = try await apiClient.request(endpoint)
        try await persistence.save(updatedTask, forKey: cacheKey)
        return updatedTask
    }
}
