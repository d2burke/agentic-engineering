import Foundation
import Models
import Common
import Analytics

// MARK: - LoginViewModel

/// View model driving the login screen.
///
/// Manages form state (email, password), validation, and authentication
/// lifecycle. Emits `InteractionEvent`s for the analytics pipeline so the
/// Experimentation Agent can measure login funnel behavior.
@Observable
@MainActor
public final class LoginViewModel {

    // MARK: - Published State

    /// The email address entered by the user.
    public var email: String = ""

    /// The password entered by the user.
    public var password: String = ""

    /// Whether an authentication request is currently in flight.
    public var isLoading: Bool = false

    /// A user-facing error message, or `nil` if there is no error.
    public var errorMessage: String?

    /// Whether the user has been authenticated successfully.
    public var isAuthenticated: Bool = false

    /// Whether biometric authentication is available on this device.
    public var biometricsAvailable: Bool = false

    /// The type of biometric available (for display purposes).
    public var biometricType: BiometricType = .none

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let biometricService: BiometricServiceProtocol
    private let interactionTracker: InteractionTracking?

    // MARK: - Initializer

    /// Creates a `LoginViewModel` with the given dependencies.
    ///
    /// - Parameters:
    ///   - authService: The authentication service for login operations.
    ///   - biometricService: The biometric service for Face ID/Touch ID.
    ///   - interactionTracker: Optional analytics tracker for interaction events.
    public init(
        authService: AuthServiceProtocol,
        biometricService: BiometricServiceProtocol = BiometricService(),
        interactionTracker: InteractionTracking? = nil
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.interactionTracker = interactionTracker
        self.biometricsAvailable = biometricService.canUseBiometrics()
        self.biometricType = biometricService.biometricType
    }

    // MARK: - Validation

    /// Whether the current form input passes validation.
    public var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }

    /// Whether the email field contains a valid email address.
    public var isEmailValid: Bool {
        email.isValidEmail
    }

    /// Whether the password field is non-empty.
    public var isPasswordValid: Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Validation message for the email field, or `nil` if valid.
    public var emailValidationMessage: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Please enter a valid email address."
    }

    /// Validation message for the password field, or `nil` if valid.
    public var passwordValidationMessage: String? {
        guard !password.isEmpty else { return nil }
        return isPasswordValid ? nil : "Password cannot be empty."
    }

    // MARK: - Actions

    /// Attempt to log in with the current email and password.
    ///
    /// On success, sets `isAuthenticated` to `true`. On failure, populates
    /// `errorMessage` with a user-facing description.
    public func login() async {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        trackEvent(action: "login_attempt")

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.login(email: email, password: password)
            isAuthenticated = true
            trackEvent(action: "login_success")
        } catch {
            errorMessage = mapErrorToMessage(error)
            trackEvent(action: "login_failure", metadata: ["error": errorMessage ?? "unknown"])
        }

        isLoading = false
    }

    /// Attempt to log in using biometric authentication.
    ///
    /// If biometric verification succeeds, proceeds with a saved-credential
    /// login flow. Falls back to standard login if biometrics fail.
    public func loginWithBiometrics() async {
        guard biometricsAvailable else {
            errorMessage = "Biometric authentication is not available."
            return
        }

        trackEvent(action: "biometric_login_attempt")

        do {
            let authenticated = try await biometricService.authenticate(
                reason: "Log in to Task Manager"
            )

            guard authenticated else {
                errorMessage = "Biometric authentication was not successful."
                trackEvent(action: "biometric_login_failure", metadata: ["reason": "not_authenticated"])
                return
            }

            // After biometric verification, attempt login with stored credentials.
            // In a full implementation, credentials would be retrieved from keychain.
            // For now, we validate that biometrics passed and use the form fields.
            if isFormValid {
                await login()
            } else {
                errorMessage = "Please enter your credentials."
                trackEvent(action: "biometric_login_failure", metadata: ["reason": "missing_credentials"])
            }
        } catch {
            errorMessage = "Biometric authentication failed. Please try again."
            trackEvent(action: "biometric_login_failure", metadata: ["error": error.localizedDescription])
        }
    }

    // MARK: - Private Helpers

    private func mapErrorToMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        return "An unexpected error occurred. Please try again."
    }

    private func trackEvent(action: String, metadata: [String: String] = [:]) {
        var eventMetadata = metadata
        eventMetadata["action"] = action
        let event = InteractionEvent(
            type: .tap,
            screen: "Login",
            metadata: eventMetadata
        )
        Task {
            await interactionTracker?.track(event)
        }
    }
}
