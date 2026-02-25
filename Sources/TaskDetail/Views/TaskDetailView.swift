import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - TaskDetailView

/// The full task detail screen.
///
/// Displays the task's title, description, status (editable picker),
/// priority, assignee, due date, and labels. Organized into sections:
/// Details, Comments, Attachments, and Activity. Supports edit mode
/// toggle for inline editing.
public struct TaskDetailView: View {
    @Bindable var viewModel: TaskDetailViewModel
    @Bindable var commentsViewModel: CommentsViewModel
    let taskId: UUID

    public init(
        viewModel: TaskDetailViewModel,
        commentsViewModel: CommentsViewModel,
        taskId: UUID
    ) {
        self.viewModel = viewModel
        self.commentsViewModel = commentsViewModel
        self.taskId = taskId
    }

    public var body: some View {
        Group {
            if let task = viewModel.task {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        detailsSection(task)
                        statusSection(task)
                        metadataSection(task)
                        labelsSection(task)
                        commentsSection
                        attachmentsSection
                        activitySection
                    }
                    .padding(Spacing.lg)
                }
            } else if viewModel.isLoading {
                LoadingOverlay(isShowing: true)
            } else if let errorMessage = viewModel.errorMessage {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Failed to Load",
                    message: errorMessage,
                    actionTitle: "Retry"
                ) {
                    Task {
                        await viewModel.loadTask(id: taskId)
                    }
                }
            }
        }
        .navigationTitle(viewModel.task?.title ?? "Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(viewModel.isEditing ? "Done" : "Edit") {
                    if viewModel.isEditing, let task = viewModel.task {
                        Task {
                            await viewModel.updateTask(task)
                        }
                    } else {
                        viewModel.isEditing.toggle()
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.loadTask(id: taskId)
            await viewModel.loadComments()
            await viewModel.loadAttachments()
            await commentsViewModel.loadComments(taskId: taskId)
        }
        .trackInteraction(screen: "TaskDetail")
    }

    // MARK: - Details Section

    @ViewBuilder
    private func detailsSection(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Details")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(task.title)
                .font(Typography.title3)
                .foregroundStyle(ColorTokens.textPrimary)

            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
    }

    // MARK: - Status Section

    @ViewBuilder
    private func statusSection(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Status")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            if viewModel.isEditing {
                Picker("Status", selection: Binding(
                    get: { task.status },
                    set: { newStatus in
                        Task {
                            await viewModel.updateStatus(newStatus)
                        }
                    }
                )) {
                    ForEach(TaskStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                StatusBadge(status: task.status)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
    }

    // MARK: - Metadata Section

    @ViewBuilder
    private func metadataSection(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Priority")
                        .font(Typography.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                    PriorityBadge(priority: task.priority)
                }

                if task.assigneeId != nil {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Assignee")
                            .font(Typography.caption)
                            .foregroundStyle(ColorTokens.textTertiary)
                        HStack(spacing: Spacing.xs) {
                            AvatarView(name: "Assignee", size: 24)
                            Text("Assigned")
                                .font(Typography.subheadline)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    }
                }

                Spacer()
            }

            if let dueDate = task.dueDate {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(Typography.caption)
                    Text("Due: ")
                        .font(Typography.subheadline)
                    Text(dueDate, style: .date)
                        .font(Typography.subheadline)
                }
                .foregroundStyle(
                    dueDate < Date() ? ColorTokens.error : ColorTokens.textSecondary
                )
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
    }

    // MARK: - Labels Section

    @ViewBuilder
    private func labelsSection(_ task: TaskItem) -> some View {
        if !task.tags.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Labels")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)

                FlowLayout(spacing: Spacing.sm) {
                    ForEach(task.tags, id: \.self) { tag in
                        Text(tag)
                            .font(Typography.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(ColorTokens.primary.opacity(0.1))
                            .foregroundStyle(ColorTokens.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(ColorTokens.cardBackground)
            )
        }
    }

    // MARK: - Comments Section

    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Comments")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            CommentsView(viewModel: commentsViewModel, taskId: taskId)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
    }

    // MARK: - Attachments Section

    @ViewBuilder
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Attachments")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            AttachmentsView(attachments: viewModel.attachments)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
    }

    // MARK: - Activity Section

    @ViewBuilder
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Activity")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            ActivityLogView(task: viewModel.task)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(ColorTokens.cardBackground)
        )
    }
}

// MARK: - FlowLayout

/// A simple horizontal wrapping layout for tags and labels.
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: currentY + lineHeight),
            positions: positions
        )
    }
}
