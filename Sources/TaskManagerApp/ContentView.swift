import SwiftUI
import Models
import Analytics
import Projects
import Notifications
import Profile
import Dashboard

// MARK: - MainTabView

/// The primary tab-based interface shown when the user is authenticated.
///
/// Contains three tabs:
/// - **Projects**: The project list and navigation flow.
/// - **Notifications**: The notification feed with unread badge.
/// - **Profile**: The user profile and settings screens.
///
/// Handles deep link navigation by switching to the appropriate tab
/// when the `DeepLinkHandler` has pending navigation targets.
public struct MainTabView: View {

    // MARK: - State

    @Bindable private var coordinator: AppCoordinator
    private let container: DependencyContainer

    @State private var notificationViewModel: NotificationFeedViewModel?
    @State private var projectListViewModel: ProjectListViewModel?
    @State private var profileViewModel: ProfileViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var dashboardViewModel: DashboardViewModel?

    // MARK: - Init

    /// Creates the main tab view.
    ///
    /// - Parameters:
    ///   - coordinator: The app coordinator managing tab selection and navigation.
    ///   - container: The dependency container for creating child view models.
    public init(coordinator: AppCoordinator, container: DependencyContainer) {
        self.coordinator = coordinator
        self.container = container
    }

    // MARK: - Body

    public var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            projectsTab
                .tag(AppTab.projects)

            dashboardTab
                .tag(AppTab.dashboard)

            notificationsTab
                .tag(AppTab.notifications)

            profileTab
                .tag(AppTab.profile)
        }
        .task {
            initializeViewModels()
        }
        .onChange(of: container.deepLinkHandler.hasPendingNavigation) { _, hasPending in
            if hasPending {
                handleDeepLink()
            }
        }
    }

    // MARK: - Projects Tab

    private var projectsTab: some View {
        NavigationStack {
            if let viewModel = projectListViewModel {
                ProjectListView(viewModel: viewModel) { project in
                    // Navigation to project detail handled within the Projects module
                }
            } else {
                ProgressView()
            }
        }
        .tabItem {
            Label(AppTab.projects.title, systemImage: AppTab.projects.icon)
        }
    }

    // MARK: - Dashboard Tab

    private var dashboardTab: some View {
        Group {
            if let viewModel = dashboardViewModel {
                DashboardRootView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .tabItem {
            Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
        }
    }

    // MARK: - Notifications Tab

    private var notificationsTab: some View {
        Group {
            if let viewModel = notificationViewModel {
                NotificationFeedView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .tabItem {
            Label(AppTab.notifications.title, systemImage: AppTab.notifications.icon)
        }
        .badge(notificationViewModel?.unreadCount ?? 0)
    }

    // MARK: - Profile Tab

    private var profileTab: some View {
        NavigationStack {
            if let profileVM = profileViewModel, let settingsVM = settingsViewModel {
                ProfileTabContent(
                    profileViewModel: profileVM,
                    settingsViewModel: settingsVM,
                    onLogout: {
                        coordinator.didLogout()
                    }
                )
            } else {
                ProgressView()
            }
        }
        .tabItem {
            Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
        }
    }

    // MARK: - Helpers

    /// Initializes view models on first appearance.
    private func initializeViewModels() {
        if notificationViewModel == nil {
            notificationViewModel = container.makeNotificationFeedViewModel()
        }
        if projectListViewModel == nil {
            projectListViewModel = container.makeProjectListViewModel()
        }
        if profileViewModel == nil {
            profileViewModel = container.makeProfileViewModel()
        }
        if settingsViewModel == nil {
            settingsViewModel = container.makeSettingsViewModel()
        }
        if dashboardViewModel == nil {
            dashboardViewModel = container.makeDashboardViewModel()
        }
    }

    /// Handles deep link navigation by switching to the correct tab.
    private func handleDeepLink() {
        let handler = container.deepLinkHandler

        if handler.pendingTaskId != nil || handler.pendingProjectId != nil {
            // If there's a pending task or project, navigate to the projects tab
            // (or notifications tab based on the notification type).
            if handler.pendingNotificationType != nil {
                coordinator.selectedTab = .notifications
            } else {
                coordinator.selectedTab = .projects
            }
        }

        handler.clearPending()
    }
}

// MARK: - ProfileTabContent

/// A container view for the profile tab that includes both the profile
/// view and a navigation link to settings.
struct ProfileTabContent: View {
    let profileViewModel: ProfileViewModel
    let settingsViewModel: SettingsViewModel
    let onLogout: () -> Void

    var body: some View {
        ProfileView(viewModel: profileViewModel)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(viewModel: settingsViewModel)
                            .onChange(of: settingsViewModel.didLogout) { _, didLogout in
                                if didLogout {
                                    onLogout()
                                }
                            }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
    }
}
