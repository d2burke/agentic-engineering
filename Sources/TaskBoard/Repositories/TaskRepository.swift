import Foundation
import Models
import Common
import Networking
import Persistence

// MARK: - TaskRepositoryProtocol

/// Defines the data access contract for task operations.
///
/// Abstracts the networking and persistence layers so that view models
/// remain testable and decoupled from infrastructure concerns.
public protocol TaskRepositoryProtocol: Sendable {
    /// Fetches all tasks for a given project.
    func fetchTasks(projectId: UUID) async throws -> [TaskItem]

    /// Fetches a single task by its identifier.
    func fetchTask(id: UUID) async throws -> TaskItem

    /// Creates a new task.
    func createTask(_ task: TaskItem) async throws -> TaskItem

    /// Updates an existing task with modified fields.
    func updateTask(_ task: TaskItem) async throws -> TaskItem

    /// Updates only the status of a task.
    func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem

    /// Deletes a task by its identifier.
    func deleteTask(id: UUID) async throws
}

// MARK: - TaskRepository

/// Production implementation of `TaskRepositoryProtocol`.
///
/// Uses a cache-first read strategy with background refresh. Write operations
/// apply optimistic updates to the local cache before issuing the API call,
/// rolling back on failure.
public struct TaskRepository: TaskRepositoryProtocol {
    private let apiClient: any APIClientProtocol
    private let persistence: PersistenceManager

    /// Creates a new task repository.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for remote communication.
    ///   - persistence: The persistence manager for local caching.
    public init(apiClient: any APIClientProtocol, persistence: PersistenceManager) {
        self.apiClient = apiClient
        self.persistence = persistence
    }

    // MARK: - Cache Keys

    private static func tasksCacheKey(projectId: UUID) -> String {
        "cached_tasks_\(projectId.uuidString)"
    }

    private static func taskCacheKey(id: UUID) -> String {
        "task_\(id.uuidString)"
    }

    // MARK: - Read Operations

    public func fetchTasks(projectId: UUID) async throws -> [TaskItem] {
        let cacheKey = Self.tasksCacheKey(projectId: projectId)
        let cachedTasks: [TaskItem] = try await persistence.load(forKey: cacheKey)

        if !cachedTasks.isEmpty {
            Task {
                await backgroundRefreshTasks(projectId: projectId, cacheKey: cacheKey)
            }
            return cachedTasks
        }

        let endpoint = Endpoint(
            path: "/projects/\(projectId.uuidString)/tasks",
            method: .get
        )
        let tasks: [TaskItem] = try await apiClient.request(endpoint)
        try await persistence.save(tasks, forKey: cacheKey)
        return tasks
    }

