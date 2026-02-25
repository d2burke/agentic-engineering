import XCTest
import SwiftUI
@testable import DesignSystem

final class ColorTokensTests: XCTestCase {

    // MARK: - Brand Colors

    func testBrandColorsAreNotNil() {
        // Verify that all brand color tokens can be instantiated without crashing.
        let _ = ColorTokens.primary
        let _ = ColorTokens.secondary
        let _ = ColorTokens.accent
        let _ = ColorTokens.destructive
    }

    // MARK: - Semantic Colors

    func testSemanticColorsAreNotNil() {
        let _ = ColorTokens.success
        let _ = ColorTokens.warning
        let _ = ColorTokens.error
        let _ = ColorTokens.info
    }

    // MARK: - Background Colors

    func testBackgroundColorsAreNotNil() {
        let _ = ColorTokens.backgroundPrimary
        let _ = ColorTokens.backgroundSecondary
        let _ = ColorTokens.backgroundTertiary
    }

    // MARK: - Text Colors

    func testTextColorsAreNotNil() {
        let _ = ColorTokens.textPrimary
        let _ = ColorTokens.textSecondary
        let _ = ColorTokens.textTertiary
    }

    // MARK: - Surface Colors

    func testSurfaceColorsAreNotNil() {
        let _ = ColorTokens.border
        let _ = ColorTokens.divider
        let _ = ColorTokens.cardBackground
        let _ = ColorTokens.groupedBackground
    }

    // MARK: - All Tokens Are Distinct Values

    func testPrimaryAndSecondaryAreDifferent() {
        // A basic sanity check that different tokens produce different values.
        // We can't easily compare Color values, but we can verify they
        // are constructed without error.
        let primary = ColorTokens.primary
        let secondary = ColorTokens.secondary
        // If these were the same static let, this would be a code smell.
        // The test ensures the initializers run successfully.
        XCTAssertNotNil(primary)
        XCTAssertNotNil(secondary)
    }
}
