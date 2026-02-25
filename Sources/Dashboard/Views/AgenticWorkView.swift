import SwiftUI
import Charts
import DesignSystem
import Analytics

// MARK: - AgenticWorkView

/// The agentic work monitoring panel displaying orchestration status,
/// development pipeline (Kanban), experiment statistics, active experiments,
/// experiment history, and agent activity log.
public struct AgenticWorkView: View {
    @Bindable private var viewModel: AgenticWorkViewModel

    /// Creates an agentic work view.
    ///
    /// - Parameter viewModel: The agentic work view model.
    public init(viewModel: AgenticWorkViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                if viewModel.metrics != nil {
                    orchestrationStatusCard
                    developmentPipeline
                    experimentStatsCards
                    activeExperimentsSection
                    experimentHistorySection
                    agentActivityLogSection
                } else if viewModel.isLoading {
                    loadingPlaceholder
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    EmptyStateView(
                        icon: "cpu",
                        title: "No Agentic Data",
                        message: "Agentic work metrics will appear here once data is loaded."
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .background(ColorTokens.backgroundSecondary)
        .trackInteraction(screen: "DashboardAgentic")
    }

    // MARK: - Orchestration Status Card

    /// Shows current phase, active agents count, and pending tasks.
    private var orchestrationStatusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Orchestration Status")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer()

                // Phase badge
                let phase = viewModel.metrics?.orchestrationState.currentPhase ?? "UNKNOWN"
                Text(phase)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(phaseColor(phase).opacity(0.15))
                    .foregroundStyle(phaseColor(phase))
                    .clipShape(Capsule())
            }

            HStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xxs) {
                    Text("\(viewModel.metrics?.orchestrationState.activeAgents ?? 0)")
                        .font(Typography.title2)
                        .foregroundStyle(ColorTokens.primary)

                    Text("Active Agents")
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 50)

