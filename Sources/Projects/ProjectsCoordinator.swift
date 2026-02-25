import SwiftUI
import Models
import Common
import Networking
import Persistence
import Analytics
import DesignSystem

// MARK: - Navigation Destination

/// Navigation destinations within the Projects feature module.
enum ProjectsDestination: Hashable {
    case projectDetail(UUID)
    case taskBoard(UUID)
}

// MARK: - ProjectsCoordinatorView

/// The root view for the Projects tab.
///
/// Manages the navigation stack from project list to project detail
/// and on to the task board. Constructs and injects dependencies
/// for each screen's view model.
public struct ProjectsCoordinatorView: View {
    private let apiClient: any APIClientProtocol
    private let persistence: PersistenceManager
    private let interactionTracker: any InteractionTracking
    private let taskBoardDestination: ((UUID) -> AnyView)?

    @State private var navigationPath = NavigationPath()

    /// Creates the coordinator view for the projects tab.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for remote communication.
    ///   - persistence: The persistence manager for local caching.
    ///   - interactionTracker: The interaction tracking service.
    ///   - taskBoardDestination: Optional closure to provide the task board view for a project.
    public init(
        apiClient: any APIClientProtocol,
        persistence: PersistenceManager,
        interactionTracker: any InteractionTracking,
        taskBoardDestination: ((UUID) -> AnyView)? = nil
    ) {
        self.apiClient = apiClient
        self.persistence = persistence
        self.interactionTracker = interactionTracker
        self.taskBoardDestination = taskBoardDestination
    }

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            projectListView
                .navigationTitle("Projects")
                .navigationDestination(for: ProjectsDestination.self) { destination in
                    switch destination {
                    case .projectDetail(let projectId):
                        projectDetailView(projectId: projectId)
                    case .taskBoard(let projectId):
                        if let taskBoardDestination {
                            taskBoardDestination(projectId)
                        } else {
                            Text("Task Board for project \(projectId.uuidString)")
                        }
                    }
                }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var projectListView: some View {
        let repository = ProjectRepository(apiClient: apiClient, persistence: persistence)
        let viewModel = ProjectListViewModel(
            repository: repository,
            interactionTracker: interactionTracker
        )
        ProjectListView(viewModel: viewModel) { project in
            navigationPath.append(ProjectsDestination.projectDetail(project.id))
        }
    }

    @ViewBuilder
    private func projectDetailView(projectId: UUID) -> some View {
        let repository = ProjectRepository(apiClient: apiClient, persistence: persistence)
        let viewModel = ProjectDetailViewModel(repository: repository)
        ProjectDetailView(
            viewModel: viewModel,
            projectId: projectId
        ) { projectId in
            navigationPath.append(ProjectsDestination.taskBoard(projectId))
        }
    }
}
