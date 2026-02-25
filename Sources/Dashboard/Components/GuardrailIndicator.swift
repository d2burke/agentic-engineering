import SwiftUI
import DesignSystem

// MARK: - GuardrailIndicator

/// A visual indicator for the status of a guardrail metric within
/// an experiment.
///
/// Displays a colored circle (green if passing, red if failing),
/// the metric name with current/threshold values, and a tier badge
/// indicating the enforcement level (HARD, SOFT, or VALUE).
public struct GuardrailIndicator: View {
    private let status: GuardrailStatus

    /// Creates a guardrail indicator.
    ///
    /// - Parameter status: The guardrail status to display.
    public init(status: GuardrailStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            // Status dot
            Circle()
                .fill(status.isPassing ? ColorTokens.success : ColorTokens.error)
                .frame(width: 10, height: 10)

            // Metric name and values
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(status.name)
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("\(formattedValue(status.currentValue)) / \(formattedValue(status.threshold))")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer()

            // Tier badge
            Text(tierDisplayName)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 2)
                .background(tierColor.opacity(0.15))
                .foregroundStyle(tierColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }

    // MARK: - Private Helpers

    /// Display name for the guardrail tier.
    private var tierDisplayName: String {
        switch status.tier {
        case .hard: return "HARD"
        case .soft: return "SOFT"
        case .value: return "VALUE"
        }
    }

    /// The color associated with the guardrail tier.
    private var tierColor: Color {
        switch status.tier {
        case .hard:
            return ColorTokens.error
        case .soft:
            return ColorTokens.warning
        case .value:
            return ColorTokens.info
        }
    }

    /// Formats a double value for display (removes unnecessary decimals).
    private func formattedValue(_ value: Double) -> String {
        if value == value.rounded() && value < 10000 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Compact Guardrail Dots

/// A compact row of guardrail status dots for use in summary cards.
/// Shows colored circles only, suitable for space-constrained layouts.
public struct GuardrailDotsView: View {
    private let guardrails: [GuardrailStatus]

    public init(guardrails: [GuardrailStatus]) {
        self.guardrails = guardrails
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(guardrails) { guardrail in
                Circle()
                    .fill(guardrail.isPassing ? ColorTokens.success : ColorTokens.error)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Guardrail Indicators") {
    VStack(spacing: 16) {
        GuardrailIndicator(
            status: GuardrailStatus(
                name: "Crash Rate Guard",
                metric: "crash_rate",
                threshold: 0.10,
                currentValue: 0.05,
                isPassing: true,
                tier: .hard
            )
        )

        GuardrailIndicator(
            status: GuardrailStatus(
                name: "Latency P95 Guard",
                metric: "latency_p95",
                threshold: 500,
                currentValue: 520,
                isPassing: false,
                tier: .soft
            )
        )

        GuardrailIndicator(
            status: GuardrailStatus(
                name: "Engagement Guard",
                metric: "engagement_score",
                threshold: 6.0,
                currentValue: 7.2,
                isPassing: true,
                tier: .value
            )
        )

        Divider()

        Text("Compact Dots")
            .font(Typography.caption)

        GuardrailDotsView(guardrails: [
            GuardrailStatus(name: "A", metric: "a", threshold: 2, currentValue: 1, isPassing: true, tier: .hard),
            GuardrailStatus(name: "B", metric: "b", threshold: 2, currentValue: 3, isPassing: false, tier: .soft),
            GuardrailStatus(name: "C", metric: "c", threshold: 2, currentValue: 1, isPassing: true, tier: .value),
        ])
    }
    .padding()
}
#endif
