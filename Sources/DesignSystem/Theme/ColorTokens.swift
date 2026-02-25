import SwiftUI

/// Centralized color tokens for the TaskManager design system.
///
/// All colors are defined as static properties for consistent theming
/// across the application. Supports both light and dark mode.
public enum ColorTokens {
    public static let primary = Color.blue
    public static let secondary = Color.gray
    public static let accent = Color.indigo
    public static let destructive = Color.red
    public static let success = Color.green
    public static let warning = Color.orange

    public static let backgroundPrimary = Color(.systemBackground)
    public static let backgroundSecondary = Color(.secondarySystemBackground)
    public static let backgroundTertiary = Color(.tertiarySystemBackground)

    public static let textPrimary = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
    public static let textTertiary = Color(.tertiaryLabel)

    public static let border = Color(.separator)
    public static let divider = Color(.opaqueSeparator)

    public static let cardBackground = Color(.secondarySystemGroupedBackground)
    public static let groupedBackground = Color(.systemGroupedBackground)
}
