import Foundation
import Common

/// A FIFO queue for offline operations awaiting synchronization.
///
/// Operations are enqueued when mutations occur while the device is offline.
/// When connectivity is restored, the `SyncEngine` drains this queue by
/// dequeuing and executing each operation in order.
///
/// Failed operations have their retry count incremented. If an operation
/// exceeds its maximum retry count, it is permanently removed from the queue.
public actor OfflineQueue {
    /// The ordered list of pending offline operations.
    private var operations: [OfflineOperation] = []

    /// Creates a new empty offline queue.
    public init() {}

    /// Adds an operation to the end of the queue.
    ///
    /// - Parameter operation: The offline operation to enqueue.
    public func enqueue(_ operation: OfflineOperation) {
        operations.append(operation)
        AppLogger.debug(
            "Enqueued \(operation.type.rawValue) operation for \(operation.entityType) [\(operation.id.uuidString)]",
            category: .sync
        )
    }

    /// Removes and returns the first operation in the queue.
    ///
    /// - Returns: The next pending operation, or `nil` if the queue is empty.
    public func dequeue() -> OfflineOperation? {
        guard !operations.isEmpty else { return nil }
        let operation = operations.removeFirst()
        AppLogger.debug(
            "Dequeued \(operation.type.rawValue) operation for \(operation.entityType) [\(operation.id.uuidString)]",
            category: .sync
        )
        return operation
    }

    /// Returns the first operation without removing it.
    ///
    /// - Returns: The next pending operation, or `nil` if the queue is empty.
    public func peek() -> OfflineOperation? {
        operations.first
    }

    /// Removes a successfully completed operation from the queue.
    ///
    /// - Parameter id: The unique identifier of the completed operation.
    public func markCompleted(id: UUID) {
        operations.removeAll { $0.id == id }
        AppLogger.debug("Marked operation \(id.uuidString) as completed", category: .sync)
    }

    /// Marks an operation as failed by incrementing its retry count.
    ///
    /// If the operation has exceeded its maximum retry count, it is permanently
    /// removed from the queue. Otherwise, it remains in place for a future retry.
    ///
    /// - Parameter id: The unique identifier of the failed operation.
    public func markFailed(id: UUID) {
        guard let index = operations.firstIndex(where: { $0.id == id }) else {
            return
        }

        operations[index].retryCount += 1

        if operations[index].retryCount >= operations[index].maxRetries {
            let removed = operations.remove(at: index)
            AppLogger.warning(
                "Operation \(removed.id.uuidString) exceeded max retries (\(removed.maxRetries)) and was removed",
                category: .sync
            )
        } else {
            AppLogger.debug(
                "Operation \(id.uuidString) retry count: \(operations[index].retryCount)/\(operations[index].maxRetries)",
                category: .sync
            )
        }
    }

    /// All pending operations in FIFO order.
    public var pendingOperations: [OfflineOperation] {
        operations
    }

    /// The number of operations currently in the queue.
    public var count: Int {
        operations.count
    }
}
