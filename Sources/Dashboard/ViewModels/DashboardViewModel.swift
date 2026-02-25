import Foundation
import Models
import Common
import Analytics

// MARK: - DashboardViewModel

/// Root coordinating view model for the dashboard.
///
/// Manages panel selection, time range, loading state, access control,
/// and alert management. Delegates section-specific data loading to
/// child view models while owning the cross-cutting concerns of
/// authentication gating and analytics event emission.
@Observable
@MainActor
public final class DashboardViewModel {

    // MARK: - Published State

    /// The currently selected dashboard panel.
    public var selectedPanel: DashboardPanel = .business

    /// The selected time range for data filtering.
    public var selectedTimeRange: DashboardTimeRange = .week

    /// Whether the dashboard is currently loading data.
    public private(set) var isLoading: Bool = false

    /// An error message to display if data loading fails.
    public private(set) var errorMessage: String?

    /// The access level of the current user.
    public private(set) var accessLevel: DashboardAccessLevel = .viewer

    /// Active dashboard alerts.
    public private(set) var alerts: [DashboardAlert] = []

    // MARK: - Dependencies

    private let dataService: any DashboardDataServiceProtocol
    private let authGate: any DashboardAuthGateProtocol
    private let tracker: (any InteractionTracking)?
    private let currentUser: User

    // MARK: - Init

    /// Creates a new dashboard view model.
    ///
    /// - Parameters:
    ///   - dataService: The data service for fetching dashboard metrics.
    ///   - authGate: The authorization gate for panel access control.
    ///   - currentUser: The currently authenticated user.
    ///   - tracker: An optional interaction tracker for analytics. Pass `nil` to disable.
    public init(
        dataService: any DashboardDataServiceProtocol,
        authGate: any DashboardAuthGateProtocol,
        currentUser: User,
        tracker: (any InteractionTracking)? = nil
    ) {
        self.dataService = dataService
        self.authGate = authGate
        self.currentUser = currentUser
        self.tracker = tracker
        self.accessLevel = authGate.accessLevel(for: currentUser)
    }

    // MARK: - Actions

    /// Loads dashboard data for all accessible sections and alerts.
    ///
    /// Emits a `dashboard_view` analytics event upon successful load.
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            alerts = try await dataService.fetchAlerts()

            trackEvent(
                type: .navigate,
                screen: "Dashboard",
                metadata: [
                    "event_name": "dashboard_view",
                    "panel": selectedPanel.rawValue,
                    "time_range": selectedTimeRange.rawValue,
                    "access_level": accessLevel.rawValue,
                    "alert_count": "\(alerts.count)"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load dashboard data: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Switches to the given panel, enforcing access control.
    ///
    /// If the user lacks permission for the panel, the selection is
    /// not changed and an error message is set.
    ///
    /// Emits a `panel_switch` analytics event.
    public func selectPanel(_ panel: DashboardPanel) {
        guard authGate.canAccess(panel: panel, user: currentUser) else {
            errorMessage = "You do not have permission to view the \(panel.displayName) panel."
            return
        }

        let previousPanel = selectedPanel
        selectedPanel = panel

        trackEvent(
            type: .tap,
            screen: "Dashboard",
            metadata: [
                "event_name": "panel_switch",
                "from_panel": previousPanel.rawValue,
                "to_panel": panel.rawValue
            ]
        )
    }

    /// Updates the time range and triggers a data reload.
    ///
    /// Emits a `time_range_change` analytics event.
    public func selectTimeRange(_ timeRange: DashboardTimeRange) async {
        let previousRange = selectedTimeRange
        selectedTimeRange = timeRange

        trackEvent(
            type: .tap,
            screen: "Dashboard",
            metadata: [
                "event_name": "time_range_change",
                "from_range": previousRange.rawValue,
                "to_range": timeRange.rawValue
            ]
        )

        await loadData()
    }

    /// Acknowledges a specific alert by its identifier.
    ///
    /// Removes the alert from the local list and notifies the service.
    public func acknowledgeAlert(id: UUID) async {
        do {
            try await dataService.acknowledgeAlert(id: id)
            alerts.removeAll { $0.id == id }

            trackEvent(
                type: .tap,
                screen: "Dashboard",
                metadata: [
                    "event_name": "alert_acknowledged",
                    "alert_id": id.uuidString
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to acknowledge alert: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    // MARK: - Computed Properties

    /// Returns only unacknowledged alerts.
    public var unacknowledgedAlerts: [DashboardAlert] {
        alerts.filter { !$0.isAcknowledged }
    }

    /// Returns the set of panels the current user may access.
    public var accessiblePanels: [DashboardPanel] {
        DashboardPanel.allCases.filter { authGate.canAccess(panel: $0, user: currentUser) }
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
