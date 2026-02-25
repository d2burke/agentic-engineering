import SwiftUI
import Charts
import DesignSystem
import Analytics

// MARK: - AppPerformanceView

/// The app performance panel displaying health score cards, crash rate trend,
/// screen load times, network latency, resource usage, and offline queue status.
public struct AppPerformanceView: View {
    private let viewModel: AppPerformanceViewModel

    /// Creates an app performance view.
    ///
    /// - Parameter viewModel: The app performance view model.
    public init(viewModel: AppPerformanceViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                if viewModel.metrics != nil {
                    healthScoreCards
                    crashRateTrendChart
                    screenLoadTimesChart
                    networkLatencyTrendChart
                    resourceUsageChart
                    offlineQueueSection
                } else if viewModel.isLoading {
                    loadingPlaceholder
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    EmptyStateView(
                        icon: "speedometer",
                        title: "No Performance Data",
                        message: "App performance metrics will appear here once data is loaded."
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .background(ColorTokens.backgroundSecondary)
        .trackInteraction(screen: "DashboardPerformance")
    }

    // MARK: - Health Score Cards

    /// Row of health score KPI cards.
    private var healthScoreCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                MetricCard(
                    title: "Crash-Free Sessions",
                    value: viewModel.formattedCrashFreeRate,
                    icon: "checkmark.shield.fill"
                )

                MetricCard(
                    title: "Launch Time P50",
                    value: viewModel.formattedLaunchTime,
                    trendIsPositive: false,
                    icon: "clock.fill"
                )

                MetricCard(
                    title: "Network Error Rate",
                    value: viewModel.formattedNetworkErrorRate,
                    trendIsPositive: false,
                    icon: "wifi.exclamationmark"
                )

                MetricCard(
                    title: "Sync Success Rate",
                    value: viewModel.formattedSyncRate,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
    }

    // MARK: - Crash Rate Trend Chart

    /// Line chart of crash rate over time.
    private var crashRateTrendChart: some View {
        TimeSeriesChart(
            data: viewModel.metrics?.crashTrend ?? [],
            title: "Crash Rate Trend",
            color: ColorTokens.error,
            showArea: true
        )
    }

    // MARK: - Screen Load Times Chart

    /// Horizontal bar chart of screen load times sorted by P95.
    private var screenLoadTimesChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Screen Load Times")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            // Legend
            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xxs) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ColorTokens.info)
                        .frame(width: 12, height: 8)
                    Text("P50")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                HStack(spacing: Spacing.xxs) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ColorTokens.warning)
                        .frame(width: 12, height: 8)
                    Text("P95")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }

            let screens = viewModel.sortedScreenLoadTimes

            if screens.isEmpty {
                Text("No screen data available")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                Chart(screens) { screen in
                    BarMark(
                        x: .value("Latency", screen.loadTime.p50),
                        y: .value("Screen", screen.screenName)
                    )
                    .foregroundStyle(ColorTokens.info)
                    .position(by: .value("Percentile", "P50"))

                    BarMark(
                        x: .value("Latency", screen.loadTime.p95),
                        y: .value("Screen", screen.screenName)
                    )
                    .foregroundStyle(ColorTokens.warning)
                    .position(by: .value("Percentile", "P95"))
                }
                .frame(height: CGFloat(max(screens.count * 44, 200)))
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(ColorTokens.divider)
                        AxisValueLabel()
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .chartXAxisLabel("Milliseconds", alignment: .center)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Network Latency Trend Chart

    /// Multi-line chart of network request latency P50 and P95 over time.
    private var networkLatencyTrendChart: some View {
        MultiLineTimeSeriesChart(
            title: "Network Latency Trend",
            seriesData: [
                (
                    label: "P50",
                    data: viewModel.metrics?.networkMetrics.latencyTrend ?? [],
                    color: ColorTokens.info
                ),
            ]
        )
    }

    // MARK: - Resource Usage Chart

    /// Dual-line chart showing memory and CPU usage trends.
    private var resourceUsageChart: some View {
        MultiLineTimeSeriesChart(
            title: "Resource Usage",
            seriesData: [
                (
                    label: "Memory (MB)",
                    data: viewModel.metrics?.memoryUsage ?? [],
                    color: ColorTokens.accent
                ),
                (
                    label: "CPU (%)",
                    data: viewModel.metrics?.cpuUsage ?? [],
                    color: ColorTokens.warning
                ),
            ]
        )
    }

    // MARK: - Offline Queue Section

    /// Current offline queue depth indicator and sync success rate gauge.
    private var offlineQueueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Offline Queue")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            HStack(spacing: Spacing.xl) {
                // Queue depth indicator
                VStack(spacing: Spacing.xs) {
                    Text("\(viewModel.metrics?.offlineQueueDepth ?? 0)")
                        .font(Typography.title)
                        .foregroundStyle(queueDepthColor)

                    Text("Queued Items")
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 60)

                // Sync success rate gauge
                VStack(spacing: Spacing.xs) {
                    let syncRate = viewModel.metrics?.syncSuccessRate ?? 0
                    Gauge(value: syncRate, in: 0...1) {
                        Text("")
                    } currentValueLabel: {
                        Text(String(format: "%.1f%%", syncRate * 100))
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(syncRate > 0.95 ? ColorTokens.success : ColorTokens.warning)
                    .frame(width: 60, height: 60)

                    Text("Sync Success")
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .frame(maxWidth: .infinity)
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

    /// Returns a color based on offline queue depth.
    private var queueDepthColor: Color {
        let depth = viewModel.metrics?.offlineQueueDepth ?? 0
        if depth == 0 {
            return ColorTokens.success
        } else if depth < 10 {
            return ColorTokens.warning
        } else {
            return ColorTokens.error
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("App Performance") {
    AppPerformanceView(
        viewModel: AppPerformanceViewModel(dataService: MockDashboardDataService())
    )
}
#endif
