import XCTest
import Foundation
@testable import Projects
import Models
import Common
import TestSupport

// MARK: - MockProjectRepositoryForVM

/// A mock project repository for view model tests.
private final class MockProjectRepositoryForVM: ProjectRepositoryProtocol, @unchecked Sendable {
    var fetchProjectsResult: Result<[Project], Error> = .success([])
    var deleteProjectError: Error?

    var fetchProjectsCallCount = 0
    var deleteProjectCallCount = 0
    var lastDeletedProjectId: UUID?

    func fetchProjects() async throws -> [Project] {
        fetchProjectsCallCount += 1
        return try fetchProjectsResult.get()
    }

    func fetchProject(id: UUID) async throws -> Project {
        throw AppError.notFound
    }

    func createProject(name: String, description: String?) async throws -> Project {
        Fixtures.project(name: name)
    }

    func updateProject(_ project: Project) async throws -> Project {
        project
    }

    func deleteProject(id: UUID) async throws {
        deleteProjectCallCount += 1
        lastDeletedProjectId = id
        if let error = deleteProjectError {
            throw error
        }
    }
}

// MARK: - ProjectListViewModelTests

@MainActor
final class ProjectListViewModelTests: XCTestCase {

    private var mockRepo: MockProjectRepositoryForVM!
    private var mockTracker: MockInteractionTracker!
    private var viewModel: ProjectListViewModel!

    override func setUp() async throws {
        mockRepo = MockProjectRepositoryForVM()
        mockTracker = MockInteractionTracker()
        viewModel = ProjectListViewModel(
            repository: mockRepo,
            interactionTracker: mockTracker
        )
    }

    // MARK: - Load Projects

    func testLoadProjectsPopulatesList() async {
        let projects = [
            Fixtures.project(id: UUID(), name: "Alpha"),
            Fixtures.project(id: UUID(), name: "Beta"),
            Fixtures.project(id: UUID(), name: "Gamma")
        ]
        mockRepo.fetchProjectsResult = .success(projects)

        await viewModel.loadProjects()

        XCTAssertEqual(viewModel.projects.count, 3)
        XCTAssertEqual(viewModel.projects[0].name, "Alpha")
        XCTAssertEqual(viewModel.projects[1].name, "Beta")
        XCTAssertEqual(viewModel.projects[2].name, "Gamma")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadProjectsEmitsViewEvent() async {
        mockRepo.fetchProjectsResult = .success([Fixtures.project()])

        await viewModel.loadProjects()

        let events = await mockTracker.trackedEvents
        let viewEvents = events.filter { $0.metadata["action"] == "project_list_view" }
        XCTAssertEqual(viewEvents.count, 1)
        XCTAssertEqual(viewEvents.first?.screen, "ProjectList")
    }

    func testLoadProjectsSetsErrorOnFailure() async {
        mockRepo.fetchProjectsResult = .failure(AppError.network("Connection failed"))

        await viewModel.loadProjects()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.projects.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Delete Project

    func testDeleteProjectRemovesFromList() async {
        let projectA = Fixtures.project(id: UUID(), name: "Alpha")
        let projectB = Fixtures.project(id: UUID(), name: "Beta")
        mockRepo.fetchProjectsResult = .success([projectA, projectB])

        await viewModel.loadProjects()
        XCTAssertEqual(viewModel.projects.count, 2)

        await viewModel.deleteProject(id: projectA.id)

        XCTAssertEqual(viewModel.projects.count, 1)
        XCTAssertEqual(viewModel.projects.first?.name, "Beta")
    }

    func testDeleteProjectEmitsDeleteEvent() async {
        let project = Fixtures.project()
        mockRepo.fetchProjectsResult = .success([project])

        await viewModel.loadProjects()
        await viewModel.deleteProject(id: project.id)

        let events = await mockTracker.trackedEvents
        let deleteEvents = events.filter { $0.metadata["action"] == "project_delete" }
        XCTAssertEqual(deleteEvents.count, 1)
        XCTAssertEqual(deleteEvents.first?.metadata["project_id"], project.id.uuidString)
    }

    func testDeleteProjectRestoresOnError() async {
        let project = Fixtures.project()
        mockRepo.fetchProjectsResult = .success([project])
        mockRepo.deleteProjectError = AppError.network("Failed")

        await viewModel.loadProjects()
        await viewModel.deleteProject(id: project.id)

        XCTAssertEqual(viewModel.projects.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Refresh

    func testRefreshEmitsRefreshEvent() async {
        mockRepo.fetchProjectsResult = .success([])

        await viewModel.refresh()

        let events = await mockTracker.trackedEvents
        let refreshEvents = events.filter { $0.metadata["action"] == "project_refresh" }
        XCTAssertEqual(refreshEvents.count, 1)
    }

    func testRefreshReloadsProjects() async {
        mockRepo.fetchProjectsResult = .success([])

        await viewModel.refresh()

        XCTAssertEqual(mockRepo.fetchProjectsCallCount, 1)
    }
}
