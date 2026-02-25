import SwiftUI
import DesignSystem
import Analytics

// MARK: - AlertBanner

/// A banner component for displaying dashboard alerts at the top of the screen.
///
/// When there are multiple unacknowledged alerts, they appear as a horizontal
/// scrollable row of alert pills. Each pill is color-coded by severity and
/// includes a dismiss button. Acknowledged alerts are removed with animation.
public struct AlertBanner: View {
    private let alerts: [DashboardAlert]
    private let onAcknowledge: (UUID) -> Void

    /// Creates an alert banner.
    ///
    /// - Parameters:
    ///   - alerts: The list of dashboard alerts to display.
    ///   - onAcknowledge: Closure called with the alert ID when the user dismisses an alert.
    public init(alerts: [DashboardAlert], onAcknowledge: @escaping (UUID) -> Void) {
        self.alerts = alerts
        self.onAcknowledge = onAcknowledge
    }

    public var body: some View {
        let unacknowledged = alerts.filter { !$0.isAcknowledged }

        if !unacknowledged.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(unacknowledged) { alert in
                        alertPill(alert)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .background(Color.black.opacity(0.03))
            .animation(.easeInOut(duration: 0.3), value: unacknowledged.map(\.id))
        }
    }

    // MARK: - Alert Pill

    /// A single alert pill showing icon, title, and dismiss button.
    private func alertPill(_ alert: DashboardAlert) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: alertIconName(alert.type))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(severityColor(alert.severity))

            VStack(alignment: .leading, spacing: 0) {
                Text(alert.title)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)

                Text(alert.message)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(1)
            }

            Button(action: { onAcknowledge(alert.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTokens.textTertiary)
                    .padding(Spacing.xs)
                    .background(Circle().fill(ColorTokens.backgroundTertiary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(severityColor(alert.severity).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(severityColor(alert.severity).opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Private Helpers

    /// Returns the SF Symbol icon for an alert type.
    private func alertIconName(_ type: DashboardAlertType) -> String {
        switch type {
        case .crashRateSpike:
            return "exclamationmark.triangle.fill"
        case .signalBurst:
            return "waveform.path.ecg"
        case .guardrailViolation:
            return "shield.lefthalf.filled.slash"
        case .experimentConcluded:
            return "flask.fill"
        case .experimentAutoIntegrated:
            return "arrow.triangle.merge"
        case .syncFailure:
            return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    /// Returns the color associated with a severity level.
    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low:
            return ColorTokens.info
        case .medium:
            return ColorTokens.warning
        case .high:
            return .orange
        case .critical:
            return ColorTokens.error
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Alert Banner") {
    VStack {
        AlertBanner(
            alerts: [
                DashboardAlert(
                    type: .crashRateSpike,
                    title: "Crash Rate Spike",
                    message: "Crash rate exceeded 1% threshold",
                    severity: .high
                ),
                DashboardAlert(
                    type: .experimentConcluded,
                    title: "Experiment Complete",
                    message: "Task Card Redesign concluded with positive outcome",
                    severity: .low
                ),
                DashboardAlert(
                    type: .guardrailViolation,
                    title: "Guardrail Breach",
                    message: "Crash rate exceeded hard guardrail",
                    severity: .critical
                ),
            ],
            onAcknowledge: { id in
                print("Acknowledged: \(id)")
            }
        )

        Spacer()
    }
}
#endif
