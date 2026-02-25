import Foundation

/// A filter predicate for narrowing task lists.
///
/// Each case carries the value to match against. Conforms to `Hashable`
/// and `Sendable` so filters can be stored in sets, used as dictionary keys,
/// and passed across concurrency boundaries.
public enum TaskFilter: Hashable, Sendable {
    case assignee(UUID)
    case priority(TaskPriority)
    case label(String)
    case status(TaskStatus)
    case dueDate(DateInterval)

    /// Returns `true` if the given task satisfies this filter.
    public func matches(_ task: TaskItem) -> Bool {
        switch self {
        case .assignee(let userId):
            return task.assigneeId == userId

        case .priority(let priority):
            return task.priority == priority

        case .label(let label):
            return task.tags.contains(label)

        case .status(let status):
            return task.status == status

        case .dueDate(let interval):
            guard let dueDate = task.dueDate else { return false }
            return interval.contains(dueDate)
        }
    }
}
