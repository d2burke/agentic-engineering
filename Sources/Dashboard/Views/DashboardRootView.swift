import SwiftUI
import DesignSystem
import Analytics

// MARK: - DashboardRootView

/// The main dashboard container view providing panel navigation,
/// time range selection, alert banner, and loading overlay.
///
/// Uses a `TabView` with tab items for iOS panel navigation across
/// the panels the current user has access to. An alert banner is
/// displayed at the top when there are unacknowledged alerts.
/// The time range picker is in the toolbar as a segmented control.
public struct DashboardRootView: View {
    @Bindable private var viewModel: DashboardViewModel
    private let businessVM: BusinessMetricsViewModel
    private let performanceVM: AppPerformanceViewModel
    private let signalsVM: InteractionSignalsViewModel
    private let agenticVM: AgenticWorkViewModel

    /// Creates the dashboard root view.
    ///
    /// - Parameters:
    ///   - viewModel: The root dashboard view model.
    ///   - businessVM: The business metrics view model.
    ///   - performanceVM: The app performance view model.
    ///   - signalsVM: The interaction signals view model.
    ///   - agenticVM: The agentic work view model.
    public init(
        viewModel: DashboardViewModel,
        businessVM: BusinessMetricsViewModel,
        performanceVM: AppPerformanceViewModel,
        signalsVM: InteractionSignalsViewModel,
        agenticVM: AgenticWorkViewModel
    ) {
        self.viewModel = viewModel
        self.businessVM = businessVM
        self.performanceVM = performanceVM
        self.signalsVM = signalsVM
        self.agenticVM = agenticVM
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Alert banner at top
                if !viewModel.unacknowledgedAlerts.isEmpty {
                    AlertBanner(
                        alerts: viewModel.alerts,
                        onAcknowledge: { alertId in
                            Task {
                                await viewModel.acknowledgeAlert(id: alertId)
                            }
                        }
                    )
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }

                // Tab-based panel navigation
                TabView(selection: $viewModel.selectedPanel) {
                    BusinessMetricsView(viewModel: businessVM)
                        .tabItem {
                            Label(
                                DashboardPanel.business.displayName,
                                systemImage: DashboardPanel.business.iconName
                            )
                        }
                        .tag(DashboardPanel.business)

                    AppPerformanceView(viewModel: performanceVM)
                        .tabItem {
                            Label(
                                DashboardPanel.appPerformance.displayName,
                                systemImage: DashboardPanel.appPerformance.iconName
                            )
                        }
                        .tag(DashboardPanel.appPerformance)

                    InteractionSignalsView(viewModel: signalsVM)
                        .tabItem {
                            Label(
                                DashboardPanel.interactionSignals.displayName,
                                systemImage: DashboardPanel.interactionSignals.iconName
                            )
                        }
                        .tag(DashboardPanel.interactionSignals)

                    AgenticWorkView(viewModel: agenticVM)
                        .tabItem {
                            Label(
                                DashboardPanel.agenticWork.displayName,
                                systemImage: DashboardPanel.agenticWork.iconName
                            )
                        }
                        .tag(DashboardPanel.agenticWork)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    timeRangePicker
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)

            // Loading overlay
            LoadingOverlay(isShowing: viewModel.isLoading)
        }
        .task {
            await viewModel.loadData()
            await loadCurrentPanel()
        }
        .onChange(of: viewModel.selectedTimeRange) { _, newRange in
            Task {
                await loadCurrentPanel()
            }
        }
        .onChange(of: viewModel.selectedPanel) { _, newPanel in
            Task {
                await loadPanelData(for: newPanel)
            }
        }
        .trackInteraction(screen: "Dashboard")
    }

    // MARK: - Time Range Picker

    /// Segmented control for selecting the time range.
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
            ForEach(DashboardTimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 240)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ColorTokens.error)
                .font(Typography.caption)

            Text(message)
                .font(Typography.caption)
                .foregroundStyle(ColorTokens.error)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(ColorTokens.error.opacity(0.08))
    }

    // MARK: - Data Loading

    /// Loads data for the currently selected panel.
    private func loadCurrentPanel() async {
        await loadPanelData(for: viewModel.selectedPanel)
    }

    /// Loads data for a specific panel.
    private func loadPanelData(for panel: DashboardPanel) async {
        let timeRange = viewModel.selectedTimeRange
        switch panel {
        case .business:
            await businessVM.loadMetrics(timeRange: timeRange)
        case .appPerformance:
            await performanceVM.loadMetrics(timeRange: timeRange)
        case .interactionSignals:
            await signalsVM.loadMetrics(timeRange: timeRange)
        case .agenticWork:
            await agenticVM.loadMetrics(timeRange: timeRange)
        case .alerts:
            break
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Dashboard Root") {
    NavigationStack {
        DashboardRootView(
            viewModel: DashboardViewModel(
                dataService: MockDashboardDataService(),
                authGate: DashboardAuthGate(),
                currentUser: .init(email: "admin@test.com", displayName: "Admin User", role: .admin)
            ),
            businessVM: BusinessMetricsViewModel(dataService: MockDashboardDataService()),
            performanceVM: AppPerformanceViewModel(dataService: MockDashboardDataService()),
            signalsVM: InteractionSignalsViewModel(dataService: MockDashboardDataService()),
            agenticVM: AgenticWorkViewModel(dataService: MockDashboardDataService())
        )
    }
}
#endif
