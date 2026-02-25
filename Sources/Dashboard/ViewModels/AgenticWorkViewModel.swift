import Foundation
import Models
import Common
import Analytics

// MARK: - AgenticWorkViewModel

/// View model for the agentic work panel, surfacing orchestration status,
/// pipeline progress, experiment registry, active experiment monitoring,
/// and agent activity logs.
///
/// This is the human-facing companion to the autonomous Experimentation
/// Agent that will be built in M9.
@Observable
@MainActor
public final class AgenticWorkViewModel {

    // MARK: - State

    /// The loaded agentic work metrics. `nil` when not yet loaded.
    public private(set) var metrics: AgenticWorkMetrics?

    /// Whether data is currently loading.
    public private(set) var isLoading: Bool = false

    /// An error message if loading fails.
    public private(set) var errorMessage: String?

    /// The currently selected experiment summary for detail display. `nil` if none.
    public var selectedExperiment: ExperimentSummary?

    /// The currently selected active experiment (set from the experiment cards). `nil` if none.
    public var selectedActiveExperiment: ActiveExperimentStatus?

    // MARK: - Dependencies

    private let dataService: any DashboardDataServiceProtocol
    private let tracker: (any InteractionTracking)?

    // MARK: - Init

    /// Creates a new agentic work view model.
    ///
    /// - Parameters:
    ///   - dataService: The data service for fetching agentic work metrics.
    ///   - tracker: An optional interaction tracker for analytics.
    public init(
        dataService: any DashboardDataServiceProtocol,
        tracker: (any InteractionTracking)? = nil
    ) {
        self.dataService = dataService
        self.tracker = tracker
    }

    // MARK: - Actions

    /// Loads agentic work metrics for the given time range.
    ///
    /// Emits an `agentic_work_loaded` analytics event upon success.
    public func loadMetrics(timeRange: DashboardTimeRange) async {
        isLoading = true
        errorMessage = nil

        do {
            metrics = try await dataService.fetchAgenticWork(timeRange: timeRange)

            trackEvent(
                type: .navigate,
                screen: "Dashboard.AgenticWork",
                metadata: [
                    "event_name": "agentic_work_loaded",
                    "time_range": timeRange.rawValue,
                    "active_experiments": "\(metrics?.activeExperiments.count ?? 0)",
                    "orchestration_phase": metrics?.orchestrationState.currentPhase ?? "UNKNOWN"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load agentic work metrics: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Selects an experiment for detailed display.
    ///
    /// Emits an `experiment_selected` analytics event.
    public func selectExperiment(_ experiment: ExperimentSummary?) {
        selectedExperiment = experiment

        if let experiment {
            trackEvent(
                type: .tap,
                screen: "Dashboard.AgenticWork",
                metadata: [
                    "event_name": "experiment_selected",
                    "experiment_id": experiment.id.uuidString,
                    "experiment_name": experiment.name,
                    "experiment_status": experiment.status.rawValue
                ]
            )
        }
    }

    // MARK: - Computed Properties

    /// Pipeline items grouped by status for Kanban-style display.
    public var pipelineByStatus: [(status: PipelineItemStatus, items: [PipelineItem])] {
        let allStatuses = PipelineItemStatus.allCases
        let items = metrics?.pipelineStatus ?? []

        return allStatuses.map { status in
            (status: status, items: items.filter { $0.status == status })
        }
    }

    /// Currently running experiments.
    public var activeExperimentsList: [ActiveExperimentStatus] {
        metrics?.activeExperiments ?? []
    }

    /// Experiment win rate formatted as percentage (e.g. "56.0%").
    public var experimentWinRate: String {
        guard let stats = metrics?.experimentStats else { return "--" }
        return String(format: "%.1f%%", stats.winRate * 100)
    }

    /// Alias for `experimentWinRate` used by existing views.
    public var formattedWinRate: String { experimentWinRate }

    /// Auto-integration rate formatted as percentage (e.g. "70.0%").
    public var autoIntegrationRate: String {
        guard let stats = metrics?.experimentStats else { return "--" }
        return String(format: "%.1f%%", stats.autoIntegrationRate * 100)
    }

    /// Alias for `autoIntegrationRate` used by existing views.
    public var formattedAutoIntegrationRate: String { autoIntegrationRate }

    /// Average experiment duration formatted (e.g. "7.0 days").
    public var averageExperimentDuration: String {
        guard let stats = metrics?.experimentStats else { return "--" }
        let days = stats.averageDuration / 86_400
        return String(format: "%.1f days", days)
    }

    /// Recent agent activity entries sorted by timestamp (most recent first).
    public var recentAgentActivity: [AgentActivityEntry] {
        guard let metrics else { return [] }
        return metrics.agentActivityLog.sorted { $0.timestamp > $1.timestamp }
    }

    /// All experiments from the registry.
    public var allExperiments: [ExperimentSummary] {
        metrics?.experiments ?? []
    }

    /// Concluded experiments only.
    public var concludedExperiments: [ExperimentSummary] {
        allExperiments.filter { $0.status == .concluded || $0.status == .rolledBack }
    }

    /// Draft experiments only.
    public var draftExperiments: [ExperimentSummary] {
        allExperiments.filter { $0.status == .draft }
    }

    /// Current orchestration phase label.
    public var orchestrationPhase: String {
        metrics?.orchestrationState.currentPhase ?? "--"
    }

    /// Number of active agents.
    public var activeAgentCount: Int {
        metrics?.orchestrationState.activeAgents ?? 0
    }

    /// Formatted time remaining from a date to human-readable string.
    public func formattedTimeRemaining(until endDate: Date) -> String {
        let interval = endDate.timeIntervalSince(Date())
        guard interval > 0 else { return "Ending soon" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }

    // MARK: - Private Helpers

    private func trackEvent(
        type: InteractionType,
        screen: String,
        metadata: [String: String]
    ) {
        let event = InteractionEvent(
            type: type,
            screen: screen,
            metadata: metadata
        )
        guard let tracker else { return }
        Task {
            await tracker.track(event)
        }
    }
}
