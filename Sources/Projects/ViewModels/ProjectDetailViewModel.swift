import Foundation
import Observation
import Models
import Common

// MARK: - ProjectDetailViewModel

/// View model for the project detail screen.
///
/// Loads and displays a single project's information including its
/// name, description, and member count.
@Observable
@MainActor
public final class ProjectDetailViewModel {
    // MARK: - Published State

    /// The loaded project, or `nil` if not yet loaded.
    public private(set) var project: Project?

    /// Whether a load operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let repository: any ProjectRepositoryProtocol

    // MARK: - Init

    /// Creates a new project detail view model.
    ///
    /// - Parameter repository: The project data repository.
    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Loads a project by its identifier.
    ///
    /// - Parameter id: The UUID of the project to load.
    public func loadProject(id: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            project = try await repository.fetchProject(id: id)
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("Failed to load project \(id): \(error.localizedDescription)", category: .network)
        }

        isLoading = false
    }
}
