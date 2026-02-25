import Foundation
import Observation
import Models
import Common
import Analytics

// MARK: - ProjectListViewModel

/// View model managing the project list screen state and user interactions.
///
/// Loads the user's projects, supports pull-to-refresh and swipe-to-delete,
/// and emits interaction events for the experimentation analytics pipeline.
@Observable
@MainActor
public final class ProjectListViewModel {
    // MARK: - Published State

    /// The list of projects to display.
    public private(set) var projects: [Project] = []

    /// Whether a load or refresh operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public var errorMessage: String?

    /// Controls presentation of the create project sheet.
    public var isShowingCreateSheet = false

    // MARK: - Dependencies

    private let repository: any ProjectRepositoryProtocol
    private let interactionTracker: any InteractionTracking

    // MARK: - Init

    /// Creates a new project list view model.
    ///
    /// - Parameters:
    ///   - repository: The project data repository.
    ///   - interactionTracker: The interaction tracking service for analytics.
    public init(
        repository: any ProjectRepositoryProtocol,
        interactionTracker: any InteractionTracking
    ) {
        self.repository = repository
        self.interactionTracker = interactionTracker
    }

    // MARK: - Actions

    /// Loads all projects from the repository.
    ///
    /// Emits a `project_list_view` interaction event upon completion.
    public func loadProjects() async {
        isLoading = true
        errorMessage = nil

        do {
            projects = try await repository.fetchProjects()
            await interactionTracker.track(InteractionEvent(
                type: .navigate,
                screen: "ProjectList",
                metadata: [
                    "action": "project_list_view",
                    "project_count": "\(projects.count)"
                ]
            ))
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("Failed to load projects: \(error.localizedDescription)", category: .network)
        }

        isLoading = false
    }

    /// Deletes a project by its identifier.
    ///
    /// Removes the project optimistically from the local list before
    /// issuing the remote delete request. Restores on failure.
    ///
    /// - Parameter id: The identifier of the project to delete.
    public func deleteProject(id: UUID) async {
        let previousProjects = projects
        projects.removeAll { $0.id == id }

        await interactionTracker.track(InteractionEvent(
            type: .tap,
            screen: "ProjectList",
            metadata: [
                "action": "project_delete",
                "project_id": id.uuidString
            ]
        ))

        do {
            try await repository.deleteProject(id: id)
        } catch {
            projects = previousProjects
            errorMessage = error.localizedDescription
            AppLogger.error("Failed to delete project: \(error.localizedDescription)", category: .network)
        }
    }

    /// Refreshes the project list from the remote source.
    ///
    /// Emits a `project_refresh` interaction event.
    public func refresh() async {
        await interactionTracker.track(InteractionEvent(
            type: .tap,
            screen: "ProjectList",
            metadata: ["action": "project_refresh"]
        ))

        await loadProjects()
    }
}
