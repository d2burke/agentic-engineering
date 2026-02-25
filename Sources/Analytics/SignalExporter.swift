import Foundation
import Common

// MARK: - SignalExporter

/// Exports detected `ExceptionalSignal`s to an external sink
/// (console, file, remote service, etc.).
///
/// Exporters are registered with the `InteractionTracker` and called
/// whenever new signals are detected. Implementations must be `Sendable`
/// for safe use across concurrency domains.
public protocol SignalExporter: Sendable {
    /// Export a batch of signals to the destination.
    func export(_ signals: [ExceptionalSignal]) async throws

    /// Flush any buffered data, ensuring all previously exported
    /// signals have been persisted to the destination.
    func flush() async throws
}

// MARK: - ConsoleSignalExporter

/// Logs detected signals to the unified system log via `AppLogger`.
///
/// Useful for development diagnostics and debugging the detection pipeline.
public final class ConsoleSignalExporter: SignalExporter {
    public init() {}

    public func export(_ signals: [ExceptionalSignal]) async throws {
        for signal in signals {
            let eventIds = signal.triggeringEvents.map { $0.uuidString.prefix(8) }.joined(separator: ", ")
            let message = "[\(signal.severity.rawValue.uppercased())] "
                + "\(signal.type.rawValue) on \(signal.screen): "
                + "\(signal.description) "
                + "(triggers: \(eventIds))"
            AppLogger.info(message, category: .analytics)
        }
    }

    public func flush() async throws {
        // Console output is unbuffered; nothing to flush.
    }
}

// MARK: - FileSignalExporter

/// Writes detected signals as newline-delimited JSON (JSONL) to a file.
///
/// Designed as an `actor` to guarantee serialized file access without
/// external locking.
public actor FileSignalExporter: SignalExporter {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private var buffer: [Data]
    private var fileHandle: FileHandle?

    /// Creates a new exporter that writes to the given file URL.
    ///
    /// - Parameter fileURL: The destination file. Created if it does not exist.
    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = .sortedKeys
        self.buffer = []
    }

    public func export(_ signals: [ExceptionalSignal]) async throws {
        for signal in signals {
            let data = try encoder.encode(signal)
            buffer.append(data)
        }

        // Auto-flush when buffer reaches a reasonable size.
        if buffer.count >= 50 {
            try await flush()
        }
    }

    public func flush() async throws {
        guard !buffer.isEmpty else { return }

        let handle = try ensureFileHandle()
        for data in buffer {
            handle.write(data)
            handle.write(Data("\n".utf8))
        }
        handle.synchronizeFile()
        buffer.removeAll()
    }

    // MARK: - Private Helpers

    private func ensureFileHandle() throws -> FileHandle {
        if let handle = fileHandle {
            return handle
        }

        let manager = FileManager.default
        if !manager.fileExists(atPath: fileURL.path) {
            manager.createFile(atPath: fileURL.path, contents: nil)
        }

        let handle = try FileHandle(forWritingTo: fileURL)
        handle.seekToEndOfFile()
        fileHandle = handle
        return handle
    }

    deinit {
        // FileHandle closed on deallocation automatically in modern Swift,
        // but explicit close is good practice.
    }
}
