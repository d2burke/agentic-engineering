import Foundation
import Observation
import Models
import Common
import Analytics

// MARK: - AppPerformanceViewModel

/// View model for the app performance panel, surfacing crash rates,
/// launch times, screen load performance, network metrics, and sync health.
///
/// Fetches data from `DashboardDataServiceProtocol` and exposes
/// formatted computed properties ready for SwiftUI binding.
@Observable
@MainActor
public final class AppPerformanceViewModel {

    // MARK: - State

    /// The loaded performance metrics. `nil` when not yet loaded.
    public private(set) var metrics: AppPerformanceMetrics?

    /// Whether data is currently loading.
    public private(set) var isLoading: Bool = false

    /// An error message if loading fails.
    public private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let dataService: any DashboardDataServiceProtocol
    private let tracker: (any InteractionTracking)?

    // MARK: - Init

    /// Creates a new app performance view model.
    ///
    /// - Parameters:
    ///   - dataService: The data service for fetching performance metrics.
    ///   - tracker: An optional interaction tracker for analytics.
    public init(
        dataService: any DashboardDataServiceProtocol,
        tracker: (any InteractionTracking)? = nil
    ) {
        self.dataService = dataService
        self.tracker = tracker
    }

    // MARK: - Actions

    /// Loads app performance metrics for the given time range.
    ///
    /// Emits an `app_performance_loaded` analytics event upon success.
    public func loadMetrics(timeRange: DashboardTimeRange) async {
        isLoading = true
        errorMessage = nil

        do {
            metrics = try await dataService.fetchAppPerformance(timeRange: timeRange)

            trackEvent(
                type: .navigate,
                screen: "Dashboard.AppPerformance",
                metadata: [
                    "event_name": "app_performance_loaded",
                    "time_range": timeRange.rawValue,
                    "crash_rate": String(format: "%.2f", metrics?.crashRate ?? 0)
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load app performance metrics: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    // MARK: - Computed Properties

    /// Formatted crash rate as a percentage string (e.g. "0.48%").
    public var crashRateFormatted: String {
        guard let metrics else { return "--" }
        return String(format: "%.2f%%", metrics.crashRate)
    }

    /// Formatted crash-free sessions rate (e.g. "99.52%").
    public var crashFreeSessionsFormatted: String {
        guard let metrics else { return "--" }
        return String(format: "%.2f%%", metrics.crashFreeSessions)
    }

    /// Formatted p50 launch time (e.g. "320ms").
    public var launchTimeFormatted: String {
        guard let metrics else { return "--" }
        return formatLatency(metrics.launchTime.p50)
    }

    /// Formatted p95 launch time for context.
    public var launchTimeP95Formatted: String {
        guard let metrics else { return "--" }
        return formatLatency(metrics.launchTime.p95)
    }

    /// Formatted p99 launch time for context.
    public var launchTimeP99Formatted: String {
        guard let metrics else { return "--" }
        return formatLatency(metrics.launchTime.p99)
    }

    /// Screens sorted by p50 load time (slowest first) for performance ranking.
    public var screensSortedByLoadTime: [ScreenPerformance] {
        guard let metrics else { return [] }
        return metrics.screenLoadTimes.sorted { $0.loadTime.p50 > $1.loadTime.p50 }
    }

    /// Formatted network error rate (e.g. "2.3%").
    public var networkErrorRateFormatted: String {
        guard let metrics else { return "--" }
        return String(format: "%.1f%%", metrics.networkMetrics.errorRate * 100)
    }

    /// Formatted network latency p50 (e.g. "145ms").
    public var networkLatencyFormatted: String {
        guard let metrics else { return "--" }
        return formatLatency(metrics.networkMetrics.requestLatency.p50)
    }

    /// A textual health status for the offline sync subsystem.
    public var syncHealthStatus: String {
        guard let metrics else { return "--" }

        if metrics.syncSuccessRate >= 0.99 {
            return "Healthy"
        } else if metrics.syncSuccessRate >= 0.95 {
            return "Degraded"
        } else {
            return "Unhealthy"
        }
    }

    /// Formatted sync success rate (e.g. "98.7%").
    public var syncSuccessRateFormatted: String {
        guard let metrics else { return "--" }
        return String(format: "%.1f%%", metrics.syncSuccessRate * 100)
    }

    /// Offline queue depth as a display string.
    public var offlineQueueDepthFormatted: String {
        guard let metrics else { return "--" }
        return "\(metrics.offlineQueueDepth)"
    }

    /// Crash trend time series for chart rendering.
    public var crashTrendChartData: [TimeSeriesPoint] {
        guard let metrics else { return [] }
        return metrics.crashTrend.sorted { $0.date < $1.date }
    }

    /// Memory usage time series for chart rendering.
    public var memoryUsageChartData: [TimeSeriesPoint] {
        guard let metrics else { return [] }
        return metrics.memoryUsage.sorted { $0.date < $1.date }
    }

    /// CPU usage time series for chart rendering.
    public var cpuUsageChartData: [TimeSeriesPoint] {
        guard let metrics else { return [] }
        return metrics.cpuUsage.sorted { $0.date < $1.date }
    }

    /// Network latency trend for chart rendering.
    public var networkLatencyTrendChartData: [TimeSeriesPoint] {
        guard let metrics else { return [] }
        return metrics.networkMetrics.latencyTrend.sorted { $0.date < $1.date }
    }

    // MARK: - Backward-Compatible Aliases

    /// Alias for `crashFreeSessionsFormatted` used by existing views.
    public var formattedCrashFreeRate: String { crashFreeSessionsFormatted }

    /// Alias for `launchTimeFormatted` used by existing views.
    public var formattedLaunchTime: String { launchTimeFormatted }

    /// Alias for `networkErrorRateFormatted` used by existing views.
    public var formattedNetworkErrorRate: String { networkErrorRateFormatted }

    /// Alias for `syncSuccessRateFormatted` used by existing views.
    public var formattedSyncRate: String { syncSuccessRateFormatted }

    /// Alias for `screensSortedByLoadTime` used by existing views.
    public var sortedScreenLoadTimes: [ScreenPerformance] { screensSortedByLoadTime }

    // MARK: - Private Helpers

    private func formatLatency(_ ms: TimeInterval) -> String {
        if ms >= 1_000 {
            return String(format: "%.1fs", ms / 1_000)
        }
        return String(format: "%.0fms", ms)
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
