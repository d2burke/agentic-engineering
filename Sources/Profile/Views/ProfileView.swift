import SwiftUI
import Models
import DesignSystem
import Analytics

// MARK: - ProfileView

/// Displays and allows editing of the current user's profile.
///
/// Shows the user's avatar, display name, email, and role in a read-only
/// mode by default. An edit button transitions to inline editing with
/// save/cancel controls. Uses DesignSystem components and attaches
/// `.trackInteraction(screen:)` for the analytics pipeline.
public struct ProfileView: View {

    // MARK: - State

    @Bindable private var viewModel: ProfileViewModel

    // MARK: - Initializer

    /// Creates a `ProfileView` bound to the given view model.
    ///
    /// - Parameter viewModel: The view model managing profile state and actions.
    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Group {
                if let user = viewModel.user {
                    profileContent(user: user)
                } else if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Unable to Load Profile",
                        message: errorMessage,
                        actionTitle: "Retry"
                    ) {
                        Task {
                            await viewModel.loadProfile()
                        }
                    }
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle",
                        title: "No Profile",
                        message: "Your profile could not be loaded."
                    )
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.user != nil {
                        if viewModel.isEditing {
                            Button("Cancel") {
                                viewModel.cancelEditing()
                            }
                        } else {
                            Button("Edit") {
                                viewModel.startEditing()
                            }
                        }
                    }
                }
            }
            .task {
                if viewModel.user == nil {
                    await viewModel.loadProfile()
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.user != nil {
                    LoadingOverlay(isShowing: true)
                }
            }
        }
        .modifier(Analytics.TrackInteractionModifier(screen: "Profile"))
    }

    // MARK: - Subviews

    private func profileContent(user: User) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                avatarSection(user: user)

                if viewModel.isEditing {
                    editingSection
                } else {
                    detailSection(user: user)
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
        }
    }

    private func avatarSection(user: User) -> some View {
        VStack(spacing: Spacing.md) {
            AvatarView(
                name: user.displayName,
                avatarURL: user.avatarURL,
                size: 96
            )

            if !viewModel.isEditing {
                Text(user.displayName)
                    .font(Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(user.email)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }

    private func detailSection(user: User) -> some View {
        VStack(spacing: Spacing.lg) {
            profileRow(label: "Display Name", value: user.displayName)
            Divider()
            profileRow(label: "Email", value: user.email)
            Divider()
            profileRow(label: "Role", value: user.role.displayName)
            Divider()
            profileRow(label: "Member Since", value: formattedDate(user.createdAt))
        }
        .padding(Spacing.lg)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var editingSection: some View {
        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Display Name")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                TextField("Your display name", text: $viewModel.editingDisplayName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Avatar URL")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textSecondary)

                TextField("https://example.com/avatar.jpg", text: $viewModel.editingAvatarURL)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    viewModel.cancelEditing()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ColorTokens.backgroundSecondary)
                .foregroundStyle(ColorTokens.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                PrimaryButton(
                    title: "Save",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    Task {
                        await viewModel.saveEdits()
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)

            Spacer()

            Text(value)
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(ColorTokens.textPrimary)
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
