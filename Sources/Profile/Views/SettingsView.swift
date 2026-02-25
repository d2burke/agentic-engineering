import SwiftUI
import DesignSystem
import Analytics

// MARK: - SettingsView

/// The application settings screen.
///
/// Organized into sections: Appearance (dark mode), Notifications,
/// Security (biometrics), Account (logout), and About (version).
/// Uses DesignSystem components and attaches `.trackInteraction(screen:)`
/// for the analytics pipeline.
public struct SettingsView: View {

    // MARK: - State

    @Bindable private var viewModel: SettingsViewModel

    /// Whether the logout confirmation alert is presented.
    @State private var showLogoutConfirmation = false

    // MARK: - Initializer

    /// Creates a `SettingsView` bound to the given view model.
    ///
    /// - Parameter viewModel: The view model managing settings state and actions.
    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                notificationsSection
                securitySection
                accountSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.onAppear()
            }
            .alert("Sign Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You will need to log in again to access your account.")
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Signing out...")
                }
            }
        }
        .modifier(Analytics.TrackInteractionModifier(screen: "Settings"))
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.isDarkMode },
                set: { _ in viewModel.toggleDarkMode() }
            )) {
                Label("Dark Mode", systemImage: "moon.fill")
            }
        } header: {
            Text("Appearance")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.notificationsEnabled },
                set: { _ in viewModel.toggleNotifications() }
            )) {
                Label("Push Notifications", systemImage: "bell.fill")
            }
        } header: {
            Text("Notifications")
        }
    }

    private var securitySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.biometricsEnabled },
                set: { _ in viewModel.toggleBiometrics() }
            )) {
                Label("Biometric Login", systemImage: "faceid")
            }
        } header: {
            Text("Security")
        }
    }

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.destructive)
            }
        } header: {
            Text("Account")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        } header: {
            Text("About")
        }
    }
}
