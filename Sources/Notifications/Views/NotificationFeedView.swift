import SwiftUI
import Models
import Common
import Analytics
import DesignSystem

// MARK: - NotificationFeedView

/// The main notification feed screen displaying a list of notifications
/// with support for pull-to-refresh, swipe-to-mark-read, and a toolbar
/// action to mark all notifications as read.
///
/// This view integrates with the analytics system via the
/// `.trackInteraction(screen:)` modifier to feed the experimentation pipeline.
public struct NotificationFeedView: View {

    /// The view model managing feed state and actions.
    @Bindable private var viewModel: NotificationFeedViewModel

    /// Creates a new notification feed view.
    ///
    /// - Parameter viewModel: The view model providing state and actions.
    public init(viewModel: NotificationFeedViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Notifications")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        toolbarContent
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .task {
                    if viewModel.notifications.isEmpty {
                        await viewModel.loadNotifications()
                    }
                }
                .trackInteraction(screen: "NotificationFeed")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.notifications.isEmpty {
            loadingView
        } else if viewModel.notifications.isEmpty {
            emptyStateView
        } else {
            notificationList
        }
    }

    // MARK: - Notification List

    private var notificationList: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                NotificationRowView(notification: notification)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await viewModel.didTapNotification(notification)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !notification.isRead {
                            Button {
                                Task {
                                    await viewModel.markAsRead(id: notification.id)
                                }
                            } label: {
                                Label("Read", systemImage: "envelope.open")
                            }
                            .tint(.blue)
                        }
                    }
                    .listRowBackground(
                        notification.isRead
                            ? Color.clear
                            : Color.blue.opacity(0.05)
                    )
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 8)
            }
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Notifications", systemImage: "bell.slash")
        } description: {
            Text("You're all caught up! New notifications will appear here.")
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView("Loading notifications...")
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarContent: some View {
        HStack(spacing: 12) {
            if viewModel.unreadCount > 0 {
                Button {
                    Task {
                        await viewModel.markAllAsRead()
                    }
                } label: {
                    Label("Mark All Read", systemImage: "envelope.open.fill")
                }

                Text("\(viewModel.unreadCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red, in: Capsule())
            }
        }
    }

    // MARK: - Helpers

    /// Binding that bridges the optional error message to a Bool for alert presentation.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
}

// MARK: - NotificationRowView

/// A single row in the notification feed displaying the notification
/// icon, title, body, relative timestamp, and read/unread indicator.
struct NotificationRowView: View {
    let notification: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            notificationIcon
                .frame(width: 36, height: 36)
                .background(iconBackgroundColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .lineLimit(1)

                    Spacer()

                    Text(notification.createdAt.relativeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(notification.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(notification.type.displayName)
                    .font(.caption2)
                    .foregroundStyle(iconBackgroundColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(iconBackgroundColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            if !notification.isRead {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Icon

    @ViewBuilder
    private var notificationIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 16))
            .foregroundStyle(iconBackgroundColor)
    }

    private var iconName: String {
        switch notification.type {
        case .taskAssigned:
            return "person.badge.plus"
        case .taskUpdated:
            return "arrow.triangle.2.circlepath"
        case .commentAdded:
            return "bubble.left"
        case .mentioned:
            return "at"
        case .projectInvite:
            return "folder.badge.plus"
        }
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .taskAssigned:
            return .blue
        case .taskUpdated:
            return .orange
        case .commentAdded:
            return .green
        case .mentioned:
            return .purple
        case .projectInvite:
            return .indigo
        }
    }
}

// MARK: - ViewModel Extension for Error Clearing

extension NotificationFeedViewModel {
    /// Clears the current error message.
    func clearError() {
        errorMessage = nil
    }
}

// Note: TrackInteractionModifier, InteractionTrackerKey, and the
// .trackInteraction(screen:) view extension are provided by the Analytics module.
