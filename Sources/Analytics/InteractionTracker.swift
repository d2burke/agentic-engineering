import Foundation
import CoreGraphics

// MARK: - InteractionTracking Protocol

/// The public contract for the interaction analytics system.
///
/// Consumers register detectors and exporters, then call `track(_:)` for
/// every user interaction. The tracker feeds events to detectors, emits
/// signals through `signalStream`, and dispatches signals to exporters.
public protocol InteractionTracking: Sendable {
    /// Record a user interaction event.
    func track(_ event: InteractionEvent) async

    /// Register a new signal detector at runtime.
    func registerDetector(_ detector: any ExceptionalSignalDetector) async

    /// Register a new signal exporter at runtime.
    func registerExporter(_ exporter: any SignalExporter) async

    /// An `AsyncStream` that emits every `ExceptionalSignal` detected
    /// by registered detectors. This is the primary data feed for the
    /// experimentation pipeline.
    var signalStream: AsyncStream<ExceptionalSignal> { get }
}

// MARK: - InteractionTracker

/// The concrete analytics tracker, implemented as an `actor` for
/// inherent thread safety.
///
/// ## Architecture
/// - **Ring buffer**: Stores the last `bufferCapacity` events for
///   detector analysis while bounding memory usage.
/// - **Pluggable detectors**: Any `ExceptionalSignalDetector` can be
///   registered at runtime; events are fanned out to all detectors.
/// - **Signal stream**: Detected signals are pushed through an
///   `AsyncStream` for consumption by the experimentation agent.
/// - **Privacy**: PII is scrubbed from metadata and coordinates are
///   snapped to a 44pt grid before storage.
public actor InteractionTracker: InteractionTracking {

    // MARK: - Configuration

    /// Maximum number of events retained in the ring buffer.
    public let bufferCapacity: Int

    // MARK: - Ring Buffer

    private var eventBuffer: [InteractionEvent]
    private var bufferIndex: Int = 0
    private var bufferCount: Int = 0

    // MARK: - Detectors & Exporters

    private var detectors: [any ExceptionalSignalDetector] = []
    private var exporters: [any SignalExporter] = []

    // MARK: - Signal Stream

    private var signalContinuation: AsyncStream<ExceptionalSignal>.Continuation?
    public nonisolated let signalStream: AsyncStream<ExceptionalSignal>

    // MARK: - Init

    /// - Parameter bufferCapacity: Maximum events to retain. Default is 500.
    public init(bufferCapacity: Int = 500) {
        self.bufferCapacity = bufferCapacity
        self.eventBuffer = []
        self.eventBuffer.reserveCapacity(bufferCapacity)

        var continuation: AsyncStream<ExceptionalSignal>.Continuation?
        self.signalStream = AsyncStream<ExceptionalSignal> { cont in
            continuation = cont
        }
        self.signalContinuation = continuation
    }

    // MARK: - Track

    public func track(_ event: InteractionEvent) async {
        // Privacy: scrub PII from metadata, snap coordinates to grid.
        let scrubbedMetadata = PIIScrubber.scrub(event.metadata)
        let snappedPoint = event.point.map { PIIScrubber.snapToGrid($0) }

        let sanitizedEvent = InteractionEvent(
            id: event.id,
            type: event.type,
            timestamp: event.timestamp,
            screen: event.screen,
            point: snappedPoint,
            metadata: scrubbedMetadata,
            duration: event.duration
        )

        // Add to ring buffer.
        addToBuffer(sanitizedEvent)

        // Fan out to all registered detectors.
        for detector in detectors {
            detector.feed(sanitizedEvent)
        }

        // Check for new signals.
        var allSignals: [ExceptionalSignal] = []
        for detector in detectors {
            let signals = detector.detectSignals()
            allSignals.append(contentsOf: signals)
        }

        // Emit signals through the stream and export them.
        if !allSignals.isEmpty {
            for signal in allSignals {
                signalContinuation?.yield(signal)
            }

            for exporter in exporters {
                try? await exporter.export(allSignals)
            }
        }
    }

    // MARK: - Registration

    public func registerDetector(_ detector: any ExceptionalSignalDetector) {
        detectors.append(detector)
    }

    public func registerExporter(_ exporter: any SignalExporter) {
        exporters.append(exporter)
    }

    // MARK: - Buffer Access (for testing)

    /// Returns the current number of events in the ring buffer.
    public var currentBufferCount: Int {
        bufferCount
    }

    /// Returns a copy of all events currently in the ring buffer, ordered
    /// from oldest to newest.
    public var bufferedEvents: [InteractionEvent] {
        if bufferCount < bufferCapacity {
            return Array(eventBuffer[0..<bufferCount])
        } else {
            // Ring buffer wrapped: read from bufferIndex to end, then start to bufferIndex.
            let tail = Array(eventBuffer[bufferIndex..<bufferCapacity])
            let head = Array(eventBuffer[0..<bufferIndex])
            return tail + head
        }
    }

    // MARK: - Private Helpers

    private func addToBuffer(_ event: InteractionEvent) {
        if eventBuffer.count < bufferCapacity {
            eventBuffer.append(event)
            bufferCount = eventBuffer.count
        } else {
            eventBuffer[bufferIndex] = event
            bufferIndex = (bufferIndex + 1) % bufferCapacity
            bufferCount = bufferCapacity
        }
    }
}
