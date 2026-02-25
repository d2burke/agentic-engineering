import XCTest
import CoreGraphics
@testable import Analytics

final class RageTapDetectorTests: XCTestCase {

    // MARK: - Detection: 3 rapid taps in same region

    func testThreeRapidTapsInSameRegionDetectsRageTap() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()
        let point = CGPoint(x: 100, y: 100)

        for i in 0..<3 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.2),
                screen: "TaskList",
                point: point,
                metadata: [:]
            )
            detector.feed(event)
        }

        let signals = detector.detectSignals()
        XCTAssertEqual(signals.count, 1)
        XCTAssertEqual(signals.first?.type, .rageTap)
        XCTAssertEqual(signals.first?.screen, "TaskList")
        XCTAssertEqual(signals.first?.triggeringEvents.count, 3)
    }

    // MARK: - No detection: only 2 taps

    func testTwoTapsDoNotTriggerDetection() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()
        let point = CGPoint(x: 100, y: 100)

        for i in 0..<2 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.2),
                screen: "TaskList",
                point: point,
                metadata: [:]
            )
            detector.feed(event)
        }

        let signals = detector.detectSignals()
        XCTAssertTrue(signals.isEmpty, "Two taps should not trigger rage tap detection")
    }

    // MARK: - No detection: different regions

    func testThreeTapsInDifferentRegionsDoNotTrigger() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()

        // Points that are far apart (> 44pt).
        let points: [CGPoint] = [
            CGPoint(x: 10, y: 10),
            CGPoint(x: 200, y: 200),
            CGPoint(x: 400, y: 400),
        ]

        for i in 0..<3 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.2),
                screen: "TaskList",
                point: points[i],
                metadata: [:]
            )
            detector.feed(event)
        }

        let signals = detector.detectSignals()
        XCTAssertTrue(signals.isEmpty, "Taps in different regions should not trigger detection")
    }

    // MARK: - No detection: taps outside time window

    func testThreeSlowTapsOutsideWindowDoNotTrigger() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()
        let point = CGPoint(x: 100, y: 100)

        // Each tap is 2 seconds apart — outside the 1-second window.
        for i in 0..<3 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 2.0),
                screen: "TaskList",
                point: point,
                metadata: [:]
            )
            detector.feed(event)
        }

        let signals = detector.detectSignals()
        XCTAssertTrue(signals.isEmpty, "Taps outside time window should not trigger detection")
    }

    // MARK: - Reset clears state

    func testResetClearsState() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()
        let point = CGPoint(x: 100, y: 100)

        // Feed 2 taps.
        for i in 0..<2 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.2),
                screen: "TaskList",
                point: point,
                metadata: [:]
            )
            detector.feed(event)
        }

        // Reset.
        detector.reset()

        // Feed 1 more tap — should NOT trigger since buffer was cleared.
        let event = InteractionEvent(
            type: .tap,
            timestamp: baseTime.addingTimeInterval(0.4),
            screen: "TaskList",
            point: point,
            metadata: [:]
        )
        detector.feed(event)

        let signals = detector.detectSignals()
        XCTAssertTrue(signals.isEmpty, "Reset should clear buffered taps")
    }

    // MARK: - Non-tap events are ignored

    func testNonTapEventsAreIgnored() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()

        for i in 0..<5 {
            let event = InteractionEvent(
                type: .scroll,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.1),
                screen: "TaskList",
                point: CGPoint(x: 100, y: 100),
                metadata: [:]
            )
            detector.feed(event)
        }

        let signals = detector.detectSignals()
        XCTAssertTrue(signals.isEmpty, "Non-tap events should not trigger rage tap detection")
    }

    // MARK: - Taps within radius boundary

    func testTapsWithinRadiusBoundaryAreDetected() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()

        // All points within 44pt of (100, 100).
        let points: [CGPoint] = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 130, y: 100),   // 30pt away
            CGPoint(x: 100, y: 140),   // 40pt away
        ]

        for i in 0..<3 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.2),
                screen: "TaskList",
                point: points[i],
                metadata: [:]
            )
            detector.feed(event)
        }

        let signals = detector.detectSignals()
        XCTAssertEqual(signals.count, 1, "Taps within radius should be detected as rage tap")
    }

    // MARK: - Consumed events are not re-detected

    func testConsumedEventsAreNotReDetected() {
        let detector = RageTapDetector(tapThreshold: 3, windowSeconds: 1.0, regionRadius: 44)
        let baseTime = Date()
        let point = CGPoint(x: 100, y: 100)

        for i in 0..<3 {
            let event = InteractionEvent(
                type: .tap,
                timestamp: baseTime.addingTimeInterval(Double(i) * 0.2),
                screen: "TaskList",
                point: point,
                metadata: [:]
            )
            detector.feed(event)
        }

        let firstSignals = detector.detectSignals()
        XCTAssertEqual(firstSignals.count, 1)

        // Second call should produce no signals since events were consumed.
        let secondSignals = detector.detectSignals()
        XCTAssertTrue(secondSignals.isEmpty, "Already consumed events should not produce duplicate signals")
    }
}
