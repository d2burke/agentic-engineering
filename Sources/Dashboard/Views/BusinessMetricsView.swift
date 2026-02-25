import SwiftUI
import Charts
import DesignSystem
import Analytics
import Models

// MARK: - BusinessMetricsView

/// The business metrics panel displaying KPI cards, user growth chart,
/// task throughput chart, status distribution, team velocity, and
/// top contributors.
public struct BusinessMetricsView: View {
    private let viewModel: BusinessMetricsViewModel

    /// Creates a business metrics view.
    ///
    /// - Parameter viewModel: The business metrics view model.
    public init(viewModel: BusinessMetricsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                if viewModel.metrics != nil {
                    kpiCardsRow
                    userGrowthChart
                    taskThroughputChart
                    statusDistributionChart
                    teamVelocityChart
                    topContributorsSection
                } else if viewModel.isLoading {
                    loadingPlaceholder
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No Business Metrics",
                        message: "Business metrics will appear here once data is loaded."
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .background(ColorTokens.backgroundSecondary)
        .trackInteraction(screen: "DashboardBusiness")
    }

    // MARK: - KPI Cards Row

    /// Horizontal scrolling row of KPI metric cards.
    private var kpiCardsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                MetricCard(
                    title: "Daily Active Users",
                    value: viewModel.formattedDAU,
                    icon: "person.fill"
                )

                MetricCard(
                    title: "Weekly Active Users",
                    value: viewModel.formattedWAU,
                    icon: "person.2.fill"
                )

                MetricCard(
                    title: "Monthly Active Users",
                    value: viewModel.formattedMAU,
                    icon: "person.3.fill"
                )

                MetricCard(
                    title: "Completion Rate",
                    value: viewModel.formattedCompletionRate,
                    subtitle: viewModel.formattedAverageCompletionTime,
                    icon: "checkmark.circle.fill"
                )
            }
        }
    }

    // MARK: - User Growth Chart

    /// Line chart showing active user growth over time.
    private var userGrowthChart: some View {
        TimeSeriesChart(
            data: viewModel.growthChartData,
            title: "User Growth",
            color: ColorTokens.primary,
            showArea: true
        )
    }

    // MARK: - Task Throughput Chart

    /// Line chart showing tasks completed over time.
    private var taskThroughputChart: some View {
        TimeSeriesChart(
            data: viewModel.throughputChartData,
            title: "Task Throughput",
            color: ColorTokens.success,
            showArea: false
        )
    }

    // MARK: - Status Distribution Chart

    /// Donut-style pie chart showing distribution of tasks by status.
    private var statusDistributionChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Status Distribution")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let distribution = viewModel.sortedStatusDistribution

            if distribution.isEmpty {
                Text("No data available")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                Chart(distribution, id: \.status) { entry in
                    SectorMark(
                        angle: .value("Count", entry.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(statusColor(for: entry.status))
                    .cornerRadius(4)
                }
                .frame(height: 200)

                // Legend
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: Spacing.sm) {
                    ForEach(distribution, id: \.status) { entry in
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(statusColor(for: entry.status))
                                .frame(width: 8, height: 8)

                            Text(statusDisplayName(for: entry.status))
                                .font(Typography.caption2)
                                .foregroundStyle(ColorTokens.textSecondary)

                            Spacer()

                            Text("\(entry.count)")
                                .font(Typography.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(ColorTokens.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Team Velocity Chart

    /// Bar chart showing team velocity (tasks completed vs created) per period.
    private var teamVelocityChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Team Velocity")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let velocityData = viewModel.velocityChartData

            if velocityData.isEmpty {
                Text("No velocity data available")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                // Legend
                HStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xxs) {
                        Circle()
                            .fill(ColorTokens.success)
                            .frame(width: 8, height: 8)
                        Text("Completed")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    HStack(spacing: Spacing.xxs) {
                        Circle()
                            .fill(ColorTokens.info)
                            .frame(width: 8, height: 8)
                        Text("Created")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                Chart(velocityData) { dataPoint in
                    BarMark(
                        x: .value("Period", dataPoint.periodLabel),
                        y: .value("Tasks", dataPoint.tasksCompleted)
                    )
                    .foregroundStyle(ColorTokens.success)
                    .position(by: .value("Type", "Completed"))

                    BarMark(
                        x: .value("Period", dataPoint.periodLabel),
                        y: .value("Tasks", dataPoint.tasksCreated)
                    )
                    .foregroundStyle(ColorTokens.info)
                    .position(by: .value("Type", "Created"))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(ColorTokens.divider)
                        AxisValueLabel()
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Top Contributors Section

    /// Ranked list of top contributors with avatar, name, and tasks completed.
    private var topContributorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Top Contributors")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let contributors = viewModel.topContributorsList

            if contributors.isEmpty {
                Text("No contributor data available")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            } else {
                ForEach(Array(contributors.enumerated()), id: \.element.id) { index, contributor in
                    HStack(spacing: Spacing.md) {
                        // Rank number
                        Text("#\(index + 1)")
                            .font(Typography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(rankColor(for: index))
                            .frame(width: 30, alignment: .leading)

                        // Avatar
                        AvatarView(name: contributor.displayName, size: 32)

                        // Name and stats
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(contributor.displayName)
                                .font(Typography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorTokens.textPrimary)

                            Text("\(contributor.tasksCreated) created, \(contributor.commentsAdded) comments")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }

                        Spacer()

                        // Tasks completed
                        VStack(alignment: .trailing, spacing: Spacing.xxs) {
                            Text("\(contributor.tasksCompleted)")
                                .font(Typography.headline)
                                .foregroundStyle(ColorTokens.textPrimary)

                            Text("completed")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)

                    if index < contributors.count - 1 {
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

    /// Returns a color for a TaskStatus raw value string.
    private func statusColor(for statusKey: String) -> Color {
        switch statusKey {
        case TaskStatus.todo.rawValue:
            return .gray
        case TaskStatus.inProgress.rawValue:
            return ColorTokens.info
        case TaskStatus.inReview.rawValue:
            return ColorTokens.warning
        case TaskStatus.done.rawValue:
            return ColorTokens.success
        case TaskStatus.archived.rawValue:
            return ColorTokens.secondary
        default:
            return .gray
        }
    }

    /// Returns a display name for a TaskStatus raw value string.
    private func statusDisplayName(for statusKey: String) -> String {
        switch statusKey {
        case TaskStatus.todo.rawValue: return "To Do"
        case TaskStatus.inProgress.rawValue: return "In Progress"
        case TaskStatus.inReview.rawValue: return "In Review"
        case TaskStatus.done.rawValue: return "Done"
        case TaskStatus.archived.rawValue: return "Archived"
        default: return statusKey.capitalized
        }
    }

    /// Returns a color for contributor rank (gold, silver, bronze, then default).
    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return ColorTokens.textSecondary
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Business Metrics") {
    BusinessMetricsView(
        viewModel: BusinessMetricsViewModel(dataService: MockDashboardDataService())
    )
}
#endif
