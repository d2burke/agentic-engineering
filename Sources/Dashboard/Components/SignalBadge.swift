import SwiftUI
import DesignSystem
import Analytics

// MARK: - SignalBadge

/// A colored pill badge for displaying an interaction signal type.
///
/// Each signal type has a distinct background color and SF Symbol icon
/// for immediate visual recognition in feeds and lists.
///
/// Color mapping:
/// - **rageTap** -> red
/// - **deadTap** -> orange
/// - **abandon** -> purple
/// - **errorBurst** -> red (darker)
/// - **longPressFrustration** -> pink
/// - **excessiveScroll** -> teal
/// - **latencySpike** -> blue
public struct SignalBadge: View {
    private let signalType: SignalType

    /// Creates a signal badge for the given signal type.
    ///
    /// - Parameter signalType: The type of interaction signal to display.
    public init(signalType: SignalType) {
        self.signalType = signalType
    }

    public var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .semibold))

            Text(displayName)
                .font(Typography.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(badgeColor.opacity(0.15))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
    }

    // MARK: - Signal Type Properties

    /// The SF Symbol icon for each signal type.
    private var iconName: String {
        switch signalType {
        case .rageTap:
            return "hand.tap.fill"
        case .deadTap:
            return "hand.raised.slash.fill"
        case .abandon:
            return "rectangle.portrait.and.arrow.right"
        case .errorBurst:
            return "exclamationmark.octagon.fill"
        case .longPressFrustration:
            return "hand.point.down.fill"
        case .excessiveScroll:
            return "scroll.fill"
        case .latencySpike:
            return "clock.badge.exclamationmark"
        }
    }

    /// A human-readable name for each signal type.
    private var displayName: String {
        switch signalType {
        case .rageTap:
            return "Rage Tap"
        case .deadTap:
            return "Dead Tap"
        case .abandon:
            return "Abandon"
        case .errorBurst:
            return "Error Burst"
        case .longPressFrustration:
            return "Long Press"
        case .excessiveScroll:
            return "Excess Scroll"
        case .latencySpike:
            return "Latency Spike"
        }
    }

    /// The badge color for each signal type.
    private var badgeColor: Color {
        switch signalType {
        case .rageTap:
            return .red
        case .deadTap:
            return .orange
        case .abandon:
            return .purple
        case .errorBurst:
            return Color(red: 0.8, green: 0.1, blue: 0.1)
        case .longPressFrustration:
            return .pink
        case .excessiveScroll:
            return .teal
        case .latencySpike:
            return .blue
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Signal Badges") {
    VStack(spacing: 12) {
        ForEach(SignalType.allCases, id: \.rawValue) { type in
            SignalBadge(signalType: type)
        }
    }
    .padding()
}
#endif
