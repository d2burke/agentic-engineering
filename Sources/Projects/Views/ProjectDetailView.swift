import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - ProjectDetailView

/// Displays detailed information about a single project.
///
/// Shows the project name, description, member count, and provides
/// navigation to the task board for this project. Interaction tracking
/// is applied for the experimentation analytics pipeline.
public struct ProjectDetailView: View {
    @Bindable var viewModel: ProjectDetailViewModel
    let projectId: UUID
    let onNavigateToTaskBoard: (UUID) -> Void

    public init(
        viewModel: ProjectDetailViewModel,
        projectId: UUID,
        onNavigateToTaskBoard: @escaping (UUID) -> Void
    ) {
        self.viewModel = viewModel
        self.projectId = projectId
        self.onNavigateToTaskBoard = onNavigateToTaskBoard
    }

    public var body: some View {
        Group {
            if let project = viewModel.project {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        projectHeaderSection(project)
                        descriptionSection(project)
                        membersSection(project)
                        taskBoardSection(project)
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
                        await viewModel.loadProject(id: projectId)
                    }
                }
            }
        }
        .navigationTitle(viewModel.project?.name ?? "Project")
        .task {
            await viewModel.loadProject(id: projectId)
        }
        .trackInteraction(screen: "ProjectDetail")
    }

    // MARK: - Sections

    @ViewBuilder
    private func projectHeaderSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(project.name)
                .font(Typography.title2)
                .foregroundStyle(ColorTokens.textPrimary)

            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(Typography.caption)
                    Text("Created \(project.createdAt, style: .date)")
                        .font(Typography.caption)
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(Typography.caption)
                    Text("Updated \(project.updatedAt, style: .relative)")
                        .font(Typography.caption)
                }
            }
            .foregroundStyle(ColorTokens.textTertiary)
        }
    }

    @ViewBuilder
    private func descriptionSection(_ project: Project) -> some View {
        if let description = project.projectDescription, !description.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Description")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(ColorTokens.cardBackground)
            )
        }
    }

    @ViewBuilder
    private func membersSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Members")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            HStack(spacing: Spacing.sm) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(ColorTokens.primary)
                Text("\(project.memberIds.count) team members")
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

    @ViewBuilder
    private func taskBoardSection(_ project: Project) -> some View {
        Button {
            onNavigateToTaskBoard(project.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Task Board")
                        .font(Typography.headline)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text("View and manage tasks for this project")
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(ColorTokens.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}
