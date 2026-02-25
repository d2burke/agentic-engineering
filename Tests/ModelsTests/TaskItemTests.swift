import XCTest
@testable import Models
import TestSupport

final class TaskItemTests: XCTestCase {

    // MARK: - Codable Round-Trip

    func testCodableRoundTrip() throws {
        let original = Fixtures.taskItem(
            dueDate: Date(timeIntervalSinceReferenceDate: 700_100_000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TaskItem.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.taskDescription, decoded.taskDescription)
        XCTAssertEqual(original.status, decoded.status)
        XCTAssertEqual(original.priority, decoded.priority)
        XCTAssertEqual(original.projectId, decoded.projectId)
        XCTAssertEqual(original.assigneeId, decoded.assigneeId)
        XCTAssertEqual(original.reporterId, decoded.reporterId)
        XCTAssertEqual(original.tags, decoded.tags)
        XCTAssertEqual(original.attachmentIds, decoded.attachmentIds)
        XCTAssertEqual(original.commentCount, decoded.commentCount)
    }

    func testCodableRoundTripWithNilOptionals() throws {
        let original = Fixtures.taskItem(
            taskDescription: nil,
            assigneeId: nil,
            dueDate: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TaskItem.self, from: data)

        XCTAssertNil(decoded.taskDescription)
        XCTAssertNil(decoded.assigneeId)
        XCTAssertNil(decoded.dueDate)
    }

    // MARK: - Equatable

    func testEqualTaskItemsAreEqual() {
        let id = UUID()
        let projectId = UUID()
        let reporterId = UUID()
        let date = Date()

        let a = TaskItem(
            id: id, title: "T", status: .todo, priority: .medium,
            projectId: projectId, reporterId: reporterId,
            createdAt: date, updatedAt: date
        )
        let b = TaskItem(
            id: id, title: "T", status: .todo, priority: .medium,
            projectId: projectId, reporterId: reporterId,
            createdAt: date, updatedAt: date
        )
        XCTAssertEqual(a, b)
    }

    func testDifferentTaskItemsAreNotEqual() {
        let a = Fixtures.taskItem(title: "Task A")
        let b = Fixtures.taskItem(title: "Task B")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Default Values

    func testDefaultStatus() {
        let task = Fixtures.taskItem()
        XCTAssertEqual(task.status, .todo)
    }

    func testDefaultPriority() {
        let task = Fixtures.taskItem()
        XCTAssertEqual(task.priority, .medium)
    }

    func testDefaultCommentCount() {
        let task = Fixtures.taskItem()
        XCTAssertEqual(task.commentCount, 0)
    }

    func testDefaultAttachmentIds() {
        let task = Fixtures.taskItem(attachmentIds: [])
        XCTAssertTrue(task.attachmentIds.isEmpty)
    }

    // MARK: - Identifiable

    func testIdentifiable() {
        let task = Fixtures.taskItem()
        XCTAssertEqual(task.id, Fixtures.taskId)
    }
}
