import XCTest
@testable import Common

final class AppErrorTests: XCTestCase {

    // MARK: - Localized Description

    func testNetworkErrorHasDescription() {
        let error = AppError.network("Connection timed out")
        XCTAssertEqual(error.localizedDescription, "Network error: Connection timed out")
    }

    func testDecodingErrorHasDescription() {
        let error = AppError.decoding("Missing key 'name'")
        XCTAssertEqual(error.localizedDescription, "Decoding error: Missing key 'name'")
    }

    func testPersistenceErrorHasDescription() {
        let error = AppError.persistence("Disk full")
        XCTAssertEqual(error.localizedDescription, "Persistence error: Disk full")
    }

    func testAuthErrorHasDescription() {
        let error = AppError.auth("Invalid credentials")
        XCTAssertEqual(error.localizedDescription, "Authentication error: Invalid credentials")
    }

    func testValidationErrorHasDescription() {
        let error = AppError.validation("Email is required")
        XCTAssertEqual(error.localizedDescription, "Validation error: Email is required")
    }

    func testNotFoundErrorHasDescription() {
        let error = AppError.notFound
        XCTAssertEqual(error.localizedDescription, "The requested resource was not found.")
    }

    func testUnauthorizedErrorHasDescription() {
        let error = AppError.unauthorized
        XCTAssertEqual(error.localizedDescription, "You are not authorized to perform this action.")
    }

    func testUnknownErrorHasDescription() {
        let error = AppError.unknown("Something went wrong")
        XCTAssertEqual(error.localizedDescription, "An unknown error occurred: Something went wrong")
    }

    // MARK: - Equatable

    func testSameNetworkErrorsAreEqual() {
        let a = AppError.network("timeout")
        let b = AppError.network("timeout")
        XCTAssertEqual(a, b)
    }

    func testDifferentNetworkErrorsAreNotEqual() {
        let a = AppError.network("timeout")
        let b = AppError.network("dns failure")
        XCTAssertNotEqual(a, b)
    }

    func testDifferentCasesAreNotEqual() {
        let a = AppError.network("error")
        let b = AppError.decoding("error")
        XCTAssertNotEqual(a, b)
    }

    func testNotFoundEquality() {
        XCTAssertEqual(AppError.notFound, AppError.notFound)
    }

    func testUnauthorizedEquality() {
        XCTAssertEqual(AppError.unauthorized, AppError.unauthorized)
    }

    func testNotFoundNotEqualToUnauthorized() {
        XCTAssertNotEqual(AppError.notFound, AppError.unauthorized)
    }

    // MARK: - Error Conformance

    func testConformsToError() {
        let error: Error = AppError.network("test")
        XCTAssertNotNil(error)
    }
}
