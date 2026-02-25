import XCTest
import Foundation
@testable import TaskBoard
import Models
import Common
import TestSupport

// MARK: - MockTaskRepositoryForTests

/// A mock task repository for testing repository behavior.
private final class MockTaskRepositoryForTests: TaskRepositoryProtocol, @unchecked Sendable {
    var fetchTasksResult: Result<[TaskItem], Error> = .success([])
    var updateTaskStatusResult: Result<TaskItem, Error> = .failure(AppError.notFound)

    var fetchTasksCallCount = 0
    var updateTaskStatusCallCount = 0
    var lastStatusUpdate: (id: UUID, status: TaskStatus)?

    func fetchTasks(projectId: UUID) async throws -> [TaskItem] {
        fetchTasksCallCount += 1
        return try fetchTasksResult.get()
    }

    func fetchTask(id: UUID) async throws -> TaskItem {
        throw AppError.notFound
    }

    func createTask(_ task: TaskItem) async throws -> TaskItem {
        task
    }

    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        task
    }

    func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem {
        updateTaskStatusCallCount += 1
        lastStatusUpdate = (id, status)
        return try updateTaskStatusResult.get()
    }

    func deleteTask(id: UUID) async throws {
        // no-op
    }
}

// MARK: - TaskRepositoryTests

final class TaskRepositoryTests: XCTestCase {

    func testFetchTasksReturnsData() async throws {
        let mockRepo = MockTaskRepositoryForTests()
        let projectId = Fixtures.projectId
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "Task A", projectId: projectId),
            Fixtures.taskItem(id: UUID(), title: "Task B", projectId: projectId)
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        let fetched = try await mockRepo.fetchTasks(projectId: projectId)

        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched[0].title, "Task A")
        XCTAssertEqual(fetched[1].title, "Task B")
        XCTAssertEqual(mockRepo.fetchTasksCallCount, 1)
    }

    func testFetchTasksPropagatesError() async {
        let mockRepo = MockTaskRepositoryForTests()
        mockRepo.fetchTasksResult = .failure(AppError.network("Connection failed"))

        do {
            _ = try await mockRepo.fetchTasks(projectId: Fixtures.projectId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    func testUpdateTaskStatusTracksUpdate() async throws {
        let mockRepo = MockTaskRepositoryForTests()
        let taskId = Fixtures.taskId
        let updatedTask = Fixtures.taskItem(id: taskId, status: .inProgress)
        mockRepo.updateTaskStatusResult = .success(updatedTask)

        let result = try await mockRepo.updateTaskStatus(id: taskId, status: .inProgress)

        XCTAssertEqual(result.status, .inProgress)
        XCTAssertEqual(mockRepo.updateTaskStatusCallCount, 1)
        XCTAssertEqual(mockRepo.lastStatusUpdate?.id, taskId)
        XCTAssertEqual(mockRepo.lastStatusUpdate?.status, .inProgress)
    }

    func testUpdateTaskStatusPropagatesError() async {
        let mockRepo = MockTaskRepositoryForTests()
        mockRepo.updateTaskStatusResult = .failure(AppError.network("Network failure"))

        do {
            _ = try await mockRepo.updateTaskStatus(id: Fixtures.taskId, status: .done)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    func testFetchTasksMultipleCalls() async throws {
        let mockRepo = MockTaskRepositoryForTests()
        mockRepo.fetchTasksResult = .success([Fixtures.taskItem()])

        _ = try await mockRepo.fetchTasks(projectId: Fixtures.projectId)
        _ = try await mockRepo.fetchTasks(projectId: Fixtures.projectId)
        _ = try await mockRepo.fetchTasks(projectId: Fixtures.projectId)

        XCTAssertEqual(mockRepo.fetchTasksCallCount, 3)
    }
}