    public func fetchTask(id: UUID) async throws -> TaskItem {
        let cacheKey = Self.taskCacheKey(id: id)
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

    // MARK: - Write Operations

    public func createTask(_ task: TaskItem) async throws -> TaskItem {
        let projectCacheKey = Self.tasksCacheKey(projectId: task.projectId)

        var cachedTasks: [TaskItem] = try await persistence.load(forKey: projectCacheKey)
        cachedTasks.append(task)
        try await persistence.save(cachedTasks, forKey: projectCacheKey)

        do {
            let body = try JSONEncoder().encode(task)
            let endpoint = Endpoint(
                path: "/projects/\(task.projectId.uuidString)/tasks",
                method: .post,
                body: body
            )
            let createdTask: TaskItem = try await apiClient.request(endpoint)

            cachedTasks = cachedTasks.filter { $0.id != task.id }
            cachedTasks.append(createdTask)
            try await persistence.save(cachedTasks, forKey: projectCacheKey)

            return createdTask
        } catch {
            let rolledBack = cachedTasks.filter { $0.id != task.id }
            try await persistence.save(rolledBack, forKey: projectCacheKey)
            AppLogger.error(
                "Create task failed, rolled back: \(error.localizedDescription)",
                category: .persistence
            )
            throw error
        }
    }

    public func updateTask(_ task: TaskItem) async throws -> TaskItem {
        let taskCacheKey = Self.taskCacheKey(id: task.id)
        let projectCacheKey = Self.tasksCacheKey(projectId: task.projectId)
        let previousTask: TaskItem? = try await persistence.loadOne(forKey: taskCacheKey)

        try await persistence.save(task, forKey: taskCacheKey)
        try await updateTaskInProjectCache(task, projectCacheKey: projectCacheKey)

        do {
            let body = try JSONEncoder().encode(task)
            let endpoint = Endpoint(
                path: "/tasks/\(task.id.uuidString)",
                method: .put,
                body: body
            )
            let updatedTask: TaskItem = try await apiClient.request(endpoint)
            try await persistence.save(updatedTask, forKey: taskCacheKey)
            return updatedTask
        } catch {
            if let previous = previousTask {
                try await persistence.save(previous, forKey: taskCacheKey)
                try await updateTaskInProjectCache(previous, projectCacheKey: projectCacheKey)
            }
            AppLogger.error(
                "Update task failed, rolled back: \(error.localizedDescription)",
                category: .persistence
            )
            throw error
        }
    }

    public func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem {
        let taskCacheKey = Self.taskCacheKey(id: id)

        guard var task: TaskItem = try await persistence.loadOne(forKey: taskCacheKey) else {
            let body = try JSONEncoder().encode(StatusUpdateRequest(status: status))
            let endpoint = Endpoint(
                path: "/tasks/\(id.uuidString)/status",
                method: .patch,
                body: body
            )
            let updatedTask: TaskItem = try await apiClient.request(endpoint)
            try await persistence.save(updatedTask, forKey: taskCacheKey)
            return updatedTask
        }

        let previousStatus = task.status
        task.status = status
        task.updatedAt = Date()

        let projectCacheKey = Self.tasksCacheKey(projectId: task.projectId)
        try await persistence.save(task, forKey: taskCacheKey)
        try await updateTaskInProjectCache(task, projectCacheKey: projectCacheKey)

        do {
            let body = try JSONEncoder().encode(StatusUpdateRequest(status: status))
            let endpoint = Endpoint(
                path: "/tasks/\(id.uuidString)/status",
                method: .patch,
                body: body
            )
            let updatedTask: TaskItem = try await apiClient.request(endpoint)
            try await persistence.save(updatedTask, forKey: taskCacheKey)
            return updatedTask
        } catch {
            task.status = previousStatus
            try await persistence.save(task, forKey: taskCacheKey)
            try await updateTaskInProjectCache(task, projectCacheKey: projectCacheKey)
            AppLogger.error(
                "Status update failed, rolled back: \(error.localizedDescription)",
                category: .persistence
            )
            throw error
        }
    }

    public func deleteTask(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "/tasks/\(id.uuidString)",
            method: .delete
        )
        try await apiClient.request(endpoint)
        try await persistence.remove(forKey: Self.taskCacheKey(id: id))
    }

    // MARK: - Private Helpers

    private func backgroundRefreshTasks(projectId: UUID, cacheKey: String) async {
        let endpoint = Endpoint(
            path: "/projects/\(projectId.uuidString)/tasks",
            method: .get
        )
        do {
            let tasks: [TaskItem] = try await apiClient.request(endpoint)
            try await persistence.save(tasks, forKey: cacheKey)
        } catch {
            AppLogger.warning(
                "Background refresh failed: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    private func updateTaskInProjectCache(_ task: TaskItem, projectCacheKey: String) async throws {
        var cachedTasks: [TaskItem] = try await persistence.load(forKey: projectCacheKey)
        if let index = cachedTasks.firstIndex(where: { $0.id == task.id }) {
            cachedTasks[index] = task
            try await persistence.save(cachedTasks, forKey: projectCacheKey)
        }
    }
}

// MARK: - Request DTOs

private struct StatusUpdateRequest: Encodable {
    let status: TaskStatus
}