                VStack(spacing: Spacing.xxs) {
                    Text("\(viewModel.metrics?.orchestrationState.pendingTasks ?? 0)")
                        .font(Typography.title2)
                        .foregroundStyle(ColorTokens.warning)

                    Text("Pending Tasks")
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            if let lastActivity = viewModel.metrics?.orchestrationState.lastActivity {
                Text("Last activity: \(relativeTimeString(lastActivity))")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Development Pipeline (Kanban)

    /// Kanban-style horizontal scroll showing features by status.
    private var developmentPipeline: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Development Pipeline")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    ForEach(viewModel.pipelineByStatus, id: \.status) { group in
                        pipelineColumn(status: group.status, items: group.items)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    /// A single Kanban column for a pipeline status.
    private func pipelineColumn(status: PipelineItemStatus, items: [PipelineItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Column header
            HStack(spacing: Spacing.xs) {
                Text(status.displayName)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(pipelineStatusColor(status))

                Text("\(items.count)")
                    .font(Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(ColorTokens.backgroundTertiary)
                    .clipShape(Capsule())
            }

            // Column items
            if items.isEmpty {
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .strokeBorder(ColorTokens.divider, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(height: 60)
                    .overlay(
                        Text("Empty")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textTertiary)
                    )
            } else {
                ForEach(items) { item in
                    pipelineItemCard(item)
                }
            }
        }
        .frame(width: 160)
    }

    /// A single pipeline item card.
    private func pipelineItemCard(_ item: PipelineItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(item.featureName)
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(2)

            Text(item.milestone)
                .font(Typography.caption2)
                .foregroundStyle(ColorTokens.textTertiary)

            if let agent = item.assignedAgent {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "cpu")
                        .font(.system(size: 8))
                    Text(agent)
                        .font(Typography.caption2)
                }
                .foregroundStyle(ColorTokens.accent)
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }

    // MARK: - Experiment Stats Cards

    /// KPI cards for experiment statistics.
    private var experimentStatsCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                MetricCard(
                    title: "Total Experiments",
                    value: "\(viewModel.metrics?.experimentStats.totalExperiments ?? 0)",
                    icon: "flask.fill"
                )

                MetricCard(
                    title: "Win Rate",
                    value: viewModel.experimentWinRate,
                    icon: "trophy.fill"
                )

                MetricCard(
                    title: "Auto-Integration",
                    value: viewModel.autoIntegrationRate,
                    icon: "arrow.triangle.merge"
                )

                MetricCard(
                    title: "This Period",
                    value: "\(viewModel.metrics?.experimentStats.experimentsThisPeriod ?? 0)",
                    icon: "calendar"
                )
            }
        }
    }

    // MARK: - Active Experiments

    /// Cards for each running experiment.
    private var activeExperimentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Active Experiments")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let activeExperiments = viewModel.metrics?.activeExperiments ?? []

            if activeExperiments.isEmpty {
                Text("No experiments currently running")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else {
                ForEach(activeExperiments) { experiment in
                    ExperimentCard(experiment: experiment) {
                        viewModel.selectedActiveExperiment = experiment
                    }
                }
            }
        }
    }

    // MARK: - Experiment History

    /// List of concluded experiments with outcome badge.
    private var experimentHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Experiment History")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let history = viewModel.concludedExperiments

            if history.isEmpty {
                Text("No concluded experiments")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else {
                ForEach(history) { experiment in
                    HStack(spacing: Spacing.sm) {
                        // Outcome badge
                        if let outcome = experiment.outcome {
                            outcomeBadge(outcome)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(experiment.name)
                                .font(Typography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .lineLimit(1)

                            HStack(spacing: Spacing.sm) {
                                Text(experiment.primaryMetric)
                                    .font(Typography.caption2)
                                    .foregroundStyle(ColorTokens.textSecondary)

                                if let result = experiment.primaryMetricResult {
                                    Text(String(format: "%+.1f%%", result * 100))
                                        .font(Typography.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(result > 0 ? ColorTokens.success : ColorTokens.error)
                                }
                            }
                        }

                        Spacer()

                        // Auto-integrated badge
                        if experiment.autoIntegrated {
                            HStack(spacing: Spacing.xxs) {
                                Image(systemName: "arrow.triangle.merge")
                                    .font(.system(size: 9))
                                Text("Integrated")
                                    .font(Typography.caption2)
                            }
                            .foregroundStyle(ColorTokens.success)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(ColorTokens.success.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, Spacing.xs)

                    if experiment.id != history.last?.id {
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

    // MARK: - Agent Activity Log

    /// Timeline view of recent agent actions.
    private var agentActivityLogSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Agent Activity Log")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            let activities = viewModel.metrics?.agentActivityLog ?? []

            if activities.isEmpty {
                Text("No agent activity recorded")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else {
                ForEach(activities) { entry in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        // Timeline dot and line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(actionStatusColor(entry.status))
                                .frame(width: 10, height: 10)

                            if entry.id != activities.last?.id {
                                Rectangle()
                                    .fill(ColorTokens.divider)
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 10)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            HStack(spacing: Spacing.xs) {
                                // Agent role badge
                                Text(entry.agentRole)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 1)
                                    .background(ColorTokens.accent.opacity(0.15))
                                    .foregroundStyle(ColorTokens.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                                Text(entry.action.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(Typography.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ColorTokens.textPrimary)

                                Spacer()

                                // Status badge
                                actionStatusBadge(entry.status)
                            }

                            Text(entry.description)
                                .font(Typography.caption)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .lineLimit(3)

                            HStack(spacing: Spacing.sm) {
                                Text(relativeTimeString(entry.timestamp))
                                    .font(Typography.caption2)
                                    .foregroundStyle(ColorTokens.textTertiary)

                                if let feature = entry.relatedFeature {
                                    HStack(spacing: 2) {
                                        Image(systemName: "link")
                                            .font(.system(size: 8))
                                        Text(feature)
                                            .font(Typography.caption2)
                                    }
                                    .foregroundStyle(ColorTokens.info)
                                }
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
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

    /// Returns a color for the orchestration phase.
    private func phaseColor(_ phase: String) -> Color {
        switch phase.uppercased() {
        case "IDLE": return ColorTokens.textSecondary
        case "PLANNING": return ColorTokens.info
        case "EXECUTING": return ColorTokens.success
        case "EVALUATING": return ColorTokens.warning
        default: return ColorTokens.textSecondary
        }
    }

    /// Returns a color for a pipeline item status.
    private func pipelineStatusColor(_ status: PipelineItemStatus) -> Color {
        switch status {
        case .planned: return ColorTokens.textSecondary
        case .inProgress: return ColorTokens.info
        case .reviewing: return ColorTokens.warning
        case .testing: return ColorTokens.accent
        case .completed: return ColorTokens.success
        case .failed: return ColorTokens.error
        }
    }

    /// Returns a badge for an experiment outcome.
    private func outcomeBadge(_ outcome: ExperimentOutcome) -> some View {
        let (color, icon): (Color, String) = {
            switch outcome {
            case .positive: return (ColorTokens.success, "checkmark.circle.fill")
            case .negative: return (ColorTokens.error, "xmark.circle.fill")
            case .inconclusive: return (ColorTokens.textSecondary, "questionmark.circle.fill")
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundStyle(color)
    }

    /// Returns a color for an agent action status.
    private func actionStatusColor(_ status: AgentActionStatus) -> Color {
        switch status {
        case .started: return ColorTokens.info
        case .completed: return ColorTokens.success
        case .failed: return ColorTokens.error
        case .blocked: return ColorTokens.warning
        }
    }

    /// Returns a badge view for an agent action status.
    private func actionStatusBadge(_ status: AgentActionStatus) -> some View {
        let displayName: String = {
            switch status {
            case .started: return "Started"
            case .completed: return "Done"
            case .failed: return "Failed"
            case .blocked: return "Blocked"
            }
        }()

        return Text(displayName)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 1)
            .background(actionStatusColor(status).opacity(0.15))
            .foregroundStyle(actionStatusColor(status))
            .clipShape(Capsule())
    }

    /// Formats a timestamp as a relative time string.
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
#Preview("Agentic Work") {
    AgenticWorkView(
        viewModel: AgenticWorkViewModel(dataService: MockDashboardDataService())
    )
}
#endif
