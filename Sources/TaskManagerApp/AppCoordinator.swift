import SwiftUI
import Models
import Analytics
import Auth
import Notifications

// MARK: - AppTab

/// The top-level tabs in the main application interface.
public enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case projects
    case dashboard
    case notifications
    case profile

    public var id: String { rawValue }

    /// The human-readable label for the tab.
    public var title: String {
        switch self {
        case .projects: return "Projects"
        case .dashboard: return "Dashboard"
        case .notifications: return "Notifications"
        case .profile: return "Profile"
        }
    }

    /// The SF Symbol name for the tab icon.
    public var icon: String {
        switch self {
        case .projects: return "folder.fill"
        case .dashboard: return "chart.bar.xaxis"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - AppCoordinator

/// Manages top-level navigation for the application.
///
/// The coordinator determines whether to show the authentication flow
/// or the main tab-based interface, and manages the selected tab.
/// It observes the `AuthCoordinator`'s authentication state to trigger
/// transitions between the two flows.
@Observable
@MainActor
public final class AppCoordinator {

    // MARK: - State

    /// Whether the user is currently authenticated.
    public var isAuthenticated: Bool = false

    /// The currently selected tab in the main interface.
    public var selectedTab: AppTab = .projects

    // MARK: - Dependencies

    /// The dependency container holding all services and repositories.
    private let container: DependencyContainer

    /// The auth coordinator managing the login/signup flow.
    public let authCoordinator: AuthCoordinator

    // MARK: - Init

    /// Creates an app coordinator with the given dependency container.
    ///
    /// - Parameter container: The container providing all service instances.
    public init(container: DependencyContainer) {
        self.container = container
        self.authCoordinator = container.makeAuthCoordinator()
    }

    // MARK: - Actions

    /// Called when the auth coordinator signals successful authentication.
    public func didAuthenticate() {
        isAuthenticated = true
    }

    /// Called when the user logs out, transitioning back to the auth flow.
    public func didLogout() {
        isAuthenticated = false
        selectedTab = .projects
    }

    /// Attempts to restore a previous session from the keychain.
    public func restoreSession() async {
        await container.authService.restoreSession()
        isAuthenticated = await container.authService.isAuthenticated
    }
}

// MARK: - AppCoordinatorView

/// The root view for the application, switching between the authentication
/// flow and the main tab-based interface based on the coordinator's state.
public struct AppCoordinatorView: View {

    // MARK: - State

    @Bindable private var coordinator: AppCoordinator
    private let container: DependencyContainer

    // MARK: - Init

    /// Creates the root app view.
    ///
    /// - Parameters:
    ///   - coordinator: The app coordinator managing top-level navigation.
    ///   - container: The dependency container for creating child view models.
    public init(coordinator: AppCoordinator, container: DependencyContainer) {
        self.coordinator = coordinator
        self.container = container
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if coordinator.isAuthenticated {
                MainTabView(
                    coordinator: coordinator,
                    container: container
                )
                .transition(.opacity)
            } else {
                AuthCoordinatorView(coordinator: coordinator.authCoordinator)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.isAuthenticated)
        .onChange(of: coordinator.authCoordinator.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                coordinator.didAuthenticate()
            }
        }
        .task {
            await coordinator.restoreSession()
        }
    }
}
