import SwiftUI
import DesignSystem
import Analytics

// MARK: - SignUpView

/// The registration screen for the TaskManager application.
///
/// Presents fields for display name, email, password, and password confirmation
/// with inline validation messages. Uses DesignSystem components for consistent
/// styling and attaches `.trackInteraction(screen:)` for the analytics pipeline.
public struct SignUpView: View {

    // MARK: - State

    @Bindable private var viewModel: SignUpViewModel

    /// Closure called when the user taps the "Back to Sign In" link.
    private let onLoginTapped: () -> Void

    // MARK: - Initializer

    /// Creates a `SignUpView` bound to the given view model.
    ///
    /// - Parameters:
    ///   - viewModel: The view model managing sign-up state and actions.
    ///   - onLoginTapped: Closure invoked when the user wants to navigate back to login.
    public init(viewModel: SignUpViewModel, onLoginTapped: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onLoginTapped = onLoginTapped
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

                loginLink
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxl)
        }
        .background(ColorTokens.backgroundPrimary.ignoresSafeArea())
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay(message: "Creating account...")
            }
        }
        .modifier(Analytics.TrackInteractionModifier(screen: "SignUp"))
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 56))
                .foregroundStyle(ColorTokens.primary)

            Text("Create Account")
                .font(Typography.title)
                .fontWeight(.bold)
                .foregroundStyle(ColorTokens.textPrimary)

            Text("Join your team on Task Manager")
                .font(Typography.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .padding(.bottom, Spacing.lg)
    }

    private var formSection: some View {
        VStack(spacing: Spacing.lg) {
            // Display Name
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Display Name")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                TextField("Your full name", text: $viewModel.displayName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocorrectionDisabled()

                if let message = viewModel.displayNameValidationMessage {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.destructive)
                }
            }

            // Email
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

            // Password
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Password")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                SecureField("At least 8 characters", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                if let message = viewModel.passwordValidationMessage {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.destructive)
                }
            }

            // Confirm Password
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Confirm Password")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                SecureField("Repeat your password", text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                if let message = viewModel.confirmPasswordValidationMessage {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.destructive)
                }
            }
        }
    }

    private var actionSection: some View {
        PrimaryButton(
            title: "Create Account",
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isFormValid
        ) {
            Task {
                await viewModel.signUp()
            }
        }
    }

    private var loginLink: some View {
        HStack(spacing: Spacing.xs) {
            Text("Already have an account?")
                .font(Typography.footnote)
                .foregroundStyle(ColorTokens.textSecondary)

            Button("Sign In") {
                onLoginTapped()
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
}
