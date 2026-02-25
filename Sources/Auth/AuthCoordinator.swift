import SwiftUI
import Observation
import Models
import Analytics

// MARK: - AuthCoordinator

/// Coordinates navigation within the authentication flow.
///
/// Manages transitions between the login and sign-up screens, and exposes
/// `isAuthenticated` so that a parent coordinator or app root can switch
/// to the main application content once the user is signed in.
@Observable
@MainActor
public final class AuthCoordinator {

    // MARK: - Navigation State

    /// Whether the sign-up screen is currently shown (vs. the login screen).
    public var showingSignUp: Bool = false

    /// Whether the user has completed authentication. Observed by the
    /// parent coordinator to transition away from the auth flow.
    public var isAuthenticated: Bool = false

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let interactionTracker: InteractionTracking?

    // MARK: - Initializer

    /// Creates an `AuthCoordinator` with the given dependencies.
    ///
    /// - Parameters:
    ///   - authService: The authentication service shared across login/signup.
    ///   - interactionTracker: Optional analytics tracker for interaction events.
    public init(
        authService: AuthServiceProtocol,
        interactionTracker: InteractionTracking? = nil
    ) {
        self.authService = authService
        self.interactionTracker = interactionTracker
    }

    // MARK: - Navigation Actions

    /// Switch to the sign-up screen.
    public func showSignUp() {
        showingSignUp = true
    }

    /// Switch to the login screen.
    public func showLogin() {
        showingSignUp = false
    }

    /// Mark the user as authenticated (called by child view models on success).
    public func didAuthenticate() {
        isAuthenticated = true
    }

    // MARK: - Factory Methods

    /// Creates a `LoginViewModel` wired to this coordinator's auth service.
    public func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            authService: authService,
            interactionTracker: interactionTracker
        )
    }

    /// Creates a `SignUpViewModel` wired to this coordinator's auth service.
    public func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(
            authService: authService,
            interactionTracker: interactionTracker
        )
    }
}

// MARK: - AuthCoordinatorView

/// The root view for the authentication flow.
///
/// Switches between `LoginView` and `SignUpView` based on the coordinator's
/// navigation state. Monitors child view model authentication state and
/// propagates it up to the coordinator.
public struct AuthCoordinatorView: View {

    // MARK: - State

    @Bindable private var coordinator: AuthCoordinator
    @State private var loginViewModel: LoginViewModel
    @State private var signUpViewModel: SignUpViewModel

    // MARK: - Initializer

    /// Creates an `AuthCoordinatorView` driven by the given coordinator.
    ///
    /// - Parameter coordinator: The auth coordinator managing flow state.
    public init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
        self._loginViewModel = State(initialValue: coordinator.makeLoginViewModel())
        self._signUpViewModel = State(initialValue: coordinator.makeSignUpViewModel())
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if coordinator.showingSignUp {
                SignUpView(
                    viewModel: signUpViewModel,
                    onLoginTapped: {
                        coordinator.showLogin()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .trailing)
                ))
            } else {
                LoginView(
                    viewModel: loginViewModel,
                    onSignUpTapped: {
                        coordinator.showSignUp()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.showingSignUp)
        .onChange(of: loginViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                coordinator.didAuthenticate()
            }
        }
        .onChange(of: signUpViewModel.isSignedUp) { _, isSignedUp in
            if isSignedUp {
                coordinator.didAuthenticate()
            }
        }
    }
}
