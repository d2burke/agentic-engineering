import Testing
import Foundation
@testable import Dashboard
@testable import Models
import Common
import Analytics

// MARK: - Test Mock: DashboardDataService

/// A mock data service for testing view model behavior without real data.
@MainActor
final class MockDashboardDataServiceForTests: DashboardDataServiceProtocol, @unchecked Sendable {

    var stubbedBusinessMetrics: BusinessMetrics?
    var stubbedAppPerformance: AppPerformanceMetrics?
    var stubbedInteractionSignals: InteractionSignalMetrics?
    var stubbedAgenticWork: AgenticWorkMetrics?
    var stubbedAlerts: [DashboardAlert] = []
    var stubbedError: Error?

    var acknowledgedAlertIds: [UUID] = []
    var fetchBusinessMetricsCallCount = 0
    var fetchAppPerformanceCallCount = 0
    var fetchInteractionSignalsCallCount = 0
    var fetchAgenticWorkCallCount = 0
    var fetchAlertsCallCount = 0

    func fetchBusinessMetrics(timeRange: DashboardTimeRange) async throws -> BusinessMetrics {
        fetchBusinessMetricsCallCount += 1
        if let error = stubbedError { throw error }
        guard let metrics = stubbedBusinessMetrics else {
            throw AppError.network("No stubbed data")
        }
        return metrics
    }

    func fetchAppPerformance(timeRange: DashboardTimeRange) async throws -> AppPerformanceMetrics {
        fetchAppPerformanceCallCount += 1
        if let error = stubbedError { throw error }
        guard let metrics = stubbedAppPerformance else {
            throw AppError.network("No stubbed data")
        }
        return metrics
    }

    func fetchInteractionSignals(timeRange: DashboardTimeRange) async throws -> InteractionSignalMetrics {
        fetchInteractionSignalsCallCount += 1
        if let error = stubbedError { throw error }
        guard let metrics = stubbedInteractionSignals else {
            throw AppError.network("No stubbed data")
        }
        return metrics
    }

    func fetchAgenticWork(timeRange: DashboardTimeRange) async throws -> AgenticWorkMetrics {
        fetchAgenticWorkCallCount += 1
        if let error = stubbedError { throw error }
        guard let metrics = stubbedAgenticWork else {
            throw AppError.network("No stubbed data")
        }
        return metrics
    }

    func fetchAlerts() async throws -> [DashboardAlert] {
        fetchAlertsCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedAlerts
    }

    func acknowledgeAlert(id: UUID) async throws {
        if let error = stubbedError { throw error }
        acknowledgedAlertIds.append(id)
    }
}

// MARK: - Test Mock: DashboardAuthGate

/// A mock auth gate that allows injecting access levels per test.
struct MockDashboardAuthGate: DashboardAuthGateProtocol {
    var fixedAccessLevel: DashboardAccessLevel = .admin

    func accessLevel(for user: User) -> DashboardAccessLevel {
        fixedAccessLevel
    }

    func canAccess(panel: DashboardPanel, user: User) -> Bool {
        DashboardAuthGate.allowedPanels(for: fixedAccessLevel).contains(panel)
    }
}

// MARK: - Test Mock: InteractionTracker

/// A mock interaction tracker that records tracked events for assertion.
actor TestInteractionTracker: InteractionTracking {
    var trackedEvents: [InteractionEvent] = []

    nonisolated let signalStream: AsyncStream<ExceptionalSignal>
    private let continuation: AsyncStream<ExceptionalSignal>.Continuation

    init() {
        var cont: AsyncStream<ExceptionalSignal>.Continuation!
        self.signalStream = AsyncStream { c in cont = c }
        self.continuation = cont
    }

    func track(_ event: InteractionEvent) async {
        trackedEvents.append(event)
    }

    func registerDetector(_ detector: any ExceptionalSignalDetector) async {}
    func registerExporter(_ exporter: any SignalExporter) async {}

    func eventCount() -> Int { trackedEvents.count }
}

// MARK: - Test Helpers

private func makeTestUser(role: UserRole = .admin) -> User {
    User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        email: "test@example.com",
        displayName: "Test User",
        role: role
    )
}

private func makeTestAlerts() -> [DashboardAlert] {
    [
        DashboardAlert(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
            type: .crashRateSpike,
            title: "Crash Rate Spike",
            message: "Crash rate elevated.",
            severity: .high
        ),
        DashboardAlert(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
            type: .signalBurst,
            title: "Signal Burst",
            message: "Signal burst detected.",
            severity: .critical
        ),
    ]
}

// MARK: - Tests

@Suite("DashboardViewModel Tests")
@MainActor
struct DashboardViewModelTests {

    // MARK: - Initial State

    @Test("Initial state has correct defaults")
    func initialState() {
        let service = MockDashboardDataServiceForTests()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        #expect(viewModel.selectedPanel == .business)
        #expect(viewModel.selectedTimeRange == .week)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.accessLevel == .admin)
        #expect(viewModel.alerts.isEmpty)
    }

