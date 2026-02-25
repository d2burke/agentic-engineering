import XCTest
import Foundation
@testable import TaskBoard
import Models
import Common
import TestSupport

// MARK: - MockTaskRepository

/// A mock task repository for task board view model tests.
private final class MockTaskRepository: TaskRepositoryProtocol, @unchecked Sendable {
    var fetchTasksResult: Result<[TaskItem], Error> = .success([])
    var fetchTaskResult: Result<TaskItem, Error> = .failure(AppError.notFound)
    var createTaskResult: Result<TaskItem, Error> = .failure(AppError.notFound)
    var updateTaskResult: Result<TaskItem, Error> = .failure(AppError.notFound)
    var updateTaskStatusResult: Result<TaskItem, Error> = .failure(AppError.notFound)
    var deleteTaskError: Error?

    var fetchTasksCallCount = 0
    var updateTaskStatusCallCount = 0
    var lastStatusUpdate: (id: UUID, status: TaskStatus)?

    func fetchTasks(projectId: UUID) async throws -> [TaskItem] {
        fetchTasksCallCount += 1
        return try fetchTasksResult.get()
    }

    func fetchTask(id: UUID) async throws -> TaskItem {
        return try fetchTaskResult.get()
    }

    func createTask(_ task: TaskItem) async throws -> TaskItem {
        return try createTaskResult.get()
    }

    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        return try updateTaskResult.get()
    }

    func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> TaskItem {
        updateTaskStatusCallCount += 1
        lastStatusUpdate = (id, status)
        return try updateTaskStatusResult.get()
    }

    func deleteTask(id: UUID) async throws {
        if let error = deleteTaskError {
            throw error
        }
    }
}

// MARK: - TaskBoardViewModelTests

@MainActor
final class TaskBoardViewModelTests: XCTestCase {

    private var mockRepo: MockTaskRepository!
    private var mockTracker: MockInteractionTracker!
    private var viewModel: TaskBoardViewModel!

    override func setUp() async throws {
        mockRepo = MockTaskRepository()
        mockTracker = MockInteractionTracker()
        viewModel = TaskBoardViewModel(
            repository: mockRepo,
            interactionTracker: mockTracker
        )
    }

    // MARK: - Load Tasks

    func testLoadTasksGroupsByStatusIntoColumns() async {
        let projectId = Fixtures.projectId
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "Task 1", status: .todo, projectId: projectId),
            Fixtures.taskItem(id: UUID(), title: "Task 2", status: .inProgress, projectId: projectId),
            Fixtures.taskItem(id: UUID(), title: "Task 3", status: .todo, projectId: projectId),
            Fixtures.taskItem(id: UUID(), title: "Task 4", status: .done, projectId: projectId)
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        await viewModel.loadTasks(projectId: projectId)

        XCTAssertEqual(viewModel.allTasks.count, 4)
        XCTAssertEqual(viewModel.columns.count, 4) // todo, inProgress, inReview, done

        let todoColumn = viewModel.columns.first { $0.status == .todo }
        XCTAssertEqual(todoColumn?.tasks.count, 2)

        let inProgressColumn = viewModel.columns.first { $0.status == .inProgress }
        XCTAssertEqual(inProgressColumn?.tasks.count, 1)

        let inReviewColumn = viewModel.columns.first { $0.status == .inReview }
        XCTAssertEqual(inReviewColumn?.tasks.count, 0)

