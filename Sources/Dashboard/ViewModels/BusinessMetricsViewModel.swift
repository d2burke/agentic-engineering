import Foundation
import Models
import Common
import Analytics

// MARK: - BusinessMetricsViewModel

/// View model for the business metrics panel, providing KPI data,
/// growth trends, task throughput, velocity charts, and contributor rankings.
///
/// Fetches data from `DashboardDataServiceProtocol` and exposes
/// formatted computed properties ready for SwiftUI binding.
@Observable
@MainActor
public final class BusinessMetricsViewModel {

    // MARK: - State

    /// The loaded business metrics. `nil` when not yet loaded.
    public private(set) var metrics: BusinessMetrics?

    /// Whether data is currently loading.
    public private(set) var isLoading: Bool = false

    /// An error message if loading fails.
    public private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let dataService: any DashboardDataServiceProtocol
    private let tracker: (any InteractionTracking)?

    // MARK: - Init

    /// Creates a new business metrics view model.
    ///
    /// - Parameters:
    ///   - dataService: The data service for fetching business metrics.
    ///   - tracker: An optional interaction tracker for analytics.
    public init(
        dataService: any DashboardDataServiceProtocol,
        tracker: (any InteractionTracking)? = nil
    ) {
        self.dataService = dataService
        self.tracker = tracker
    }

    // MARK: - Actions

    /// Loads business metrics for the given time range.
    ///
    /// Emits a `business_metrics_loaded` analytics event upon success.
    public func loadMetrics(timeRange: DashboardTimeRange) async {
        isLoading = true
        errorMessage = nil

        do {
            metrics = try await dataService.fetchBusinessMetrics(timeRange: timeRange)

            trackEvent(
                type: .navigate,
                screen: "Dashboard.BusinessMetrics",
                metadata: [
                    "event_name": "business_metrics_loaded",
                    "time_range": timeRange.rawValue,
                    "dau": "\(metrics?.activeUsers.dau ?? 0)",
                    "total_tasks": "\(metrics?.taskMetrics.totalTasks ?? 0)"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load business metrics: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    // MARK: - Computed Properties

    /// Formatted DAU value with abbreviation (e.g. "1.3K").
    public var formattedDAU: String {
        guard let metrics else { return "--" }
        return formatCompact(metrics.activeUsers.dau)
    }

    /// Formatted WAU value with abbreviation.
    public var formattedWAU: String {
        guard let metrics else { return "--" }
        return formatCompact(metrics.activeUsers.wau)
    }

    /// Formatted MAU value with abbreviation.
    public var formattedMAU: String {
        guard let metrics else { return "--" }
        return formatCompact(metrics.activeUsers.mau)
    }

    /// Formatted completion rate as percentage string (e.g. "73.0%").
    public var formattedCompletionRate: String {
        guard let metrics else { return "--" }
        return String(format: "%.1f%%", metrics.taskMetrics.completionRate * 100)
    }

    /// Top contributors sorted by tasks completed (descending).
    public var topContributorsList: [ContributorStats] {
        guard let metrics else { return [] }
        return metrics.topContributors.sorted { $0.tasksCompleted > $1.tasksCompleted }
    }

    /// Velocity data points suitable for chart rendering.
    public var velocityChartData: [VelocityDataPoint] {
        guard let metrics else { return [] }
        return metrics.teamVelocity.sorted { $0.date < $1.date }
    }

    /// User growth trend time series for chart rendering.
    public var growthChartData: [TimeSeriesPoint] {
        guard let metrics else { return [] }
        return metrics.activeUsers.growthTrend.sorted { $0.date < $1.date }
    }

    /// Task throughput trend time series for chart rendering.
    public var throughputChartData: [TimeSeriesPoint] {
        guard let metrics else { return [] }
        return metrics.taskMetrics.throughputTrend.sorted { $0.date < $1.date }
    }

    /// Formatted average completion time (e.g. "2.0 days").
    public var formattedAverageCompletionTime: String {
        guard let metrics else { return "--" }
        let days = metrics.taskMetrics.averageCompletionTime / 86_400
        if days >= 1 {
            return String(format: "%.1f days", days)
        }
        let hours = metrics.taskMetrics.averageCompletionTime / 3_600
        return String(format: "%.1f hours", hours)
    }

    /// Status distribution entries sorted by count descending.
    public var sortedStatusDistribution: [(status: String, count: Int)] {
        guard let metrics else { return [] }
        return metrics.taskMetrics.statusDistribution
            .sorted { $0.value > $1.value }
            .map { (status: $0.key, count: $0.value) }
    }

    // MARK: - Private Helpers

    private func formatCompact(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

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
