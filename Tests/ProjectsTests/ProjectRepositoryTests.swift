import XCTest
import Foundation
@testable import Projects
import Models
import Common
import TestSupport

// MARK: - MockProjectRepository

/// A mock project repository for testing view models.
final class MockProjectRepository: ProjectRepositoryProtocol, @unchecked Sendable {
    var fetchProjectsResult: Result<[Project], Error> = .success([])
    var fetchProjectResult: Result<Project, Error> = .failure(AppError.notFound)
    var createProjectResult: Result<Project, Error> = .failure(AppError.notFound)
    var updateProjectResult: Result<Project, Error> = .failure(AppError.notFound)
    var deleteProjectError: Error?

    var fetchProjectsCallCount = 0
    var deleteProjectCallCount = 0
    var lastDeletedProjectId: UUID?

    func fetchProjects() async throws -> [Project] {
        fetchProjectsCallCount += 1
        return try fetchProjectsResult.get()
    }

    func fetchProject(id: UUID) async throws -> Project {
        return try fetchProjectResult.get()
    }

    func createProject(name: String, description: String?) async throws -> Project {
        return try createProjectResult.get()
    }

    func updateProject(_ project: Project) async throws -> Project {
        return try updateProjectResult.get()
    }

    func deleteProject(id: UUID) async throws {
        deleteProjectCallCount += 1
        lastDeletedProjectId = id
        if let error = deleteProjectError {
            throw error
        }
    }
}

// MARK: - ProjectRepositoryTests

final class ProjectRepositoryTests: XCTestCase {

    func testFetchProjectsReturnsAPIData() async throws {
        let projects = [
            Fixtures.project(id: UUID(), name: "Project A"),
            Fixtures.project(id: UUID(), name: "Project B")
        ]

        let mockRepo = MockProjectRepository()
        mockRepo.fetchProjectsResult = .success(projects)

        let fetched = try await mockRepo.fetchProjects()
        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched[0].name, "Project A")
        XCTAssertEqual(fetched[1].name, "Project B")
    }

    func testCreateProjectReturnsNewProject() async throws {
        let newProject = Fixtures.project(name: "New Project")

        let mockRepo = MockProjectRepository()
        mockRepo.createProjectResult = .success(newProject)

        let created = try await mockRepo.createProject(name: "New Project", description: nil)
        XCTAssertEqual(created.name, "New Project")
    }

    func testFetchProjectsTracksCallCount() async throws {
        let mockRepo = MockProjectRepository()
        let projects = [Fixtures.project()]
        mockRepo.fetchProjectsResult = .success(projects)

        _ = try await mockRepo.fetchProjects()
        _ = try await mockRepo.fetchProjects()

        XCTAssertEqual(mockRepo.fetchProjectsCallCount, 2)
    }

    func testDeleteProjectCallsRepository() async throws {
        let mockRepo = MockProjectRepository()
        let projectId = UUID()

        try await mockRepo.deleteProject(id: projectId)

        XCTAssertEqual(mockRepo.deleteProjectCallCount, 1)
        XCTAssertEqual(mockRepo.lastDeletedProjectId, projectId)
    }

    func testDeleteProjectPropagatesError() async {
        let mockRepo = MockProjectRepository()
        mockRepo.deleteProjectError = AppError.network("Network error")

        do {
            try await mockRepo.deleteProject(id: UUID())
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
}