    // MARK: - loadData

    @Test("loadData populates alerts on success")
    func loadDataPopulatesAlerts() async {
        let service = MockDashboardDataServiceForTests()
        service.stubbedAlerts = makeTestAlerts()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        await viewModel.loadData()

        #expect(viewModel.alerts.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(service.fetchAlertsCallCount == 1)
    }

    @Test("loadData sets error message on failure")
    func loadDataHandlesError() async {
        let service = MockDashboardDataServiceForTests()
        service.stubbedError = AppError.network("Connection failed")
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        await viewModel.loadData()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Panel Access Control

    @Test("Admin user can access all panels")
    func adminAccessAllPanels() {
        let service = MockDashboardDataServiceForTests()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser(role: .admin)

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        #expect(viewModel.accessiblePanels.count == DashboardPanel.allCases.count)
        for panel in DashboardPanel.allCases {
            #expect(viewModel.accessiblePanels.contains(panel))
        }
    }

    @Test("Member user can access business, appPerformance, and alerts only")
    func memberAccessLimitedPanels() {
        let service = MockDashboardDataServiceForTests()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .member)
        let user = makeTestUser(role: .member)

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        #expect(viewModel.accessLevel == .member)
        #expect(viewModel.accessiblePanels.contains(.business))
        #expect(viewModel.accessiblePanels.contains(.appPerformance))
        #expect(viewModel.accessiblePanels.contains(.alerts))
        #expect(!viewModel.accessiblePanels.contains(.interactionSignals))
        #expect(!viewModel.accessiblePanels.contains(.agenticWork))
    }

    @Test("Viewer user can access business panel only")
    func viewerAccessBusinessOnly() {
        let service = MockDashboardDataServiceForTests()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .viewer)
        let user = makeTestUser(role: .viewer)

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        #expect(viewModel.accessLevel == .viewer)
        #expect(viewModel.accessiblePanels == [.business])
    }

    @Test("Selecting unauthorized panel sets error and does not switch")
    func selectUnauthorizedPanelBlocked() {
        let service = MockDashboardDataServiceForTests()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .viewer)
        let user = makeTestUser(role: .viewer)

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        viewModel.selectPanel(.agenticWork)

        #expect(viewModel.selectedPanel == .business) // unchanged
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Selecting authorized panel switches correctly")
    func selectAuthorizedPanelSwitches() {
        let service = MockDashboardDataServiceForTests()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser(role: .admin)

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        viewModel.selectPanel(.interactionSignals)

        #expect(viewModel.selectedPanel == .interactionSignals)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Time Range Change

    @Test("Selecting time range triggers reload")
    func timeRangeChangeTriggersReload() async {
        let service = MockDashboardDataServiceForTests()
        service.stubbedAlerts = makeTestAlerts()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        await viewModel.selectTimeRange(.month)

        #expect(viewModel.selectedTimeRange == .month)
        #expect(service.fetchAlertsCallCount == 1) // loadData was called
        #expect(viewModel.alerts.count == 2)
    }

    // MARK: - Alert Acknowledgement

    @Test("Acknowledging alert removes it from the list")
    func acknowledgeAlertRemovesFromList() async {
        let alertId = UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!
        let service = MockDashboardDataServiceForTests()
        service.stubbedAlerts = makeTestAlerts()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        await viewModel.loadData()
        #expect(viewModel.alerts.count == 2)

        await viewModel.acknowledgeAlert(id: alertId)

        #expect(viewModel.alerts.count == 1)
        #expect(viewModel.alerts.first?.id != alertId)
        #expect(service.acknowledgedAlertIds.contains(alertId))
    }

    @Test("Acknowledging alert sets error on service failure")
    func acknowledgeAlertHandlesError() async {
        let alertId = UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!
        let service = MockDashboardDataServiceForTests()
        service.stubbedAlerts = makeTestAlerts()
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user
        )

        await viewModel.loadData()

        // Set error after successful load
        service.stubbedError = AppError.network("Server error")
        await viewModel.acknowledgeAlert(id: alertId)

        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Analytics Events

    @Test("loadData emits dashboard_view analytics event")
    func loadDataEmitsAnalyticsEvent() async {
        let service = MockDashboardDataServiceForTests()
        service.stubbedAlerts = []
        let authGate = MockDashboardAuthGate(fixedAccessLevel: .admin)
        let user = makeTestUser()
        let tracker = TestInteractionTracker()

        let viewModel = DashboardViewModel(
            dataService: service,
            authGate: authGate,
            currentUser: user,
            tracker: tracker
        )

        await viewModel.loadData()

        // Allow the Task in trackEvent to complete
        try? await Task.sleep(for: .milliseconds(50))

        let eventCount = await tracker.eventCount()
        #expect(eventCount >= 1)
    }
}
