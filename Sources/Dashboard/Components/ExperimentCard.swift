import SwiftUI
import DesignSystem

// MARK: - ExperimentCard

/// A card component for displaying the status of an actively running
/// experiment in the agentic work panel.
///
/// Shows the experiment name, hypothesis (truncated), progress bar
/// (time elapsed), primary metric with current vs target, guardrail
/// status indicator dots, and time remaining. The card is tappable
/// for navigating to experiment detail.
public struct ExperimentCard: View {
    private let experiment: ActiveExperimentStatus
    private let onTap: (() -> Void)?

    /// Creates an experiment card.
    ///
    /// - Parameters:
    ///   - experiment: The active experiment status to display.
    ///   - onTap: Optional closure invoked when the card is tapped.
    public init(experiment: ActiveExperimentStatus, onTap: (() -> Void)? = nil) {
        self.experiment = experiment
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header: name and time remaining
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(experiment.experimentName)
                            .font(Typography.headline)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(1)

                        Text(experiment.hypothesis)
                            .font(Typography.caption)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text(formattedTimeRemaining)
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    ProgressView(value: experiment.progress, total: 1.0)
                        .tint(progressColor)

                    HStack {
                        Text("\(Int(experiment.progress * 100))% complete")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textTertiary)

                        Spacer()

                        Text("\(experiment.sampleSize) samples")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }

                // Primary metric: current vs target
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(experiment.primaryMetric)
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(ColorTokens.textSecondary)

                    HStack(spacing: Spacing.sm) {
                        // Current value bar
                        metricBar(
                            label: "Current",
                            value: experiment.currentMetricValue,
                            maxValue: max(experiment.targetMetricValue, experiment.currentMetricValue) * 1.2,
                            color: metricColor
                        )

                        // Target value bar
                        metricBar(
                            label: "Target",
                            value: experiment.targetMetricValue,
                            maxValue: max(experiment.targetMetricValue, experiment.currentMetricValue) * 1.2,
                            color: ColorTokens.textTertiary
                        )
                    }
                }

                // Guardrail status dots and label
                HStack(spacing: Spacing.sm) {
                    Text("Guardrails")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textTertiary)

                    GuardrailDotsView(guardrails: experiment.guardrailStatuses)

                    Spacer()

                    let passing = experiment.guardrailStatuses.filter(\.isPassing).count
                    let total = experiment.guardrailStatuses.count
                    Text("\(passing)/\(total) passing")
                        .font(Typography.caption2)
                        .foregroundStyle(passing == total ? ColorTokens.success : ColorTokens.warning)
                }
            }
            .padding(Spacing.md)
            .background(ColorTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    /// A small horizontal bar chart for comparing current vs target metrics.
    private func metricBar(label: String, value: Double, maxValue: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(ColorTokens.textTertiary)

            GeometryReader { geometry in
                let barWidth = maxValue > 0
                    ? max(0, min(geometry.size.width, geometry.size.width * (value / maxValue)))
                    : 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: barWidth, height: 6)
            }
            .frame(height: 6)

            Text(String(format: "%.2f", value))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }

    // MARK: - Computed Properties

    /// Formatted time remaining string based on estimated end date.
    private var formattedTimeRemaining: String {
        let interval = experiment.estimatedEndDate.timeIntervalSince(Date())
        guard interval > 0 else { return "Ending soon" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h left"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }

    /// Color of the progress bar based on completion.
    private var progressColor: Color {
        if experiment.progress >= 0.9 {
            return ColorTokens.success
        } else if experiment.progress >= 0.5 {
            return ColorTokens.info
        } else {
            return ColorTokens.warning
        }
    }

    /// Color for the primary metric indicator.
    private var metricColor: Color {
        if experiment.currentMetricValue >= experiment.targetMetricValue {
            return ColorTokens.success
        } else if experiment.currentMetricValue >= experiment.targetMetricValue * 0.8 {
            return ColorTokens.warning
        } else {
            return ColorTokens.error
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Experiment Card") {
    ScrollView {
        VStack(spacing: 16) {
            ExperimentCard(
                experiment: ActiveExperimentStatus(
                    experimentName: "Task Card Redesign v2",
                    hypothesis: "Larger tap targets and clearer status indicators will reduce dead taps by 30%",
                    variantNames: ["control", "variant_a"],
                    primaryMetric: "dead_tap_rate",
                    currentMetricValue: 0.08,
                    targetMetricValue: 0.05,
                    guardrailStatuses: [
                        GuardrailStatus(name: "Crash Rate", metric: "crash_rate", threshold: 0.05, currentValue: 0.01, isPassing: true, tier: .hard),
                        GuardrailStatus(name: "Load Time", metric: "load_time", threshold: 200, currentValue: 180, isPassing: true, tier: .soft),
                        GuardrailStatus(name: "Engagement", metric: "engagement", threshold: 6.0, currentValue: 6.8, isPassing: true, tier: .value),
                    ],
                    progress: 0.65,
                    startDate: Date().addingTimeInterval(-86400),
                    estimatedEndDate: Date().addingTimeInterval(43200),
                    sampleSize: 5400
                )
            )

            ExperimentCard(
                experiment: ActiveExperimentStatus(
                    experimentName: "Navigation Flow Optimization",
                    hypothesis: "Reducing navigation depth will decrease abandon signals on project screens",
                    variantNames: ["control", "shallow_nav"],
                    primaryMetric: "abandon_rate",
                    currentMetricValue: 0.12,
                    targetMetricValue: 0.10,
                    guardrailStatuses: [
                        GuardrailStatus(name: "Crash Rate", metric: "crash_rate", threshold: 0.05, currentValue: 0.06, isPassing: false, tier: .hard),
                        GuardrailStatus(name: "Latency P95", metric: "latency_p95", threshold: 500, currentValue: 450, isPassing: true, tier: .soft),
                    ],
                    progress: 0.92,
                    startDate: Date().addingTimeInterval(-172800),
                    estimatedEndDate: Date().addingTimeInterval(3600),
                    sampleSize: 12300
                )
            )
        }
        .padding()
    }
    .background(ColorTokens.backgroundSecondary)
}
#endif
