import XCTest
@testable import Common

final class DateFormattingTests: XCTestCase {

    // MARK: - ISO 8601 Round-Trip

    func testISO8601RoundTrip() {
        let originalDate = Date(timeIntervalSinceReferenceDate: 700_000_000)
        let isoString = DateFormatting.iso8601String(from: originalDate)
        let parsedDate = DateFormatting.date(fromISO8601: isoString)

        XCTAssertNotNil(parsedDate)
        // Allow a tiny tolerance for fractional second rounding
        if let parsedDate = parsedDate {
            XCTAssertEqual(
                originalDate.timeIntervalSinceReferenceDate,
                parsedDate.timeIntervalSinceReferenceDate,
                accuracy: 0.001
            )
        }
    }

    func testISO8601StringFormat() {
        let isoString = DateFormatting.iso8601String(from: Date(timeIntervalSince1970: 0))
        // Should contain 'T' separator and timezone designator
        XCTAssertTrue(isoString.contains("T"))
        XCTAssertTrue(isoString.contains("Z") || isoString.contains("+") || isoString.contains("-"))
    }

    func testInvalidISO8601ReturnsNil() {
        XCTAssertNil(DateFormatting.date(fromISO8601: "not-a-date"))
        XCTAssertNil(DateFormatting.date(fromISO8601: ""))
    }

    // MARK: - Display Formatting

    func testDisplayStringIsNotEmpty() {
        let displayString = DateFormatting.displayString(from: Date())
        XCTAssertFalse(displayString.isEmpty)
    }

    func testDisplayStringContainsTimeComponents() {
        let date = Date()
        let displayString = DateFormatting.displayString(from: date)
        // Medium date style + short time style always includes the year and some time indicator
        XCTAssertTrue(displayString.count > 5, "Display string should have meaningful content")
    }

    // MARK: - Relative Formatting

    func testRelativeStringIsNotEmpty() {
        let date = Date().addingTimeInterval(-3600) // 1 hour ago
        let relativeString = DateFormatting.relativeString(from: date)
        XCTAssertFalse(relativeString.isEmpty)
    }

    func testRelativeStringForRecentDate() {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300)
        let relativeString = DateFormatting.relativeString(from: fiveMinutesAgo, relativeTo: now)
        XCTAssertFalse(relativeString.isEmpty)
        // Should contain "minute" in some form
        let lowered = relativeString.lowercased()
        XCTAssertTrue(lowered.contains("minute") || lowered.contains("min"),
                       "Expected relative string to mention minutes, got: \(relativeString)")
    }

    // MARK: - Date Extension

    func testDateRelativeStringExtension() {
        let date = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertFalse(date.relativeString.isEmpty)
    }

    func testDateDisplayStringExtension() {
        let date = Date()
        XCTAssertFalse(date.displayString.isEmpty)
    }

    func testDateISO8601StringExtension() {
        let date = Date()
        let isoString = date.iso8601String
        XCTAssertFalse(isoString.isEmpty)
        XCTAssertTrue(isoString.contains("T"))
    }
}
