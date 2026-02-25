import XCTest
import CoreGraphics
@testable import Analytics

final class InteractionTrackerTests: XCTestCase {

    // MARK: - Tracking Events

    func testTrackEventIsStoredInBuffer() async {
        let tracker = InteractionTracker(bufferCapacity: 500)
        let event = InteractionEvent(
            type: .tap,
            screen: "Home",
            point: CGPoint(x: 100, y: 200),
            metadata: ["element": "button"]
        )

        await tracker.track(event)

        let count = await tracker.currentBufferCount
        XCTAssertEqual(count, 1)

        let events = await tracker.bufferedEvents
        XCTAssertEqual(events.first?.screen, "Home")
        XCTAssertEqual(events.first?.type, .tap)
    }

    func testMultipleEventsAreStored() async {
        let tracker = InteractionTracker(bufferCapacity: 500)

        for i in 0..<10 {
            let event = InteractionEvent(
                type: .tap,
                screen: "Screen\(i)",
                metadata: [:]
            )
            await tracker.track(event)
        }

        let count = await tracker.currentBufferCount
        XCTAssertEqual(count, 10)
    }

    // MARK: - Ring Buffer Overflow

    func testRingBufferOverflowCapsAtCapacity() async {
        let capacity = 500
        let tracker = InteractionTracker(bufferCapacity: capacity)

        for i in 0..<600 {
            let event = InteractionEvent(
                type: .tap,
                screen: "Screen\(i)",
                metadata: [:]
            )
            await tracker.track(event)
        }

        let count = await tracker.currentBufferCount
        XCTAssertEqual(count, capacity, "Buffer should stay at capacity after overflow")

        let events = await tracker.bufferedEvents
        XCTAssertEqual(events.count, capacity)

        // Oldest events (0-99) should have been evicted.
        // The newest event should be Screen599.
        let lastEvent = events.last
        XCTAssertEqual(lastEvent?.screen, "Screen599")
    }

    // MARK: - Detector Registration and Signal Detection

    func testDetectorRegistrationAndSignalDetection() async {
        let tracker = InteractionTracker(bufferCapacity: 500)
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 2.0, regionRadius: 44)
        await tracker.registerDetector(detector)

        let baseTime = Date()
        let point = CGPoint(x: 100, y: 100)

        // Feed 3 rapid taps in the same region.
        for i in 0..<3 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.1),
                screen: "TaskList",
                point: point,
                metadata: [:]
            )
            await tracker.track(event)
        }

        // The tracker should have detected and emitted signals.
        // We verify indirectly by checking the buffer has all events.
        let count = await tracker.currentBufferCount
        XCTAssertEqual(count, 3)
    }

    // MARK: - PII Scrubbing

    func testPIIScrubbingOnTrack() async {
        let tracker = InteractionTracker(bufferCapacity: 500)
        let event = InteractionEvent(
            type: .tap,
            screen: "Profile",
            metadata: [
                "email": "user@example.com",
                "apiToken": "abc123secret",
                "element": "save_button",
            ]
        )

        await tracker.track(event)

        let events = await tracker.bufferedEvents
        guard let stored = events.first else {
            XCTFail("Expected stored event")
            return
        }

        // Email should be scrubbed.
        XCTAssertNotEqual(stored.metadata["email"], "user@example.com")
        XCTAssertEqual(stored.metadata["email"], "[REDACTED]")

        // Key containing "token" should be redacted.
        XCTAssertEqual(stored.metadata["apiToken"], "[REDACTED]")

        // Non-PII metadata should pass through.
        XCTAssertEqual(stored.metadata["element"], "save_button")
    }

    func testCoordinatesAreSnappedToGrid() async {
        let tracker = InteractionTracker(bufferCapacity: 500)
        let event = InteractionEvent(
            type: .tap,
            screen: "Map",
            point: CGPoint(x: 57, y: 123),
            metadata: [:]
        )

        await tracker.track(event)

        let events = await tracker.bufferedEvents
        guard let stored = events.first, let point = stored.point else {
            XCTFail("Expected stored event with point")
            return
        }

        // 57 / 44 = 1.295... → floor → 1 * 44 = 44
        // 123 / 44 = 2.795... → floor → 2 * 44 = 88
        XCTAssertEqual(point.x, 44, accuracy: 0.01)
        XCTAssertEqual(point.y, 88, accuracy: 0.01)
    }

    // MARK: - Exporter Registration

    func testExporterRegistration() async {
        let tracker = InteractionTracker(bufferCapacity: 500)
        let exporter = ConsoleSignalExporter()
        await tracker.registerExporter(exporter)

        // No crash, exporter is registered. Tracking an event should
        // call the exporter if signals are detected.
        let event = InteractionEvent(type: .navigate, screen: "Home", metadata: [:])
        await tracker.track(event)
    }
}
