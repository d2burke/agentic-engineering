import Foundation
import Models
import Common
import Analytics
import Networking

// MARK: - ProfileViewModel

/// View model driving the user profile screen.
///
/// Manages the user's profile data, loading state, and inline editing
/// lifecycle. Emits `InteractionEvent`s for the analytics pipeline so the
/// Experimentation Agent can track profile engagement patterns.
@Observable
@MainActor
public final class ProfileViewModel {

    // MARK: - Published State

    /// The currently loaded user profile, or `nil` if not yet loaded.
    public var user: User?

    /// Whether a network request is in flight.
    public var isLoading: Bool = false

    /// A user-facing error message, or `nil` if there is no error.
    public var errorMessage: String?

    /// Whether the view is in inline editing mode.
    public var isEditing: Bool = false

    /// The editable display name (populated when entering edit mode).
    public var editingDisplayName: String = ""

    /// The editable avatar URL string (populated when entering edit mode).
    public var editingAvatarURL: String = ""

    // MARK: - Dependencies

    private let userRepository: UserRepositoryProtocol
    private let interactionTracker: InteractionTracking?

    // MARK: - Initializer

    /// Creates a `ProfileViewModel` with the given dependencies.
    ///
    /// - Parameters:
    ///   - userRepository: The repository for user profile data access.
    ///   - interactionTracker: Optional analytics tracker for interaction events.
    public init(
        userRepository: UserRepositoryProtocol,
        interactionTracker: InteractionTracking? = nil
    ) {
        self.userRepository = userRepository
        self.interactionTracker = interactionTracker
    }

    // MARK: - Actions

    /// Load the current user's profile from the server.
    ///
    /// Populates `user` on success, or `errorMessage` on failure.
    public func loadProfile() async {
        isLoading = true
        errorMessage = nil
        trackEvent(action: "profile_view")

        do {
            user = try await userRepository.fetchCurrentUser()
        } catch {
            errorMessage = mapErrorToMessage(error)
        }

        isLoading = false
    }

    /// Update the current user's profile with the given values.
    ///
    /// - Parameters:
    ///   - displayName: The new display name.
    ///   - avatarURL: The new avatar URL, or `nil` to leave unchanged.
    public func updateProfile(displayName: String, avatarURL: URL?) async {
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Display name cannot be empty."
            return
        }

        isLoading = true
        errorMessage = nil
        trackEvent(action: "profile_edit", metadata: ["field": "displayName"])

        do {
            user = try await userRepository.updateProfile(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarURL: avatarURL
            )
            isEditing = false
        } catch {
            errorMessage = mapErrorToMessage(error)
        }

        isLoading = false
    }

    /// Enter inline editing mode, pre-populating fields from the current user.
    public func startEditing() {
        guard let user else { return }
        editingDisplayName = user.displayName
        editingAvatarURL = user.avatarURL?.absoluteString ?? ""
        isEditing = true
        trackEvent(action: "profile_edit_started")
    }

    /// Cancel inline editing and discard changes.
    public func cancelEditing() {
        isEditing = false
        editingDisplayName = ""
        editingAvatarURL = ""
        trackEvent(action: "profile_edit_cancelled")
    }

    /// Save the current edits by calling `updateProfile`.
    public func saveEdits() async {
        let avatarURL: URL? = editingAvatarURL.isEmpty ? nil : URL(string: editingAvatarURL)
        await updateProfile(displayName: editingDisplayName, avatarURL: avatarURL)
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
            screen: "Profile",
            metadata: eventMetadata
        )
        Task {
            await interactionTracker?.track(event)
        }
    }
}
