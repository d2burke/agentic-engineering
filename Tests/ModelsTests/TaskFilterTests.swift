import XCTest
@testable import Models
import TestSupport

final class TaskFilterTests: XCTestCase {

    // MARK: - Assignee Filter

    func testAssigneeFilterMatchesAssignedTask() {
        let userId = UUID()
        let task = Fixtures.taskItem(assigneeId: userId)
        let filter = TaskFilter.assignee(userId)
        XCTAssertTrue(filter.matches(task))
    }

    func testAssigneeFilterDoesNotMatchDifferentUser() {
        let task = Fixtures.taskItem(assigneeId: UUID())
        let filter = TaskFilter.assignee(UUID())
        XCTAssertFalse(filter.matches(task))
    }

    func testAssigneeFilterDoesNotMatchUnassignedTask() {
        let task = Fixtures.taskItem(assigneeId: nil)
        let filter = TaskFilter.assignee(UUID())
        XCTAssertFalse(filter.matches(task))
    }

    // MARK: - Priority Filter

    func testPriorityFilterMatchesMatchingPriority() {
        let task = Fixtures.taskItem(priority: .high)
        let filter = TaskFilter.priority(.high)
        XCTAssertTrue(filter.matches(task))
    }

    func testPriorityFilterDoesNotMatchDifferentPriority() {
        let task = Fixtures.taskItem(priority: .low)
        let filter = TaskFilter.priority(.critical)
        XCTAssertFalse(filter.matches(task))
    }

    // MARK: - Label (Tag) Filter

    func testLabelFilterMatchesTaskWithLabel() {
        let task = Fixtures.taskItem(tags: ["bug", "urgent"])
        let filter = TaskFilter.label("bug")
        XCTAssertTrue(filter.matches(task))
    }

    func testLabelFilterDoesNotMatchTaskWithoutLabel() {
        let task = Fixtures.taskItem(tags: ["feature"])
        let filter = TaskFilter.label("bug")
        XCTAssertFalse(filter.matches(task))
    }

    func testLabelFilterDoesNotMatchTaskWithEmptyLabels() {
        let task = Fixtures.taskItem(tags: [])
        let filter = TaskFilter.label("bug")
        XCTAssertFalse(filter.matches(task))
    }

    // MARK: - Status Filter

    func testStatusFilterMatchesMatchingStatus() {
        let task = Fixtures.taskItem(status: .inProgress)
        let filter = TaskFilter.status(.inProgress)
        XCTAssertTrue(filter.matches(task))
    }

    func testStatusFilterDoesNotMatchDifferentStatus() {
        let task = Fixtures.taskItem(status: .done)
        let filter = TaskFilter.status(.todo)
        XCTAssertFalse(filter.matches(task))
    }

    // MARK: - Due Date Filter

    func testDueDateFilterMatchesTaskWithinInterval() {
        let now = Date()
        let interval = DateInterval(
            start: now.addingTimeInterval(-86400),
            end: now.addingTimeInterval(86400)
        )
        let task = Fixtures.taskItem(dueDate: now)
        let filter = TaskFilter.dueDate(interval)
        XCTAssertTrue(filter.matches(task))
    }

    func testDueDateFilterDoesNotMatchTaskOutsideInterval() {
        let now = Date()
        let interval = DateInterval(
            start: now.addingTimeInterval(-86400),
            end: now.addingTimeInterval(-3600)
        )
        let task = Fixtures.taskItem(dueDate: now.addingTimeInterval(86400))
        let filter = TaskFilter.dueDate(interval)
        XCTAssertFalse(filter.matches(task))
    }

    func testDueDateFilterDoesNotMatchTaskWithNoDueDate() {
        let now = Date()
        let interval = DateInterval(
            start: now.addingTimeInterval(-86400),
            end: now.addingTimeInterval(86400)
        )
        let task = Fixtures.taskItem(dueDate: nil)
        let filter = TaskFilter.dueDate(interval)
        XCTAssertFalse(filter.matches(task))
    }

    // MARK: - Hashable

    func testHashableConformance() {
        let filter1 = TaskFilter.status(.todo)
        let filter2 = TaskFilter.status(.todo)
        let filter3 = TaskFilter.status(.done)

        var set = Set<TaskFilter>()
        set.insert(filter1)
        set.insert(filter2)
        XCTAssertEqual(set.count, 1, "Identical filters should hash to the same bucket")

        set.insert(filter3)
        XCTAssertEqual(set.count, 2, "Different filters should produce different hashes")
    }
}