        let doneColumn = viewModel.columns.first { $0.status == .done }
        XCTAssertEqual(doneColumn?.tasks.count, 1)
    }

    func testLoadTasksEmitsBoardViewEvent() async {
        mockRepo.fetchTasksResult = .success([Fixtures.taskItem()])

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        let events = await mockTracker.trackedEvents
        let viewEvents = events.filter { $0.metadata["action"] == "board_view" }
        XCTAssertEqual(viewEvents.count, 1)
        XCTAssertEqual(viewEvents.first?.screen, "TaskBoard")
    }

    func testLoadTasksSetsErrorOnFailure() async {
        mockRepo.fetchTasksResult = .failure(AppError.network("Failed"))

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.allTasks.isEmpty)
    }

    // MARK: - Move Task

    func testMoveTaskUpdatesStatusAndEmitsEvent() async {
        let taskId = UUID()
        let task = Fixtures.taskItem(id: taskId, status: .todo)
        let updatedTask = Fixtures.taskItem(id: taskId, status: .inProgress)
        mockRepo.fetchTasksResult = .success([task])
        mockRepo.updateTaskStatusResult = .success(updatedTask)

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        await viewModel.moveTask(taskId: taskId, toStatus: .inProgress)

        let movedTask = viewModel.allTasks.first { $0.id == taskId }
        XCTAssertEqual(movedTask?.status, .inProgress)

        let events = await mockTracker.trackedEvents
        let moveEvents = events.filter { $0.metadata["action"] == "task_move" }
        XCTAssertEqual(moveEvents.count, 1)
        XCTAssertEqual(moveEvents.first?.metadata["from_status"], "todo")
        XCTAssertEqual(moveEvents.first?.metadata["to_status"], "inProgress")
        XCTAssertEqual(moveEvents.first?.metadata["task_id"], taskId.uuidString)
    }

    func testMoveTaskDoesNothingForSameStatus() async {
        let taskId = UUID()
        let task = Fixtures.taskItem(id: taskId, status: .todo)
        mockRepo.fetchTasksResult = .success([task])

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        await viewModel.moveTask(taskId: taskId, toStatus: .todo)

        let events = await mockTracker.trackedEvents
        let moveEvents = events.filter { $0.metadata["action"] == "task_move" }
        XCTAssertEqual(moveEvents.count, 0)
    }

    func testMoveTaskRollsBackOnError() async {
        let taskId = UUID()
        let task = Fixtures.taskItem(id: taskId, status: .todo)
        mockRepo.fetchTasksResult = .success([task])
        mockRepo.updateTaskStatusResult = .failure(AppError.network("Failed"))

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        await viewModel.moveTask(taskId: taskId, toStatus: .inProgress)

        let rolledBackTask = viewModel.allTasks.first { $0.id == taskId }
        XCTAssertEqual(rolledBackTask?.status, .todo)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Filters

    func testApplyFilterNarrowsResults() async {
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "High", status: .todo, priority: .high),
            Fixtures.taskItem(id: UUID(), title: "Low", status: .todo, priority: .low),
            Fixtures.taskItem(id: UUID(), title: "Medium", status: .todo, priority: .medium)
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        viewModel.applyFilter(.priority(.high))

        let filtered = viewModel.filteredTasks(for: .todo)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "High")
    }

    func testRemoveFilterExpandsResults() async {
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "High", status: .todo, priority: .high),
            Fixtures.taskItem(id: UUID(), title: "Low", status: .todo, priority: .low)
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        viewModel.applyFilter(.priority(.high))
        XCTAssertEqual(viewModel.filteredTasks(for: .todo).count, 1)

        viewModel.removeFilter(.priority(.high))
        XCTAssertEqual(viewModel.filteredTasks(for: .todo).count, 2)
    }

    func testClearFiltersRemovesAllFilters() async {
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "Tagged", status: .todo, priority: .high, tags: ["bug"])
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        viewModel.applyFilter(.priority(.low))
        viewModel.applyFilter(.label("feature"))
        XCTAssertEqual(viewModel.activeFilters.count, 2)

        viewModel.clearFilters()
        XCTAssertTrue(viewModel.activeFilters.isEmpty)
    }

    func testClearFiltersEmitsEvent() async {
        mockRepo.fetchTasksResult = .success([])

        await viewModel.loadTasks(projectId: Fixtures.projectId)
        viewModel.applyFilter(.priority(.high))
        viewModel.clearFilters()

        // Wait briefly for the Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        let events = await mockTracker.trackedEvents
        let clearEvents = events.filter { $0.metadata["action"] == "filter_cleared" }
        XCTAssertEqual(clearEvents.count, 1)
    }

    // MARK: - Filtered Tasks

    func testFilteredTasksReturnsCorrectSubset() async {
        let assigneeId = UUID()
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "Assigned", status: .inProgress, assigneeId: assigneeId),
            Fixtures.taskItem(id: UUID(), title: "Unassigned", status: .inProgress, assigneeId: nil)
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        viewModel.applyFilter(.assignee(assigneeId))

        let filtered = viewModel.filteredTasks(for: .inProgress)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Assigned")
    }

    func testSearchTextFiltersTasksByTitle() async {
        let tasks = [
            Fixtures.taskItem(id: UUID(), title: "Fix login bug", status: .todo),
            Fixtures.taskItem(id: UUID(), title: "Add dark mode", status: .todo),
            Fixtures.taskItem(id: UUID(), title: "Update docs", status: .todo)
        ]
        mockRepo.fetchTasksResult = .success(tasks)

        await viewModel.loadTasks(projectId: Fixtures.projectId)

        viewModel.searchText = "login"
        let filtered = viewModel.filteredTasks(for: .todo)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Fix login bug")
    }
}
