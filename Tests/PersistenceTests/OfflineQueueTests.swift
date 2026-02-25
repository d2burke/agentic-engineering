import XCTest
@testable import Persistence

final class OfflineQueueTests: XCTestCase {
    private var queue: OfflineQueue!

    override func setUp() {
        super.setUp()
        queue = OfflineQueue()
    }

    override func tearDown() {
        queue = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeOperation(
        type: OperationType = .create,
        entityType: String = "TaskItem",
        maxRetries: Int = 3
    ) -> OfflineOperation {
        OfflineOperation(
            id: UUID(),
            type: type,
            entityType: entityType,
            entityId: UUID(),
            payload: "{\"test\": true}".data(using: .utf8),
            createdAt: Date(),
            retryCount: 0,
            maxRetries: maxRetries
        )
    }

    // MARK: - FIFO Order Tests

    func testEnqueueAndDequeueMaintainsFIFOOrder() async {
        // Arrange
        let op1 = makeOperation(entityType: "First")
        let op2 = makeOperation(entityType: "Second")
        let op3 = makeOperation(entityType: "Third")

        // Act
        await queue.enqueue(op1)
        await queue.enqueue(op2)
        await queue.enqueue(op3)

        // Assert
        let dequeued1 = await queue.dequeue()
        let dequeued2 = await queue.dequeue()
        let dequeued3 = await queue.dequeue()

        XCTAssertEqual(dequeued1?.id, op1.id)
        XCTAssertEqual(dequeued2?.id, op2.id)
        XCTAssertEqual(dequeued3?.id, op3.id)
    }

    func testDequeueFromEmptyQueueReturnsNil() async {
        let result = await queue.dequeue()
        XCTAssertNil(result)
    }

    func testPeekReturnsFirstWithoutRemoving() async {
        // Arrange
        let op = makeOperation()
        await queue.enqueue(op)

        // Act
        let peeked = await queue.peek()

        // Assert
        XCTAssertEqual(peeked?.id, op.id)
        let count = await queue.count
        XCTAssertEqual(count, 1, "Peek should not remove the operation")
    }

    func testPeekOnEmptyQueueReturnsNil() async {
        let result = await queue.peek()
        XCTAssertNil(result)
    }

    // MARK: - Mark Completed Tests

    func testMarkCompletedRemovesOperation() async {
        // Arrange
        let op1 = makeOperation(entityType: "First")
        let op2 = makeOperation(entityType: "Second")
        await queue.enqueue(op1)
        await queue.enqueue(op2)

        // Act
        await queue.markCompleted(id: op1.id)

        // Assert
        let count = await queue.count
        XCTAssertEqual(count, 1)

        let remaining = await queue.pendingOperations
        XCTAssertEqual(remaining.first?.id, op2.id)
    }

    func testMarkCompletedWithUnknownIdDoesNothing() async {
        // Arrange
        let op = makeOperation()
        await queue.enqueue(op)

        // Act
        await queue.markCompleted(id: UUID())

        // Assert
        let count = await queue.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - Mark Failed Tests

    func testMarkFailedIncrementsRetryCount() async {
        // Arrange
        let op = makeOperation(maxRetries: 3)
        await queue.enqueue(op)

        // Act
        await queue.markFailed(id: op.id)

        // Assert
        let pending = await queue.pendingOperations
        XCTAssertEqual(pending.first?.retryCount, 1)
        let count = await queue.count
        XCTAssertEqual(count, 1, "Operation should still be in queue after first failure")
    }

    func testMarkFailedRemovesOperationWhenMaxRetriesExceeded() async {
        // Arrange: operation with maxRetries = 2
        let op = makeOperation(maxRetries: 2)
        await queue.enqueue(op)

        // Act: fail twice (reaching maxRetries)
        await queue.markFailed(id: op.id)
        await queue.markFailed(id: op.id)

        // Assert
        let count = await queue.count
        XCTAssertEqual(count, 0, "Operation should be removed after exceeding max retries")
    }

    func testMarkFailedDoesNotRemoveBeforeMaxRetries() async {
        // Arrange: operation with maxRetries = 3
        let op = makeOperation(maxRetries: 3)
        await queue.enqueue(op)

        // Act: fail twice (below maxRetries)
        await queue.markFailed(id: op.id)
        await queue.markFailed(id: op.id)

        // Assert
        let count = await queue.count
        XCTAssertEqual(count, 1, "Operation should remain in queue before max retries")

        let pending = await queue.pendingOperations
        XCTAssertEqual(pending.first?.retryCount, 2)
    }

    func testMarkFailedThirdTimeRemovesWithMaxRetries3() async {
        // Arrange
        let op = makeOperation(maxRetries: 3)
        await queue.enqueue(op)

        // Act: fail 3 times (reaching maxRetries)
        await queue.markFailed(id: op.id)
        await queue.markFailed(id: op.id)
        await queue.markFailed(id: op.id)

        // Assert
        let count = await queue.count
        XCTAssertEqual(count, 0, "Operation should be removed after reaching max retries")
    }

    // MARK: - Count and Pending Operations

    func testCountReflectsQueueSize() async {
        let count0 = await queue.count
        XCTAssertEqual(count0, 0)

        await queue.enqueue(makeOperation())
        let count1 = await queue.count
        XCTAssertEqual(count1, 1)

        await queue.enqueue(makeOperation())
        let count2 = await queue.count
        XCTAssertEqual(count2, 2)
    }

    func testPendingOperationsReturnsAllInOrder() async {
        // Arrange
        let op1 = makeOperation(entityType: "A")
        let op2 = makeOperation(entityType: "B")
        let op3 = makeOperation(entityType: "C")

        await queue.enqueue(op1)
        await queue.enqueue(op2)
        await queue.enqueue(op3)

        // Act
        let pending = await queue.pendingOperations

        // Assert
        XCTAssertEqual(pending.count, 3)
        XCTAssertEqual(pending[0].id, op1.id)
        XCTAssertEqual(pending[1].id, op2.id)
        XCTAssertEqual(pending[2].id, op3.id)
    }

    func testMarkFailedWithUnknownIdDoesNothing() async {
        // Arrange
        let op = makeOperation()
        await queue.enqueue(op)

        // Act
        await queue.markFailed(id: UUID())

        // Assert
        let pending = await queue.pendingOperations
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.retryCount, 0, "Original operation should be unchanged")
    }

    func testMaxRetriesOfOneRemovesAfterFirstFailure() async {
        // Arrange
        let op = makeOperation(maxRetries: 1)
        await queue.enqueue(op)

        // Act
        await queue.markFailed(id: op.id)

        // Assert
        let count = await queue.count
        XCTAssertEqual(count, 0, "Operation with maxRetries=1 should be removed after first failure")
    }
}
