import Foundation
import Observation
import Models
import Common
import Analytics

// MARK: - SignUpViewModel

/// View model driving the sign-up screen.
///
/// Manages form state, multi-field validation (email format, password
/// strength, password confirmation, display name), and the registration
/// lifecycle. Emits `InteractionEvent`s for the analytics pipeline.
@Observable
@MainActor
public final class SignUpViewModel {

    // MARK: - Published State

    /// The email address entered by the user.
    public var email: String = ""

    /// The desired password.
    public var password: String = ""

    /// The password confirmation field, must match `password`.
    public var confirmPassword: String = ""

    /// The user's display name.
    public var displayName: String = ""

    /// Whether a registration request is currently in flight.
    public var isLoading: Bool = false

    /// A user-facing error message, or `nil` if there is no error.
    public var errorMessage: String?

    /// Whether sign-up completed successfully.
    public var isSignedUp: Bool = false

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let interactionTracker: InteractionTracking?

    // MARK: - Initializer

    /// Creates a `SignUpViewModel` with the given dependencies.
    ///
    /// - Parameters:
    ///   - authService: The authentication service for registration.
    ///   - interactionTracker: Optional analytics tracker for interaction events.
    public init(
        authService: AuthServiceProtocol,
        interactionTracker: InteractionTracking? = nil
    ) {
        self.authService = authService
        self.interactionTracker = interactionTracker
    }

    // MARK: - Validation

    /// Whether all form fields pass validation.
    public var isFormValid: Bool {
        isEmailValid && isPasswordValid && doPasswordsMatch && isDisplayNameValid
    }

    /// Whether the email field contains a valid email address.
    public var isEmailValid: Bool {
        email.isValidEmail
    }

    /// Whether the password meets the minimum length requirement (8 characters).
    public var isPasswordValid: Bool {
        password.count >= 8
    }

    /// Whether the password and confirmation fields match.
    public var doPasswordsMatch: Bool {
        password == confirmPassword
    }

    /// Whether the display name is non-empty.
    public var isDisplayNameValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Validation message for the email field, or `nil` if valid.
    public var emailValidationMessage: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Please enter a valid email address."
    }

    /// Validation message for the password field, or `nil` if valid.
    public var passwordValidationMessage: String? {
        guard !password.isEmpty else { return nil }
        return isPasswordValid ? nil : "Password must be at least 8 characters."
    }

    /// Validation message for the confirm password field, or `nil` if valid.
    public var confirmPasswordValidationMessage: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return doPasswordsMatch ? nil : "Passwords do not match."
    }

    /// Validation message for the display name field, or `nil` if valid.
    public var displayNameValidationMessage: String? {
        guard !displayName.isEmpty else { return nil }
        return isDisplayNameValid ? nil : "Display name cannot be empty."
    }

    // MARK: - Actions

    /// Attempt to register a new user with the current form data.
    ///
    /// On success, sets `isSignedUp` to `true`. On failure, populates
    /// `errorMessage` with a user-facing description.
    public func signUp() async {
        guard isFormValid else {
            errorMessage = validationSummary
            return
        }

        trackEvent(action: "signup_attempt")

        isLoading = true
        errorMessage = nil

        do {
            let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await authService.signUp(
                email: email,
                password: password,
                displayName: trimmedDisplayName
            )
            isSignedUp = true
            trackEvent(action: "signup_success")
        } catch {
            errorMessage = mapErrorToMessage(error)
            trackEvent(action: "signup_failure", metadata: ["error": errorMessage ?? "unknown"])
        }

        isLoading = false
    }

    // MARK: - Private Helpers

    /// Produces a consolidated validation error message for the current form state.
    private var validationSummary: String {
        var messages: [String] = []
        if !isDisplayNameValid { messages.append("Display name is required.") }
        if !isEmailValid { messages.append("A valid email address is required.") }
        if !isPasswordValid { messages.append("Password must be at least 8 characters.") }
        if !doPasswordsMatch { messages.append("Passwords do not match.") }
        return messages.joined(separator: " ")
    }

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
            screen: "SignUp",
            metadata: eventMetadata
        )
        Task {
            await interactionTracker?.track(event)
        }
    }
}
