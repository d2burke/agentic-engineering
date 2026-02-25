import Foundation
import CoreGraphics

// MARK: - Spacing

/// Spacing scale for consistent layout rhythm across the design system.
///
/// Values follow a geometric progression that produces visually
/// harmonious gaps at every density level.
public enum Spacing {
    /// 2pt — hairline separators and micro-adjustments.
    public static let xxs: CGFloat = 2

    /// 4pt — tight inline spacing.
    public static let xs: CGFloat = 4

    /// 8pt — compact spacing between related elements.
    public static let sm: CGFloat = 8

    /// 12pt — default spacing within grouped content.
    public static let md: CGFloat = 12

    /// 16pt — standard spacing between distinct elements.
    public static let lg: CGFloat = 16

    /// 24pt — generous spacing between content sections.
    public static let xl: CGFloat = 24

    /// 32pt — large spacing for major section breaks.
    public static let xxl: CGFloat = 32

    /// 48pt — extra-large spacing for hero areas and page margins.
    public static let xxxl: CGFloat = 48
}

// MARK: - CornerRadius

/// Corner radius presets for consistent rounding across the design system.
public enum CornerRadius {
    /// 6pt — subtle rounding for small elements (badges, chips).
    public static let small: CGFloat = 6

    /// 10pt — standard rounding for cards and buttons.
    public static let medium: CGFloat = 10

    /// 16pt — prominent rounding for modals and sheets.
    public static let large: CGFloat = 16

    /// 9999pt — fully rounded (pill shape) for tags and toggles.
    public static let pill: CGFloat = 9999
}
