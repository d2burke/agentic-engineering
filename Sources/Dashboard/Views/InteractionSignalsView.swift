import SwiftUI
import Charts
import DesignSystem
import Analytics

// MARK: - InteractionSignalsView

/// The interaction signals panel -- the human view of what the
/// Experimentation Agent sees.
///
/// Displays signal rate, live signal feed with filter chips, signal
/// heatmap, signal trends over time, top friction points, and
/// detector health status.
public struct InteractionSignalsView: View {
    @Bindable private var viewModel: InteractionSignalsViewModel

    /// Creates an interaction signals view.
    ///
    /// - Parameter viewModel: The interaction signals view model.
    public init(viewModel: InteractionSignalsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                if viewModel.metrics != nil {
                    signalRateCard
                    liveSignalFeed
                    signalHeatmap
                    signalTrendsChart
                    topFrictionPointsSection
                    detectorHealthSection
                } else if viewModel.isLoading {
                    loadingPlaceholder
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    EmptyStateView(
                        icon: "waveform.path.ecg",
                        title: "No Signal Data",
                        message: "Interaction signal metrics will appear here once data is loaded."
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .background(ColorTokens.backgroundSecondary)
        .trackInteraction(screen: "DashboardSignals")
    }

    // MARK: - Signal Rate Card

    /// KPI card showing current signals per hour with trend.
    private var signalRateCard: some View {
        HStack(spacing: Spacing.md) {
            MetricCard(
                title: "Signals / Hour",
                value: viewModel.formattedSignalRate,
                subtitle: "\(viewModel.formattedTotalSignals) total signals",
                icon: "waveform.path.ecg"
            )

            // Live streaming toggle
            VStack(spacing: Spacing.sm) {
                Button(action: { viewModel.toggleLiveStreaming() }) {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(viewModel.isStreamingLive ? Color.red : ColorTokens.textTertiary)
                            .frame(width: 8, height: 8)

                        Text(viewModel.isStreamingLive ? "Live" : "Paused")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        (viewModel.isStreamingLive ? Color.red : ColorTokens.textTertiary)
                            .opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Live Signal Feed

    /// Scrollable list of recent signals with filter chips.
    private var liveSignalFeed: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Live Signal Feed")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    // "All" chip
                    filterChip(label: "All", isSelected: viewModel.selectedSignalType == nil) {
                        viewModel.filterBySignalType(nil)
                    }

                    // Per-type chips
                    ForEach(viewModel.availableSignalTypes, id: \.rawValue) { type in
                        filterChip(
                            label: signalTypeName(type),
                            isSelected: viewModel.selectedSignalType == type
                        ) {
                            viewModel.filterBySignalType(type)
                        }
                    }
                }
            }

            // Signal list
            let signals = viewModel.filteredSignals

            if signals.isEmpty {
                Text("No signals match the current filter")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            } else {
                ForEach(signals.prefix(20)) { signal in
                    signalFeedRow(signal)

                    if signal.id != signals.prefix(20).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    /// A single row in the signal feed.
    private func signalFeedRow(_ signal: SignalFeedItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            SignalBadge(signalType: signal.signalType)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(signal.screen)
                    .font(Typography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(signal.description)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                severityBadge(signal.severity)

                Text(relativeTimeString(signal.timestamp))
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    /// A filter chip button.
    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    isSelected ? ColorTokens.primary.opacity(0.15) : ColorTokens.backgroundTertiary
                )
                .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Signal Heatmap

    /// Grid visualization of signals by screen and type.
    private var signalHeatmap: some View {
        HeatmapGrid(
            data: viewModel.heatmapData,
            signalTypes: [.rageTap, .deadTap, .abandon, .latencySpike]
        )
    }

    // MARK: - Signal Trends Chart

    /// Multi-line chart showing each signal type over time.
    private var signalTrendsChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            let trends = viewModel.trendChartData

            if trends.isEmpty {
                Text("No trend data available")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            } else {
                MultiLineTimeSeriesChart(
                    title: "Signal Trends",
                    seriesData: trends.map { trend in
                        (
                            label: signalTypeName(trend.signalType),
                            data: trend.dataPoints,
                            color: signalTypeColor(trend.signalType)
                        )
                    }
                )
            }
        }
    }

    // MARK: - Top Friction Points

    /// Ranked list of friction points with screen, signal type, count, trend, and severity.
    private var topFrictionPointsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Top Friction Points")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let frictionPoints = viewModel.frictionPointsRanked

            if frictionPoints.isEmpty {
                Text("No friction points detected")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else {
                ForEach(frictionPoints) { point in
                    HStack(spacing: Spacing.sm) {
                        // Trend arrow
                        Image(systemName: point.trend.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(trendColor(point.trend))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            HStack(spacing: Spacing.xs) {
                                Text(point.screen)
                                    .font(Typography.callout)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ColorTokens.textPrimary)

                                SignalBadge(signalType: point.signalType)
                            }

                            Text(point.description)
                                .font(Typography.caption)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: Spacing.xxs) {
                            Text("\(point.count)")
                                .font(Typography.headline)
                                .foregroundStyle(ColorTokens.textPrimary)

                            severityBadge(point.severity)
                        }
                    }
                    .padding(.vertical, Spacing.xs)

                    if point.id != frictionPoints.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Detector Health

    /// List of signal detectors showing name, detection count,
    /// false positive rate, and active/inactive status.
    private var detectorHealthSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Detector Health")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let detectors = viewModel.detectorHealthRanked

            if detectors.isEmpty {
                Text("No detector data available")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else {
                ForEach(detectors) { detector in
                    HStack(spacing: Spacing.sm) {
                        // Active status indicator
                        Circle()
                            .fill(detector.isActive ? ColorTokens.success : ColorTokens.textTertiary)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(detector.detectorName)
                                .font(Typography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorTokens.textPrimary)

                            HStack(spacing: Spacing.sm) {
                                Text("\(detector.totalDetections) detections")
                                    .font(Typography.caption2)
                                    .foregroundStyle(ColorTokens.textSecondary)

                                Text("FPR: \(String(format: "%.0f%%", detector.estimatedFalsePositiveRate * 100))")
                                    .font(Typography.caption2)
                                    .foregroundStyle(
                                        detector.estimatedFalsePositiveRate > 0.15
                                            ? ColorTokens.warning
                                            : ColorTokens.textTertiary
                                    )
                            }
                        }

                        Spacer()

                        // Status badge
                        Text(detector.isActive ? "Active" : "Inactive")
                            .font(Typography.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(
                                (detector.isActive ? ColorTokens.success : ColorTokens.textTertiary)
                                    .opacity(0.15)
                            )
                            .foregroundStyle(detector.isActive ? ColorTokens.success : ColorTokens.textTertiary)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, Spacing.xs)

                    if detector.id != detectors.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Loading / Error States

    private var loadingPlaceholder: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(ColorTokens.backgroundTertiary)
                    .frame(height: 120)
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Failed to Load",
            message: message
        )
    }

    // MARK: - Private Helpers

    /// A severity badge pill.
    private func severityBadge(_ severity: Severity) -> some View {
        Text(severity.rawValue.capitalized)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 1)
            .background(severityColor(severity).opacity(0.15))
            .foregroundStyle(severityColor(severity))
            .clipShape(Capsule())
    }

    /// Returns a color for a severity level.
    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low: return ColorTokens.info
        case .medium: return ColorTokens.warning
        case .high: return .orange
        case .critical: return ColorTokens.error
        }
    }

    /// Returns a color for a trend direction.
    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return ColorTokens.error
        case .decreasing: return ColorTokens.success
        case .stable: return ColorTokens.textSecondary
        }
    }

    /// Returns a human-readable name for a signal type.
    private func signalTypeName(_ type: SignalType) -> String {
        switch type {
        case .rageTap: return "Rage Tap"
        case .deadTap: return "Dead Tap"
        case .abandon: return "Abandon"
        case .errorBurst: return "Error Burst"
        case .longPressFrustration: return "Long Press"
        case .excessiveScroll: return "Excess Scroll"
        case .latencySpike: return "Latency Spike"
        }
    }

    /// Returns a color for a signal type.
    private func signalTypeColor(_ type: SignalType) -> Color {
        switch type {
        case .rageTap: return .red
        case .deadTap: return .orange
        case .abandon: return .purple
        case .errorBurst: return Color(red: 0.8, green: 0.1, blue: 0.1)
        case .longPressFrustration: return .pink
        case .excessiveScroll: return .teal
        case .latencySpike: return .blue
        }
    }

    /// Formats a timestamp as a relative time string (e.g., "2m ago", "1h ago").
    private func relativeTimeString(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Interaction Signals") {
    InteractionSignalsView(
        viewModel: InteractionSignalsViewModel(dataService: MockDashboardDataService())
    )
}
#endif
