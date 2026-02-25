import SwiftUI
import Analytics
import Notifications

// MARK: - TaskManagerAppView

/// The root view for the Team Task Manager application.
///
/// This view serves as the entry point when integrated into an actual iOS app
/// target. It creates the `DependencyContainer`, sets up the `AppCoordinator`,
/// and injects the `InteractionTracker` into the SwiftUI environment so that
/// all feature views can use `.trackInteraction(screen:)`.
///
/// ## Experimentation Integration
/// The `InteractionTracker`'s `signalStream` is the primary data feed for
/// the experimentation engine (M9). By injecting the tracker into the
/// environment at this level, every screen in the app automatically
/// participates in the analytics pipeline.
///
/// ## Usage
/// In an actual iOS app target:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             TaskManagerAppView()
///         }
///     }
/// }
/// ```
public struct TaskManagerAppView: View {

    // MARK: - State

    /// The dependency container holding all services and repositories.
    /// Stored as `@State` to ensure it persists across view re-renders.
    @State private var container = DependencyContainer()

    /// The app coordinator managing top-level navigation.
    @State private var coordinator: AppCoordinator?

    // MARK: - Body

    public var body: some View {
        Group {
            if let coordinator {
                AppCoordinatorView(
                    coordinator: coordinator,
                    container: container
                )
            } else {
                ProgressView("Initializing...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(\.interactionTracker, container.interactionTracker)
        .task {
            if coordinator == nil {
                coordinator = AppCoordinator(container: container)
            }

            // Request push notification permission on launch.
            do {
                try await container.pushNotificationService.requestPermission()
            } catch {
                // Permission request failure is non-fatal.
            }
        }
    }

    // MARK: - Init

    /// Creates the root application view.
    public init() {}
}
