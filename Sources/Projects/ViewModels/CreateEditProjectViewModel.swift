import Foundation
import Observation
import Models
import Common
import Analytics

// MARK: - CreateEditProjectViewModel

/// View model for creating or editing a project.
///
/// Operates in two modes: create (no existing project) and edit (with an
/// existing project pre-populated). Emits interaction events for each
/// save operation to support experimentation analytics.
@Observable
@MainActor
public final class CreateEditProjectViewModel {
    // MARK: - Mode

    /// The editing mode: creating a new project or editing an existing one.
    public enum Mode {
        case create
        case edit(Project)
    }

    // MARK: - Published State

    /// The project name field.
    public var name: String = ""

    /// The project description field.
    public var projectDescription: String = ""

    /// Whether a save operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public private(set) var errorMessage: String?

    /// Whether the save completed successfully.
    public private(set) var isSaved = false

    // MARK: - Internal State

    /// The current editing mode.
    public let mode: Mode

    // MARK: - Dependencies

    private let repository: any ProjectRepositoryProtocol
    private let interactionTracker: any InteractionTracking

    // MARK: - Init

    /// Creates a new view model for project creation or editing.
    ///
    /// - Parameters:
    ///   - mode: Whether to create a new project or edit an existing one.
    ///   - repository: The project data repository.
    ///   - interactionTracker: The interaction tracking service for analytics.
    public init(
        mode: Mode = .create,
        repository: any ProjectRepositoryProtocol,
        interactionTracker: any InteractionTracking
    ) {
        self.mode = mode
        self.repository = repository
        self.interactionTracker = interactionTracker

        switch mode {
        case .create:
            break
        case .edit(let project):
            self.name = project.name
            self.projectDescription = project.projectDescription ?? ""
        }
    }

    // MARK: - Computed Properties

    /// Whether the form is valid and ready to submit.
    public var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Saves the project, either creating a new one or updating an existing one.
    ///
    /// Emits `project_create` or `project_edit` interaction events based on the mode.
    public func save() async {
        guard isFormValid else {
            errorMessage = "Project name is required."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let descriptionValue = trimmedDescription.isEmpty ? nil : trimmedDescription

            switch mode {
            case .create:
                let project = try await repository.createProject(
                    name: trimmedName,
                    description: descriptionValue
                )
                await interactionTracker.track(InteractionEvent(
                    type: .tap,
                    screen: "CreateEditProject",
                    metadata: [
                        "action": "project_create",
                        "project_id": project.id.uuidString,
                        "project_name": trimmedName
                    ]
                ))

            case .edit(let existingProject):
                var updatedProject = existingProject
                updatedProject.name = trimmedName
                updatedProject.projectDescription = descriptionValue
                updatedProject.updatedAt = Date()
                _ = try await repository.updateProject(updatedProject)
                await interactionTracker.track(InteractionEvent(
                    type: .tap,
                    screen: "CreateEditProject",
                    metadata: [
                        "action": "project_edit",
                        "project_id": existingProject.id.uuidString,
                        "project_name": trimmedName
                    ]
                ))
            }

            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("Failed to save project: \(error.localizedDescription)", category: .network)
        }

        isLoading = false
    }
}
