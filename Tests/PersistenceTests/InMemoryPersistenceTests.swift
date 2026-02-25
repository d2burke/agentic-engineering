import XCTest
@testable import Persistence
import Models

final class InMemoryPersistenceTests: XCTestCase {
    private var manager: InMemoryPersistenceManager!

    override func setUp() {
        super.setUp()
        manager = InMemoryPersistenceManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Test Model

    /// A lightweight Codable model used exclusively in these tests.
    struct TestEntity: Codable, Identifiable, Equatable {
        let id: UUID
        let name: String
        let value: Int

        init(id: UUID = UUID(), name: String, value: Int) {
            self.id = id
            self.name = name
            self.value = value
        }
    }

    // MARK: - Save and Fetch Round-Trip

    func testSaveAndFetchRoundTrip() async throws {
        // Arrange
        let entity = TestEntity(name: "Test Item", value: 42)

        // Act
        try await manager.save(entity)
        let fetched = try await manager.fetch(TestEntity.self, id: entity.id)

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, entity.id)
        XCTAssertEqual(fetched?.name, entity.name)
        XCTAssertEqual(fetched?.value, entity.value)
    }

    func testSaveOverwritesExistingEntity() async throws {
        // Arrange
        let id = UUID()
        let original = TestEntity(id: id, name: "Original", value: 1)
        let updated = TestEntity(id: id, name: "Updated", value: 2)

        // Act
        try await manager.save(original)
        try await manager.save(updated)
        let fetched = try await manager.fetch(TestEntity.self, id: id)

        // Assert
        XCTAssertEqual(fetched?.name, "Updated")
        XCTAssertEqual(fetched?.value, 2)
    }

    // MARK: - Fetch All

    func testFetchAllReturnsAllItems() async throws {
        // Arrange
        let entity1 = TestEntity(name: "Item 1", value: 10)
        let entity2 = TestEntity(name: "Item 2", value: 20)
        let entity3 = TestEntity(name: "Item 3", value: 30)

        try await manager.save(entity1)
        try await manager.save(entity2)
        try await manager.save(entity3)

        // Act
        let all = try await manager.fetchAll(TestEntity.self)

        // Assert
        XCTAssertEqual(all.count, 3)

        let ids = Set(all.map(\.id))
        XCTAssertTrue(ids.contains(entity1.id))
        XCTAssertTrue(ids.contains(entity2.id))
        XCTAssertTrue(ids.contains(entity3.id))
    }

    func testFetchAllReturnsEmptyArrayWhenNoItems() async throws {
        // Act
        let all = try await manager.fetchAll(TestEntity.self)

        // Assert
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Delete

    func testDeleteRemovesItem() async throws {
        // Arrange
        let entity = TestEntity(name: "To Delete", value: 99)
        try await manager.save(entity)

        // Act
        try await manager.delete(TestEntity.self, id: entity.id)
        let fetched = try await manager.fetch(TestEntity.self, id: entity.id)

        // Assert
        XCTAssertNil(fetched, "Deleted item should not be fetchable")
    }

    func testDeleteNonExistentItemDoesNotThrow() async throws {
        // Act & Assert: should complete without error
        try await manager.delete(TestEntity.self, id: UUID())
    }

    func testDeleteOnlyRemovesTargetItem() async throws {
        // Arrange
        let entity1 = TestEntity(name: "Keep", value: 1)
        let entity2 = TestEntity(name: "Delete", value: 2)

        try await manager.save(entity1)
        try await manager.save(entity2)

        // Act
        try await manager.delete(TestEntity.self, id: entity2.id)

        // Assert
        let all = try await manager.fetchAll(TestEntity.self)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, entity1.id)
    }

    // MARK: - Fetch Non-Existent

    func testFetchNonExistentReturnsNil() async throws {
        // Act
        let fetched = try await manager.fetch(TestEntity.self, id: UUID())

        // Assert
        XCTAssertNil(fetched, "Fetching a non-existent entity should return nil")
    }

    // MARK: - Type Isolation

    /// A second test entity type to verify type-level isolation in the store.
    struct OtherEntity: Codable, Identifiable, Equatable {
        let id: UUID
        let label: String

        init(id: UUID = UUID(), label: String) {
            self.id = id
            self.label = label
        }
    }

    func testDifferentTypesAreIsolated() async throws {
        // Arrange
        let testEntity = TestEntity(name: "Test", value: 1)
        let otherEntity = OtherEntity(label: "Other")

        // Act
        try await manager.save(testEntity)
        try await manager.save(otherEntity)

        // Assert
        let allTests = try await manager.fetchAll(TestEntity.self)
        let allOthers = try await manager.fetchAll(OtherEntity.self)

        XCTAssertEqual(allTests.count, 1)
        XCTAssertEqual(allOthers.count, 1)
        XCTAssertEqual(allTests.first?.name, "Test")
        XCTAssertEqual(allOthers.first?.label, "Other")
    }

    // MARK: - Real Model Tests

    func testSaveAndFetchUser() async throws {
        // Arrange
        let user = User(
            email: "test@example.com",
            displayName: "Test User"
        )

        // Act
        try await manager.save(user)
        let fetched = try await manager.fetch(User.self, id: user.id)

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.email, "test@example.com")
        XCTAssertEqual(fetched?.displayName, "Test User")
    }

    func testSaveAndFetchProject() async throws {
        // Arrange
        let project = Project(
            name: "Test Project",
            projectDescription: "A test project",
            ownerId: UUID()
        )

        // Act
        try await manager.save(project)
        let fetched = try await manager.fetch(Project.self, id: project.id)

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Test Project")
        XCTAssertEqual(fetched?.projectDescription, "A test project")
    }
}
