import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ColorTokens

/// Centralized color palette for the TaskManager design system.
///
/// All colors support both light and dark appearance modes using
/// adaptive `UIColor` initializers wrapped in SwiftUI `Color`.
/// This ensures consistent theming across the entire application
/// without relying on asset catalog resources.
public enum ColorTokens {

    // MARK: - Brand Colors

    /// Primary brand color — used for key actions and navigation elements.
    public static let primary = adaptiveColor(light: 0x0066FF, dark: 0x4D94FF)

    /// Secondary brand color — used for supporting UI elements.
    public static let secondary = adaptiveColor(light: 0x6B7280, dark: 0x9CA3AF)

    /// Accent color — used for highlights and interactive affordances.
    public static let accent = adaptiveColor(light: 0x8B5CF6, dark: 0xA78BFA)

    /// Destructive action color.
    public static let destructive = adaptiveColor(light: 0xEF4444, dark: 0xF87171)

    // MARK: - Semantic Colors

    /// Indicates successful completion or positive state.
    public static let success = adaptiveColor(light: 0x10B981, dark: 0x34D399)

    /// Indicates a warning or cautionary state.
    public static let warning = adaptiveColor(light: 0xF59E0B, dark: 0xFBBF24)

    /// Indicates an error or destructive action.
    public static let error = adaptiveColor(light: 0xEF4444, dark: 0xF87171)

    /// Indicates informational or neutral status.
    public static let info = adaptiveColor(light: 0x3B82F6, dark: 0x60A5FA)

    // MARK: - Background Colors

    /// Primary background — the main canvas.
    public static let backgroundPrimary = adaptiveColor(light: 0xFFFFFF, dark: 0x111111)

    /// Secondary background — cards and elevated surfaces.
    public static let backgroundSecondary = adaptiveColor(light: 0xF9FAFB, dark: 0x1F1F1F)

    /// Tertiary background — grouped content areas.
    public static let backgroundTertiary = adaptiveColor(light: 0xF3F4F6, dark: 0x2D2D2D)

    // MARK: - Text Colors

    /// Primary text — headings and body copy.
    public static let textPrimary = adaptiveColor(light: 0x111827, dark: 0xF9FAFB)

    /// Secondary text — supporting and less prominent copy.
    public static let textSecondary = adaptiveColor(light: 0x6B7280, dark: 0x9CA3AF)

    /// Tertiary text — placeholders and disabled labels.
    public static let textTertiary = adaptiveColor(light: 0x9CA3AF, dark: 0x6B7280)

    // MARK: - Surface Colors

    /// Border color for separators and outlines.
    public static let border = adaptiveColor(light: 0xD1D5DB, dark: 0x374151)

    /// Divider color for content separation.
    public static let divider = adaptiveColor(light: 0xE5E7EB, dark: 0x4B5563)

    /// Card background for elevated content surfaces.
    public static let cardBackground = adaptiveColor(light: 0xFFFFFF, dark: 0x1F1F1F)

    /// Grouped background for table-style layouts.
    public static let groupedBackground = adaptiveColor(light: 0xF2F2F7, dark: 0x1C1C1E)

    // MARK: - Helpers

    /// Creates an adaptive `Color` that automatically switches between
    /// light and dark variants based on the current interface style.
    private static func adaptiveColor(light: UInt, dark: UInt) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: dark)
            default:
                return UIColor(hex: light)
            }
        })
        #else
        return Color(hex: light)
        #endif
    }
}

// MARK: - UIColor Hex Convenience

#if canImport(UIKit)
private extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
#endif

// MARK: - Color Hex Convenience (fallback)

private extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
