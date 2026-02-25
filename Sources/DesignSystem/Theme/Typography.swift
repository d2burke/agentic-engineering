import SwiftUI

// MARK: - Typography

/// Centralized typography scale for the TaskManager design system.
///
/// All fonts use the system typeface at carefully chosen sizes and
/// weights to maintain visual hierarchy and readability across
/// light and dark modes. Supports Dynamic Type for accessibility.
public enum Typography {

    // MARK: - Predefined Styles

    /// Large title — splash screens and hero headers (34pt, bold).
    public static let largeTitle: Font = .system(size: 34, weight: .bold, design: .default)

    /// Title — section headers and screen titles (28pt, bold).
    public static let title: Font = .system(size: 28, weight: .bold, design: .default)

    /// Title 2 — subsection headers (22pt, bold).
    public static let title2: Font = .system(size: 22, weight: .bold, design: .default)

    /// Title 3 — tertiary headers (20pt, semibold).
    public static let title3: Font = .system(size: 20, weight: .semibold, design: .default)

    /// Headline — card titles and prominent labels (17pt, semibold).
    public static let headline: Font = .system(size: 17, weight: .semibold, design: .default)

    /// Subheadline — supporting headings (15pt, regular).
    public static let subheadline: Font = .system(size: 15, weight: .regular, design: .default)

    /// Body — primary reading content (17pt, regular).
    public static let body: Font = .system(size: 17, weight: .regular, design: .default)

    /// Callout — secondary reading content and descriptions (16pt, regular).
    public static let callout: Font = .system(size: 16, weight: .regular, design: .default)

    /// Footnote — legal text and very small labels (13pt, regular).
    public static let footnote: Font = .system(size: 13, weight: .regular, design: .default)

    /// Caption — metadata, timestamps, and auxiliary info (12pt, regular).
    public static let caption: Font = .system(size: 12, weight: .regular, design: .default)

    /// Caption 2 — smallest text for badges and micro-labels (11pt, regular).
    public static let caption2: Font = .system(size: 11, weight: .regular, design: .default)

    // MARK: - Custom Font Builder

    /// Create a custom font with the given size and weight using the
    /// system typeface.
    ///
    /// - Parameters:
    ///   - size: The point size.
    ///   - weight: The font weight.
    /// - Returns: A configured `Font` instance.
    public static func font(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
