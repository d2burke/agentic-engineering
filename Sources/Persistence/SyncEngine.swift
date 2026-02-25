import Foundation
import Common

/// Protocol for handling the execution of a single offline operation.
///
/// Implementations bridge the persistence layer to the networking layer
/// without creating a direct dependency between the two modules.
/// The concrete implementation (provided at the app composition layer)
/// translates each `OfflineOperation` into the appropriate API call.
public protocol SyncHandler: Sendable {
    /// Executes a single offline operation against the remote server.
    ///
    /// - Parameter operation: The offline operation to execute.
    /// - Throws: An error if the remote operation fails.
    func execute(_ operation: OfflineOperation) async throws
}

/// Protocol defining the contract for a synchronization engine that
/// drains the offline queue when connectivity is available.
public protocol SyncEngineProtocol: Sendable {
    /// Attempts to synchronize all pending offline operations.
    ///
    /// Operations are processed in FIFO order. If an operation fails,
    /// its retry count is incremented and processing continues with the
    /// next operation.
    ///
    /// - Throws: An error if a critical sync failure occurs.
    func sync() async throws

    /// Enqueues a new operation for later synchronization.
    ///
    /// - Parameter operation: The offline operation to enqueue.
    func enqueueOffline(_ operation: OfflineOperation) async

    /// Whether the engine is currently executing a sync cycle.
    var isSyncing: Bool { get async }

    /// The number of operations awaiting synchronization.
    var pendingCount: Int { get async }
}

/// Coordinates the synchronization of offline operations with the remote server.
///
/// The `SyncEngine` actor processes the offline queue in FIFO order, delegating
/// each operation to a `SyncHandler`. It tracks syncing state and handles
/// failures gracefully by leveraging the queue's built-in retry mechanism.
public actor SyncEngine: SyncEngineProtocol {
    /// The queue of pending offline operations.
    private let queue: OfflineQueue

    /// The handler responsible for executing individual operations.
    private let handler: SyncHandler

    /// Whether a sync cycle is currently in progress.
    private var _isSyncing: Bool = false

    /// Creates a new sync engine.
    ///
    /// - Parameters:
    ///   - queue: The offline operation queue to drain.
    ///   - handler: The handler that executes each operation remotely.
    public init(queue: OfflineQueue, handler: SyncHandler) {
        self.queue = queue
        self.handler = handler
    }

    public var isSyncing: Bool {
        _isSyncing
    }

    public var pendingCount: Int {
        get async {
            await queue.count
        }
    }

    public func enqueueOffline(_ operation: OfflineOperation) async {
        await queue.enqueue(operation)
    }

    /// Drains the offline queue, executing each operation in FIFO order.
    ///
    /// Each operation is dequeued, executed via the handler, and marked as
    /// completed on success or failed on error. The sync cycle continues
    /// until the queue is empty.
    public func sync() async throws {
        guard !_isSyncing else {
            AppLogger.debug("Sync already in progress, skipping", category: .sync)
            return
        }

        _isSyncing = true
        defer { _isSyncing = false }

        let pending = await queue.pendingOperations
        AppLogger.info("Starting sync with \(pending.count) pending operations", category: .sync)

        for operation in pending {
            do {
                try await handler.execute(operation)
                await queue.markCompleted(id: operation.id)
                AppLogger.info(
                    "Synced \(operation.type.rawValue) for \(operation.entityType) [\(operation.entityId.uuidString)]",
                    category: .sync
                )
            } catch {
                await queue.markFailed(id: operation.id)
                AppLogger.error(
                    "Failed to sync \(operation.type.rawValue) for \(operation.entityType) [\(operation.entityId.uuidString)]: \(error.localizedDescription)",
                    category: .sync
                )
            }
        }

        let remaining = await queue.count
        AppLogger.info("Sync complete. \(remaining) operations remaining", category: .sync)
    }
}
