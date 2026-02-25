import Foundation
import Models
import Common
import Analytics

// MARK: - SettingsViewModel

/// View model driving the application settings screen.
///
/// Manages user preferences (appearance, notifications, security),
/// persists them via `UserDefaults`, and provides a logout action.
/// Emits `InteractionEvent`s for the analytics pipeline so the
/// Experimentation Agent can track settings engagement patterns.
@Observable
@MainActor
public final class SettingsViewModel {

    // MARK: - UserDefaults Keys

    private enum DefaultsKey {
        static let isDarkMode = "settings.isDarkMode"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let biometricsEnabled = "settings.biometricsEnabled"
    }

    // MARK: - Published State

    /// Whether dark mode is enabled.
    public var isDarkMode: Bool {
        didSet {
            defaults.set(isDarkMode, forKey: DefaultsKey.isDarkMode)
        }
    }

    /// Whether push notifications are enabled.
    public var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: DefaultsKey.notificationsEnabled)
        }
    }

    /// Whether biometric login is enabled.
    public var biometricsEnabled: Bool {
        didSet {
            defaults.set(biometricsEnabled, forKey: DefaultsKey.biometricsEnabled)
        }
    }

    /// The current app version string.
    public let appVersion: String

    /// Whether a logout request is currently in flight.
    public var isLoading: Bool = false

    /// A user-facing error message, or `nil` if there is no error.
    public var errorMessage: String?

    /// Set to `true` after a successful logout to signal the coordinator.
    public var didLogout: Bool = false

    // MARK: - Dependencies

    private let logoutAction: () async throws -> Void
    private let interactionTracker: InteractionTracking?
    private let defaults: UserDefaults

    // MARK: - Initializer

    /// Creates a `SettingsViewModel` with the given dependencies.
    ///
    /// - Parameters:
    ///   - logoutAction: An async closure that performs the logout operation.
    ///   - interactionTracker: Optional analytics tracker for interaction events.
    ///   - defaults: The `UserDefaults` store for persisting preferences.
    ///   - appVersion: The app version string to display. Defaults to the bundle version.
    public init(
        logoutAction: @escaping () async throws -> Void,
        interactionTracker: InteractionTracking? = nil,
        defaults: UserDefaults = .standard,
        appVersion: String? = nil
    ) {
        self.logoutAction = logoutAction
        self.interactionTracker = interactionTracker
        self.defaults = defaults
        self.appVersion = appVersion
            ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0.0"

        // Load persisted preferences.
        self.isDarkMode = defaults.bool(forKey: DefaultsKey.isDarkMode)
        self.notificationsEnabled = defaults.bool(forKey: DefaultsKey.notificationsEnabled)
        self.biometricsEnabled = defaults.bool(forKey: DefaultsKey.biometricsEnabled)
    }

    // MARK: - Actions

    /// Toggle dark mode and track the change.
    public func toggleDarkMode() {
        isDarkMode.toggle()
        trackSettingChanged(setting: "dark_mode", value: String(isDarkMode))
    }

    /// Toggle notifications and track the change.
    public func toggleNotifications() {
        notificationsEnabled.toggle()
        trackSettingChanged(setting: "notifications", value: String(notificationsEnabled))
    }

    /// Toggle biometric login and track the change.
    public func toggleBiometrics() {
        biometricsEnabled.toggle()
        trackSettingChanged(setting: "biometrics", value: String(biometricsEnabled))
    }

    /// Perform the logout operation.
    ///
    /// On success, sets `didLogout` to `true`. On failure, populates `errorMessage`.
    public func logout() async {
        isLoading = true
        errorMessage = nil
        trackEvent(action: "logout_attempt")

        do {
            try await logoutAction()
            didLogout = true
            trackEvent(action: "logout_success")
        } catch {
            errorMessage = "Failed to log out. Please try again."
            trackEvent(action: "logout_failure", metadata: ["error": error.localizedDescription])
        }

        isLoading = false
    }

    /// Called when the settings screen appears. Tracks the view event.
    public func onAppear() {
        trackEvent(action: "settings_view")
    }

    // MARK: - Private Helpers

    private func trackSettingChanged(setting: String, value: String) {
        trackEvent(action: "setting_changed", metadata: [
            "setting": setting,
            "value": value,
        ])
    }

    private func trackEvent(action: String, metadata: [String: String] = [:]) {
        var eventMetadata = metadata
        eventMetadata["action"] = action
        let event = InteractionEvent(
            type: .tap,
            screen: "Settings",
            metadata: eventMetadata
        )
        Task {
            await interactionTracker?.track(event)
        }
    }
}
