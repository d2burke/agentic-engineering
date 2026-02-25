import SwiftUI
import DesignSystem

// MARK: - MetricCard

/// A reusable card component for displaying a key performance indicator (KPI).
///
/// Shows a title, large formatted value, optional trend indicator with
/// directional arrow and percentage, and an optional subtitle. The trend
/// arrow is color-coded based on whether the trend direction is positive
/// or negative for the given metric.
///
/// ## Usage
/// ```swift
/// MetricCard(
///     title: "Daily Active Users",
///     value: "12.4K",
///     trend: .increasing,
///     trendValue: "+8.3%",
///     trendIsPositive: true,
///     icon: "person.3.fill"
/// )
/// ```
public struct MetricCard: View {
    private let title: String
    private let value: String
    private let subtitle: String?
    private let trend: TrendDirection?
    private let trendValue: String?
    private let trendIsPositive: Bool
    private let icon: String

    /// Creates a new metric card.
    ///
    /// - Parameters:
    ///   - title: The metric name displayed at the top of the card.
    ///   - value: The large formatted value (e.g., "12.4K", "99.5%").
    ///   - subtitle: Optional supporting text below the value.
    ///   - trend: The direction of the trend arrow. `nil` hides the trend indicator.
    ///   - trendValue: The trend percentage or delta string (e.g., "+8.3%").
    ///   - trendIsPositive: Whether the current trend direction is desirable.
    ///     When `true`, an increasing trend shows green; when `false`, increasing shows red.
    ///   - icon: An SF Symbol name displayed alongside the title.
    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        trendIsPositive: Bool = true,
        icon: String
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.trendValue = trendValue
        self.trendIsPositive = trendIsPositive
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Title row with icon
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(1)
            }

            // Large value
            Text(value)
                .font(Typography.title2)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Trend indicator
            if let trend, let trendValue {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: trend.iconName)
                        .font(.system(size: 10, weight: .bold))

                    Text(trendValue)
                        .font(Typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(trendColor(for: trend))
            }

            // Optional subtitle
            if let subtitle {
                Text(subtitle)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.md)
        .frame(minWidth: 140, alignment: .leading)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Private Helpers

    /// Determines the color of the trend indicator based on direction
    /// and whether the direction is positive for this metric.
    private func trendColor(for direction: TrendDirection) -> Color {
        switch direction {
        case .increasing:
            return trendIsPositive ? ColorTokens.success : ColorTokens.error
        case .decreasing:
            return trendIsPositive ? ColorTokens.error : ColorTokens.success
        case .stable:
            return ColorTokens.textSecondary
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Metric Cards") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            MetricCard(
                title: "Daily Active Users",
                value: "12.4K",
                trend: .increasing,
                trendValue: "+8.3%",
                trendIsPositive: true,
                icon: "person.3.fill"
            )

            MetricCard(
                title: "Crash Rate",
                value: "0.12%",
                trend: .decreasing,
                trendValue: "-2.1%",
                trendIsPositive: false,
                icon: "exclamationmark.triangle"
            )

            MetricCard(
                title: "Completion Rate",
                value: "78.5%",
                subtitle: "vs 75.2% last period",
                trend: .increasing,
                trendValue: "+3.3%",
                trendIsPositive: true,
                icon: "checkmark.circle"
            )

            MetricCard(
                title: "Latency P50",
                value: "142ms",
                trend: .stable,
                trendValue: "0.0%",
                trendIsPositive: false,
                icon: "clock"
            )
        }
        .padding()
    }
    .background(ColorTokens.backgroundSecondary)
}
#endif
