import SwiftUI
import Models
import DesignSystem

// MARK: - FilterBar

/// A horizontal scrollable bar of filter chips for the task board.
///
/// Shows active filters as filled chips with a remove action. Includes
/// a "Clear All" button when any filters are active. Supports filtering
/// by assignee, priority, status, and label.
public struct FilterBar: View {
    let activeFilters: Set<TaskFilter>
    let onRemoveFilter: (TaskFilter) -> Void
    let onClearAll: () -> Void

    public init(
        activeFilters: Set<TaskFilter>,
        onRemoveFilter: @escaping (TaskFilter) -> Void,
        onClearAll: @escaping () -> Void
    ) {
        self.activeFilters = activeFilters
        self.onRemoveFilter = onRemoveFilter
        self.onClearAll = onClearAll
    }

    public var body: some View {
        if !activeFilters.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(activeFilters), id: \.self) { filter in
                        FilterChip(
                            label: filterLabel(filter),
                            isActive: true
                        ) {
                            onRemoveFilter(filter)
                        }
                    }

                    if activeFilters.count > 1 {
                        Button {
                            onClearAll()
                        } label: {
                            Text("Clear All")
                                .font(Typography.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorTokens.destructive)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .background(ColorTokens.backgroundSecondary)
        }
    }

    // MARK: - Filter Label

    private func filterLabel(_ filter: TaskFilter) -> String {
        switch filter {
        case .assignee:
            return "Assignee"
        case .priority(let priority):
            return priority.displayName
        case .label(let label):
            return label
        case .status(let status):
            return status.displayName
        case .dueDate:
            return "Due Date"
        }
    }
}

// MARK: - FilterChip

/// A single filter chip component.
///
/// Displays a label with an optional remove button. Active chips
/// use a filled background; inactive chips use an outline.
struct FilterChip: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Text(label)
                    .font(Typography.caption)
                    .fontWeight(.medium)

                if isActive {
                    Image(systemName: "xmark")
                        .font(Typography.caption2)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(isActive ? ColorTokens.primary.opacity(0.12) : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? ColorTokens.primary : ColorTokens.border,
                        lineWidth: 1
                    )
            )
            .foregroundStyle(isActive ? ColorTokens.primary : ColorTokens.textSecondary)
        }
    }
}
