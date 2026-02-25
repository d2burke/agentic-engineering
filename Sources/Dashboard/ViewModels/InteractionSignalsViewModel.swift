import Foundation
import Observation
import Models
import Common
import Analytics

// MARK: - InteractionSignalsViewModel

/// View model for the interaction signals panel, providing live signal
/// feeds, heatmap data, trend charts, friction point rankings, and
/// detector health status.
///
/// This view model surfaces the SAME data that the Experimentation Agent
/// analyzes autonomously, giving human operators a real-time window
/// into behavioral signal patterns.
@Observable
@MainActor
public final class InteractionSignalsViewModel {

    // MARK: - State

    /// The loaded interaction signal metrics. `nil` when not yet loaded.
    public private(set) var metrics: InteractionSignalMetrics?

    /// Whether data is currently loading.
    public private(set) var isLoading: Bool = false

    /// An error message if loading fails.
    public private(set) var errorMessage: String?

    /// The currently selected signal type filter. `nil` means show all.
    public var selectedSignalType: SignalType?

    /// Whether the live signal feed is actively streaming.
    public var isStreamingLive: Bool = false

    // MARK: - Dependencies

    private let dataService: any DashboardDataServiceProtocol
    private let tracker: (any InteractionTracking)?

    // MARK: - Init

    /// Creates a new interaction signals view model.
    ///
    /// - Parameters:
    ///   - dataService: The data service for fetching signal metrics.
    ///   - tracker: An optional interaction tracker for analytics.
    public init(
        dataService: any DashboardDataServiceProtocol,
        tracker: (any InteractionTracking)? = nil
    ) {
        self.dataService = dataService
        self.tracker = tracker
    }

    // MARK: - Actions

    /// Loads interaction signal metrics for the given time range.
    ///
    /// Emits an `interaction_signals_loaded` analytics event upon success.
    public func loadMetrics(timeRange: DashboardTimeRange) async {
        isLoading = true
        errorMessage = nil

        do {
            metrics = try await dataService.fetchInteractionSignals(timeRange: timeRange)

            trackEvent(
                type: .navigate,
                screen: "Dashboard.InteractionSignals",
                metadata: [
                    "event_name": "interaction_signals_loaded",
                    "time_range": timeRange.rawValue,
                    "total_signals": "\(metrics?.totalSignals ?? 0)",
                    "signal_rate": String(format: "%.1f", metrics?.signalRate ?? 0)
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load interaction signals: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Sets a signal type filter to narrow the feed.
    ///
    /// Emits a `signal_filter_changed` analytics event.
    public func filterBySignalType(_ type: SignalType?) {
        selectedSignalType = type

        trackEvent(
            type: .tap,
            screen: "Dashboard.InteractionSignals",
            metadata: [
                "event_name": "signal_filter_changed",
                "filter": type?.rawValue ?? "all"
            ]
        )
    }

    /// Clears the active signal type filter.
    public func clearFilter() {
        filterBySignalType(nil)
    }

    /// Toggles the live streaming state.
    public func toggleLiveStreaming() {
        isStreamingLive.toggle()
    }

    // MARK: - Computed Properties

    /// Recent signals filtered by the current signal type selection.
    public var filteredSignals: [SignalFeedItem] {
        guard let signals = metrics?.recentSignals else { return [] }
        if let selectedType = selectedSignalType {
            return signals.filter { $0.signalType == selectedType }
        }
        return signals
    }

    /// Heatmap data: per-screen signal summaries sorted by total signals (descending).
    ///
    /// Each entry contains counts per signal type and severity breakdown,
    /// suitable for rendering a grid heatmap visualization.
    public var heatmapData: [ScreenSignalSummary] {
        guard let metrics else { return [] }
        return metrics.signalsByScreen.sorted { $0.totalSignals > $1.totalSignals }
    }

    /// Trend chart data, optionally filtered by selected signal type.
    public var trendChartData: [SignalTrendData] {
        guard let metrics else { return [] }
        if let selectedType = selectedSignalType {
            return metrics.signalTrends.filter { $0.signalType == selectedType }
        }
        return metrics.signalTrends
    }

    /// Friction points ranked by severity (descending), then count (descending).
    public var frictionPointsRanked: [FrictionPoint] {
        guard let metrics else { return [] }
        return metrics.topFrictionPoints.sorted { lhs, rhs in
            if lhs.severity != rhs.severity {
                return lhs.severity > rhs.severity
            }
            return lhs.count > rhs.count
        }
    }

    /// Detector health metrics sorted by detection count (descending).
    public var detectorHealthRanked: [DetectorHealthMetric] {
        guard let metrics else { return [] }
        return metrics.detectorHealth.sorted { $0.totalDetections > $1.totalDetections }
    }

    /// Formatted total signal count.
    public var formattedTotalSignals: String {
        guard let metrics else { return "--" }
        return "\(metrics.totalSignals)"
    }

    /// Formatted signal rate per hour.
    public var formattedSignalRate: String {
        guard let metrics else { return "--" }
        return String(format: "%.1f/hr", metrics.signalRate)
    }

    /// All available signal types for filter chips.
    public var availableSignalTypes: [SignalType] {
        SignalType.allCases
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
