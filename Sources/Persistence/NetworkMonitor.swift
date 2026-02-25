import Foundation
import Network
import Common

/// Protocol for monitoring network connectivity status.
///
/// Provides both a synchronous snapshot of the current state and an
/// asynchronous stream for observing changes over time.
public protocol NetworkMonitorProtocol: Sendable {
    /// Whether the device currently has network connectivity.
    var isConnected: Bool { get }

    /// An asynchronous stream that emits `true` when connectivity is gained
    /// and `false` when connectivity is lost.
    var connectionStream: AsyncStream<Bool> { get }
}

/// Monitors network connectivity using Apple's Network framework (`NWPathMonitor`).
///
/// This class starts monitoring on initialization and publishes connectivity
/// changes via an `AsyncStream<Bool>`. Consumers can observe the stream to
/// trigger sync operations when connectivity is restored.
public final class NetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    /// The underlying NWPathMonitor from the Network framework.
    private let monitor: NWPathMonitor

    /// The dispatch queue on which path updates are delivered.
    private let monitorQueue: DispatchQueue

    /// Thread-safe storage for the current connectivity state.
    private let _isConnected: ManagedAtomic<Bool>

    /// The continuation used to push connectivity changes into the async stream.
    private let streamContinuation: AsyncStream<Bool>.Continuation

    /// The async stream of connectivity change events.
    public let connectionStream: AsyncStream<Bool>

    /// Whether the device currently has network connectivity.
    public var isConnected: Bool {
        _isConnected.value
    }

    /// Creates and starts a new network monitor.
    ///
    /// Monitoring begins immediately on a background dispatch queue.
    /// The initial connectivity state is determined by the first path update.
    public init() {
        self.monitor = NWPathMonitor()
        self.monitorQueue = DispatchQueue(label: "com.taskmanager.networkmonitor", qos: .utility)
        self._isConnected = ManagedAtomic(false)

        var continuation: AsyncStream<Bool>.Continuation!
        self.connectionStream = AsyncStream<Bool> { cont in
            continuation = cont
        }
        self.streamContinuation = continuation

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            let previousValue = self._isConnected.exchange(connected)

            if connected != previousValue {
                AppLogger.info(
                    "Network connectivity changed: \(connected ? "connected" : "disconnected")",
                    category: .network
                )
                self.streamContinuation.yield(connected)
            }
        }

        monitor.start(queue: monitorQueue)
        AppLogger.info("Network monitor started", category: .network)
    }

    deinit {
        monitor.cancel()
        streamContinuation.finish()
    }
}

// MARK: - Lock-Free Atomic Boolean

/// A simple thread-safe boolean wrapper using an `NSLock` for
/// lightweight synchronization. Used internally by `NetworkMonitor`
/// to avoid data races on the connectivity flag.
///
/// Note: In a production codebase targeting iOS 17+, this could use
/// `Synchronization.Atomic<Bool>`. We use a lock-based approach for
/// broader compatibility and to avoid requiring the Synchronization framework.
final class ManagedAtomic<Value: Sendable>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    /// The current value, read under the lock.
    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    /// Creates a new atomic wrapper with the given initial value.
    init(_ initialValue: Value) {
        self._value = initialValue
    }

    /// Atomically replaces the current value and returns the previous value.
    @discardableResult
    func exchange(_ newValue: Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        let old = _value
        _value = newValue
        return old
    }
}
