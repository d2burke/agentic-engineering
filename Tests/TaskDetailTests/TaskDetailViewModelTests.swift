import XCTest
import Foundation
@testable import TaskDetail
import Models
import Common
import TestSupport

// MARK: - MockTaskDetailRepository

/// A mock repository for task detail view model tests.
private final class MockTaskDetailRepository: TaskDetailRepositoryProtocol, @unchecked Sendable {
    var fetchTaskResult: Result<TaskItem, Error> = .failure(AppError.notFound)
    var updateTaskResult: Result<TaskItem, Error> = .failure(AppError.notFound)
    var updateTaskStatusResult: Result<TaskItem, Error> = .failure(AppError.notFound)

    var fetchTaskCallCount = 0
    var updateTaskCallCount = 0
    var updateStatusCallCount = 0
    var lastStatusUpdate: (id: UUID, status: TaskStatus)?

    func fetchTask(id: UUID) async throws -> TaskItem {
        fetchTaskCallCount += 1
        return try fetchTaskResult.get()
    }

    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        updateTaskCallCount += 1
        return try updateTaskResult.get()
    }

    func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem {
        updateStatusCallCount += 1
        lastStatusUpdate = (id, status)
        return try updateTaskStatusResult.get()
    }
}

// MARK: - TaskDetailViewModelTests

@MainActor
final class TaskDetailViewModelTests: XCTestCase {

    private var mockRepo: MockTaskDetailRepository!
    private var mockAPI: MockAPIClient!
    private var mockTracker: MockInteractionTracker!
    private var viewModel: TaskDetailViewModel!

    override func setUp() async throws {
        mockRepo = MockTaskDetailRepository()
        mockAPI = MockAPIClient()
        mockTracker = MockInteractionTracker()
        viewModel = TaskDetailViewModel(
            repository: mockRepo,
            apiClient: mockAPI,
            interactionTracker: mockTracker
        )
    }

    // MARK: - Load Task

    func testLoadTaskPopulatesTask() async {
        let task = Fixtures.taskItem(title: "Test Task")
        mockRepo.fetchTaskResult = .success(task)

        await viewModel.loadTask(id: task.id)

        XCTAssertNotNil(viewModel.task)
        XCTAssertEqual(viewModel.task?.title, "Test Task")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadTaskEmitsDetailViewEvent() async {
        let task = Fixtures.taskItem()
        mockRepo.fetchTaskResult = .success(task)

        await viewModel.loadTask(id: task.id)

        let events = await mockTracker.trackedEvents
        let viewEvents = events.filter { $0.metadata["action"] == "task_detail_view" }
        XCTAssertEqual(viewEvents.count, 1)
        XCTAssertEqual(viewEvents.first?.screen, "TaskDetail")
        XCTAssertEqual(viewEvents.first?.metadata["task_id"], task.id.uuidString)
    }

    func testLoadTaskSetsErrorOnFailure() async {
        mockRepo.fetchTaskResult = .failure(AppError.network("Failed to load"))

        await viewModel.loadTask(id: UUID())

        XCTAssertNil(viewModel.task)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Update Status

    func testUpdateStatusChangesTaskStatus() async {
        let task = Fixtures.taskItem(status: .todo)
        let updatedTask = Fixtures.taskItem(id: task.id, status: .inProgress)
        mockRepo.fetchTaskResult = .success(task)
        mockRepo.updateTaskStatusResult = .success(updatedTask)

        await viewModel.loadTask(id: task.id)

        await viewModel.updateStatus(.inProgress)

        XCTAssertEqual(viewModel.task?.status, .inProgress)
    }

    func testUpdateStatusEmitsStatusChangeEvent() async {
        let task = Fixtures.taskItem(status: .todo)
        let updatedTask = Fixtures.taskItem(id: task.id, status: .done)
        mockRepo.fetchTaskResult = .success(task)
        mockRepo.updateTaskStatusResult = .success(updatedTask)

        await viewModel.loadTask(id: task.id)
        await viewModel.updateStatus(.done)

        let events = await mockTracker.trackedEvents
        let statusEvents = events.filter { $0.metadata["action"] == "task_status_change" }
        XCTAssertEqual(statusEvents.count, 1)
        XCTAssertEqual(statusEvents.first?.metadata["from_status"], "todo")
        XCTAssertEqual(statusEvents.first?.metadata["to_status"], "done")
    }

    func testUpdateStatusSetsErrorOnFailure() async {
        let task = Fixtures.taskItem(status: .todo)
        mockRepo.fetchTaskResult = .success(task)
        mockRepo.updateTaskStatusResult = .failure(AppError.network("Failed"))

        await viewModel.loadTask(id: task.id)
        await viewModel.updateStatus(.inProgress)

        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Load Comments

    func testLoadCommentsPopulatesComments() async {
        let task = Fixtures.taskItem()
        mockRepo.fetchTaskResult = .success(task)

        let comments = [
            Fixtures.comment(id: UUID(), body: "First comment"),
            Fixtures.comment(id: UUID(), body: "Second comment")
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        mockAPI.requestHandler = { _ in
            try encoder.encode(comments)
        }

        await viewModel.loadTask(id: task.id)
        await viewModel.loadComments()

        XCTAssertEqual(viewModel.comments.count, 2)
    }

    func testLoadCommentsEmitsCommentViewEvent() async {
        let task = Fixtures.taskItem()
        mockRepo.fetchTaskResult = .success(task)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        mockAPI.requestHandler = { _ in
            try encoder.encode([Comment]())
        }

        await viewModel.loadTask(id: task.id)
        await viewModel.loadComments()

        let events = await mockTracker.trackedEvents
        let commentEvents = events.filter { $0.metadata["action"] == "comment_view" }
        XCTAssertEqual(commentEvents.count, 1)
    }

    // MARK: - Update Task

    func testUpdateTaskEmitsEditEvent() async {
        let task = Fixtures.taskItem(title: "Original")
        var updated = task
        updated.title = "Updated Title"
        mockRepo.fetchTaskResult = .success(task)
        mockRepo.updateTaskResult = .success(updated)

        await viewModel.loadTask(id: task.id)
        viewModel.isEditing = true

        await viewModel.updateTask(updated)

        XCTAssertFalse(viewModel.isEditing)

        let events = await mockTracker.trackedEvents
        let editEvents = events.filter { $0.metadata["action"] == "task_edit" }
        XCTAssertEqual(editEvents.count, 1)
    }
}
