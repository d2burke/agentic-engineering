import Foundation
import Models
import Common
import Analytics

// MARK: - BoardColumn

/// Represents a single Kanban column on the task board.
///
/// Each column corresponds to a `TaskStatus` and contains the tasks
/// currently in that status. Conforms to `Identifiable` for SwiftUI
/// list rendering.
public struct BoardColumn: Identifiable, Sendable {
    public var id: String { status.rawValue }
    public let status: TaskStatus
    public var tasks: [TaskItem]

    public init(status: TaskStatus, tasks: [TaskItem]) {
        self.status = status
        self.tasks = tasks
    }
}

// MARK: - TaskBoardViewModel

/// View model managing the Kanban task board state and user interactions.
///
/// This is the PRIMARY target for interaction tracking. All user actions
/// including task moves, filter changes, and task taps are tracked with
/// rich metadata to support rage tap detection, dead tap analysis, and
/// abandon pattern identification in the experimentation pipeline.
@Observable
@MainActor
public final class TaskBoardViewModel {
    // MARK: - Published State

    /// The Kanban columns, one per task status.
    public private(set) var columns: [BoardColumn] = []

    /// All tasks for the current project (unfiltered).
    public private(set) var allTasks: [TaskItem] = []

    /// The set of currently active filters.
    public private(set) var activeFilters: Set<TaskFilter> = []

    /// Whether a load operation is in progress.
    public private(set) var isLoading = false

    /// An error message to display, or `nil` if no error.
    public var errorMessage: String?

    /// The current search text for filtering tasks by title.
    public var searchText: String = ""

    /// The project identifier this board is displaying.
    public private(set) var projectId: UUID?

    // MARK: - Dependencies

    private let repository: any TaskRepositoryProtocol
    private let interactionTracker: any InteractionTracking

    // MARK: - Init

    /// Creates a new task board view model.
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

    // MARK: - Actions

    /// Loads all tasks for the given project and groups them by status into columns.
    ///
    /// Emits a `board_view` interaction event on successful load.
    ///
    /// - Parameter projectId: The UUID of the project whose tasks to load.
    public func loadTasks(projectId: UUID) async {
        self.projectId = projectId
        isLoading = true
        errorMessage = nil

        do {
            allTasks = try await repository.fetchTasks(projectId: projectId)
            rebuildColumns()

            await interactionTracker.track(InteractionEvent(
                type: .navigate,
                screen: "TaskBoard",
                metadata: [
                    "action": "board_view",
                    "project_id": projectId.uuidString,
                    "task_count": "\(allTasks.count)"
                ]
            ))
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to load tasks: \(error.localizedDescription)",
                category: .network
            )
        }

        isLoading = false
    }

    /// Moves a task to a new status column.
    ///
    /// Performs an optimistic update locally, then issues the remote status
    /// change. Rolls back on failure. Emits a `task_move` interaction event
    /// with `from_status` and `to_status` metadata.
    ///
    /// - Parameters:
    ///   - taskId: The UUID of the task to move.
    ///   - toStatus: The target status column.
    public func moveTask(taskId: UUID, toStatus: TaskStatus) async {
        guard let taskIndex = allTasks.firstIndex(where: { $0.id == taskId }) else { return }

        let fromStatus = allTasks[taskIndex].status
        guard fromStatus != toStatus else { return }

        let previousTasks = allTasks
        allTasks[taskIndex].status = toStatus
        allTasks[taskIndex].updatedAt = Date()
        rebuildColumns()

        await interactionTracker.track(InteractionEvent(
            type: .drag,
            screen: "TaskBoard",
            metadata: [
                "action": "task_move",
                "task_id": taskId.uuidString,
                "from_status": fromStatus.rawValue,
                "to_status": toStatus.rawValue
            ]
        ))

        do {
            _ = try await repository.updateTaskStatus(id: taskId, status: toStatus)
        } catch {
            allTasks = previousTasks
            rebuildColumns()
            errorMessage = error.localizedDescription
            AppLogger.error(
                "Failed to move task: \(error.localizedDescription)",
                category: .network
            )
        }
    }

    /// Applies a filter to the task board.
    ///
    /// Emits a `filter_applied` interaction event with filter type and value metadata.
    ///
    /// - Parameter filter: The filter to apply.
    public func applyFilter(_ filter: TaskFilter) {
        activeFilters.insert(filter)
        rebuildColumns()

        Task {
            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskBoard",
                metadata: [
                    "action": "filter_applied",
                    "filter_type": filterTypeName(filter),
                    "filter_value": filterValueName(filter)
                ]
            ))
        }
    }

    /// Removes a filter from the task board.
    ///
    /// - Parameter filter: The filter to remove.
    public func removeFilter(_ filter: TaskFilter) {
        activeFilters.remove(filter)
        rebuildColumns()
    }

    /// Clears all active filters.
    ///
    /// Emits a `filter_cleared` interaction event.
    public func clearFilters() {
        activeFilters.removeAll()
        rebuildColumns()

        Task {
            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskBoard",
                metadata: ["action": "filter_cleared"]
            ))
        }
    }

    /// Returns filtered tasks for a given status.
    ///
    /// Applies all active filters and the search text to the tasks
    /// in the specified status column.
    ///
    /// - Parameter status: The status to filter tasks for.
    /// - Returns: The filtered tasks for the given status.
    public func filteredTasks(for status: TaskStatus) -> [TaskItem] {
        var tasks = allTasks.filter { $0.status == status }

        for filter in activeFilters {
            tasks = tasks.filter { filter.matches($0) }
        }

        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            tasks = tasks.filter {
                $0.title.lowercased().contains(lowercased) ||
                ($0.taskDescription?.lowercased().contains(lowercased) ?? false)
            }
        }

        return tasks
    }

    /// Tracks a task card tap interaction.
    ///
    /// - Parameter taskId: The UUID of the tapped task.
    public func trackTaskTap(taskId: UUID) {
        Task {
            await interactionTracker.track(InteractionEvent(
                type: .tap,
                screen: "TaskBoard",
                metadata: [
                    "action": "task_tap",
                    "task_id": taskId.uuidString
                ]
            ))
        }
    }

    // MARK: - Private Helpers

    private func rebuildColumns() {
        let activeStatuses: [TaskStatus] = [.todo, .inProgress, .inReview, .done]
        columns = activeStatuses.map { status in
            BoardColumn(status: status, tasks: filteredTasks(for: status))
        }
    }

    private func filterTypeName(_ filter: TaskFilter) -> String {
        switch filter {
        case .assignee: return "assignee"
        case .priority: return "priority"
        case .label: return "label"
        case .status: return "status"
        case .dueDate: return "due_date"
        }
    }

    private func filterValueName(_ filter: TaskFilter) -> String {
        switch filter {
        case .assignee(let id): return id.uuidString
        case .priority(let priority): return priority.rawValue
        case .label(let label): return label
        case .status(let status): return status.rawValue
        case .dueDate: return "date_range"
        }
    }
}
