import Foundation
import Common
import Models
import Networking
import Persistence
import Analytics
import Auth
import Projects
import Profile
import Notifications
import Dashboard

// MARK: - DependencyContainer

/// The application's dependency composition root.
///
/// `DependencyContainer` creates and holds all service, repository, and
/// infrastructure instances used throughout the application. Dependencies
/// are wired together in `init()`, ensuring a single source of truth for
/// the object graph.
///
/// ## Experimentation Pipeline
/// The `interactionTracker` is configured with all behavioral signal detectors
/// (RageTap, DeadTap, Abandon) and the `ConsoleSignalExporter` (in DEBUG).
/// Its `signalStream` is the data feed that the experimentation engine (M9)
/// will consume for real-time decision making.
@Observable
@MainActor
public final class DependencyContainer {

    // MARK: - Infrastructure

    /// The API client for all network communication.
    public let apiClient: URLSessionAPIClient

    /// The in-memory persistence manager for caching and offline data.
    public let persistenceManager: InMemoryPersistenceManager

    /// The file-based persistence manager for production caching.
    public let filePersistenceManager: PersistenceManager

    /// The keychain service for secure credential storage.
    public let keychainService: KeychainService

    /// The offline operation queue for pending mutations.
    public let offlineQueue: OfflineQueue

    /// The network connectivity monitor.
    public let networkMonitor: NetworkMonitor

    /// The sync engine for replaying offline operations.
    public let syncEngine: SyncEngine

    // MARK: - Services

    /// The authentication service managing login, signup, and session lifecycle.
    public let authService: AuthService

    /// The interaction tracker for the analytics and experimentation pipeline.
    public let interactionTracker: InteractionTracker

    /// The push notification service for permission and device registration.
    public let pushNotificationService: PushNotificationService

    /// The deep link handler for processing notification-driven navigation.
    public let deepLinkHandler: DeepLinkHandler

    // MARK: - Repositories

    /// The project data repository.
    public let projectRepository: ProjectRepository

    /// The user profile data repository.
    public let userRepository: UserRepository

    /// The notification data repository.
    public let notificationRepository: NotificationRepository

    // MARK: - Init

    /// Creates and wires together the entire dependency graph.
    ///
    /// This initializer:
    /// 1. Creates infrastructure services (API client, persistence, keychain).
    /// 2. Creates the interaction tracker and registers all signal detectors.
    /// 3. Registers signal exporters (ConsoleSignalExporter in DEBUG builds).
    /// 4. Creates all feature repositories and services.
    public init() {
        // -- Infrastructure --

        let baseURL = URL(string: "https://api.taskmanager.com/v1")!
        self.apiClient = URLSessionAPIClient(baseURL: baseURL)
        self.persistenceManager = InMemoryPersistenceManager()
        self.filePersistenceManager = PersistenceManager()
        self.keychainService = KeychainService()
        self.offlineQueue = OfflineQueue()
        self.networkMonitor = NetworkMonitor()

        // -- Sync Engine --

        let syncHandler = APISyncHandler(apiClient: apiClient)
        self.syncEngine = SyncEngine(queue: offlineQueue, handler: syncHandler)

        // -- Analytics / Experimentation Pipeline --

        let tracker = InteractionTracker()
        self.interactionTracker = tracker

        // Register behavioral signal detectors.
        // These feed into the signalStream consumed by the experimentation engine.
        Task {
            await tracker.registerDetector(RageTapDetector())
            await tracker.registerDetector(DeadTapDetector())
            await tracker.registerDetector(AbandonDetector())

            // Register exporters.
            // In DEBUG builds, log signals to the console for development diagnostics.
            #if DEBUG
            await tracker.registerExporter(ConsoleSignalExporter())
            #endif
        }

        // -- Auth --

        self.authService = AuthService(
            apiClient: apiClient,
            keychainService: keychainService
        )

        // -- Feature Repositories --

        self.projectRepository = ProjectRepository(
            apiClient: apiClient,
            persistence: filePersistenceManager
        )

        self.userRepository = UserRepository(
            apiClient: apiClient
        )

        self.notificationRepository = NotificationRepository(
            apiClient: apiClient
        )

        // -- Services --

        self.pushNotificationService = PushNotificationService(
            apiClient: apiClient
        )

        self.deepLinkHandler = DeepLinkHandler()
    }

    // MARK: - Factory Methods

    /// Creates an `AuthCoordinator` wired to the container's auth service and tracker.
    public func makeAuthCoordinator() -> AuthCoordinator {
        AuthCoordinator(
            authService: authService,
            interactionTracker: interactionTracker
        )
    }

    /// Creates a `NotificationFeedViewModel` wired to the container's repository and tracker.
    public func makeNotificationFeedViewModel() -> NotificationFeedViewModel {
        NotificationFeedViewModel(
            repository: notificationRepository,
            tracker: interactionTracker
        )
    }

    /// Creates a `ProjectListViewModel` wired to the container's repository and tracker.
    public func makeProjectListViewModel() -> ProjectListViewModel {
        ProjectListViewModel(
            repository: projectRepository,
            interactionTracker: interactionTracker
        )
    }

    /// Creates a `ProfileViewModel` wired to the container's user repository and tracker.
    public func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            userRepository: userRepository,
            interactionTracker: interactionTracker
        )
    }

    /// Creates a `DashboardViewModel` wired to the container's data service and tracker.
    public func makeDashboardViewModel() -> DashboardViewModel {
        let dataService = MockDashboardDataService()
        let authGate = DashboardAuthGate()
        return DashboardViewModel(
            dataService: dataService,
            authGate: authGate,
            interactionTracker: interactionTracker
        )
    }

    /// Creates a `SettingsViewModel` wired to the container's auth service and tracker.
    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            logoutAction: { [authService] in
                try await authService.logout()
            },
            interactionTracker: interactionTracker
        )
    }
}

// MARK: - APISyncHandler

/// Bridges `SyncHandler` to the API client, translating each
/// `OfflineOperation` into the corresponding API request.
///
/// This enables the `SyncEngine` to drain the offline queue without
/// the Persistence module depending on Networking.
struct APISyncHandler: SyncHandler {
    let apiClient: any APIClientProtocol

    func execute(_ operation: OfflineOperation) async throws {
        let method: HTTPMethod
        switch operation.type {
        case .create:
            method = .post
        case .update:
            method = .put
        case .delete:
            method = .delete
        }

        let path = "/\(operation.entityType.lowercased())s/\(operation.entityId.uuidString)"
        let endpoint = Endpoint(path: path, method: method, body: operation.payload)
        try await apiClient.request(endpoint)
    }
}
