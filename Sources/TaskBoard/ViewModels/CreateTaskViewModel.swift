import Foundation
import Observation
import Models
import Common
import Analytics

// MARK: - CreateTaskViewModel

/// View model for the create task form.
///
/// Manages form state for all task fields and handles task creation
/// through the repository. Emits interaction events for analytics.
@Observable
@MainActor
public final class CreateTaskViewModel {
    // MARK: - Form State

    /// The task title.
    public var title: String = ""

    /// The task description.
    public var taskDescription: String = ""

    /// The initial task status.
    public var status: TaskStatus = .todo

    /// The task priority level.
    public var priority: TaskPriority = .medium

    /// The assigned user's identifier, if any.
    public var assigneeId: UUID?

    /// The task due date, if any.
    public var dueDate: Date?

    /// Labels/tags for the task.
    public var labels: [String] = []

    // MARK: - Published State

    /// Whether a save operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public var errorMessage: String?

    /// Whether the save completed successfully.
    public private(set) var isSaved = false

    // MARK: - Dependencies

    private let repository: any TaskRepositoryProtocol
    private let interactionTracker: any InteractionTracking

    // MARK: - Init

    /// Creates a new create task view model.
    ///
    /// - Parameters:
    ///   - repository: The task data repository.
    ///   - interactionTracker: The interaction tracking service for analytics.
    public init(
        repository: any TaskRepositoryProtocol,
        interactionTracker: any InteractionTracking
    ) {
        self.repository = repository
        self.interactionTracker = interactionTracker
    }

    // MARK: - Computed Properties

    /// Whether the form has valid required fields.
    public var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Saves the new task to the repository.
    ///
    /// - Parameter projectId: The project to create the task in.
    public func save(projectId: UUID) async {
        guard isFormValid else {
            errorMessage = "Task title is required."
            return
        }

        isLoading = true
        errorMessage = nil

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let task = TaskItem(
            title: trimmedTitle,
            taskDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
            status: status,
            priority: priority,
            projectId: projectId,
            assigneeId: assigneeId,
            reporterId: UUID(),
            tags: labels,
            dueDate: dueDate
        )

        do {
            let createdTask = try await repository.createTask(task)

            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "CreateTask",
                metadata: [
                    "action": "task_create",
                    "task_id": createdTask.id.uuidString,
                    "status": status.rawValue,
                    "priority": priority.rawValue,
                    "project_id": projectId.uuidString
                ]
            ))

            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to create task: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }
}
