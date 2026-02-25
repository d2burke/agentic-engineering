import SwiftUI
import DesignSystem
import Analytics

// MARK: - LoginView

/// The login screen for the TaskManager application.
///
/// Presents email and password fields, a primary login button, an optional
/// biometric login button (when Face ID / Touch ID is available), and a
/// navigation link to the sign-up flow.
///
/// Uses DesignSystem components for consistent styling and attaches the
/// `.trackInteraction(screen:)` modifier for the analytics pipeline.
public struct LoginView: View {

    // MARK: - State

    @Bindable private var viewModel: LoginViewModel

    /// Closure called when the user taps the "Sign Up" link.
    private let onSignUpTapped: () -> Void

    // MARK: - Initializer

    /// Creates a `LoginView` bound to the given view model.
    ///
    /// - Parameters:
    ///   - viewModel: The view model managing login state and actions.
    ///   - onSignUpTapped: Closure invoked when the user wants to navigate to sign-up.
    public init(viewModel: LoginViewModel, onSignUpTapped: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onSignUpTapped = onSignUpTapped
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                headerSection

                formSection

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }

                actionSection

                signUpLink
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(ColorTokens.backgroundPrimary.ignoresSafeArea())
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay(message: "Signing in...")
            }
        }
        .modifier(Analytics.TrackInteractionModifier(screen: "Login"))
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(ColorTokens.primary)

            Text("Task Manager")
                .font(Typography.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ColorTokens.textPrimary)

            Text("Sign in to continue")
                .font(Typography.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .padding(.bottom, Spacing.lg)
    }

    private var formSection: some View {
        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Email")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                TextField("you@example.com", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if let message = viewModel.emailValidationMessage {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.destructive)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Password")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                SecureField("Enter your password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let message = viewModel.passwordValidationMessage {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.destructive)
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: Spacing.md) {
            PrimaryButton(
                title: "Sign In",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isFormValid
            ) {
                Task {
                    await viewModel.login()
                }
            }

            if viewModel.biometricsAvailable {
                Button {
                    Task {
                        await viewModel.loginWithBiometrics()
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: biometricIconName)
                        Text("Sign in with \(biometricLabel)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ColorTokens.backgroundSecondary)
                    .foregroundStyle(ColorTokens.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(ColorTokens.border, lineWidth: 1)
                    )
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private var signUpLink: some View {
        HStack(spacing: Spacing.xs) {
            Text("Don't have an account?")
                .font(Typography.footnote)
                .foregroundStyle(ColorTokens.textSecondary)

            Button("Sign Up") {
                onSignUpTapped()
            }
            .font(Typography.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(ColorTokens.primary)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ColorTokens.destructive)

            Text(message)
                .font(Typography.footnote)
                .foregroundStyle(ColorTokens.destructive)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(Spacing.md)
        .background(ColorTokens.destructive.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private var biometricIconName: String {
        switch viewModel.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.shield"
        }
    }

    private var biometricLabel: String {
        switch viewModel.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometrics"
        }
    }
}
