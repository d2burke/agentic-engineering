import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - ProjectListView

/// The main project list screen.
///
/// Displays all projects in a scrollable list with pull-to-refresh,
/// swipe-to-delete, empty state handling, and a toolbar button to
/// create new projects. Interaction tracking is applied for the
/// experimentation analytics pipeline.
public struct ProjectListView: View {
    @Bindable var viewModel: ProjectListViewModel
    let onSelectProject: (Project) -> Void

    public init(
        viewModel: ProjectListViewModel,
        onSelectProject: @escaping (Project) -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectProject = onSelectProject
    }

    public var body: some View {
        Group {
            if viewModel.projects.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "folder",
                    title: "No Projects",
                    message: "Create your first project to get started organizing tasks.",
                    actionTitle: "Create Project"
                ) {
                    viewModel.isShowingCreateSheet = true
                }
            } else {
                List {
                    ForEach(viewModel.projects) { project in
                        ProjectRowView(project: project)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectProject(project)
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let project = viewModel.projects[index]
                            Task {
                                await viewModel.deleteProject(id: project.id)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .overlay {
            LoadingOverlay(isShowing: viewModel.isLoading && viewModel.projects.isEmpty)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isShowingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            Task {
                await viewModel.loadProjects()
            }
        } content: {
            EmptyView()
        }
        .task {
            await viewModel.loadProjects()
        }
        .trackInteraction(screen: "ProjectList")
    }
}

// MARK: - ProjectRowView

/// A single row in the project list displaying the project name,
/// description preview, and member count.
struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(project.name)
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            if let description = project.projectDescription, !description.isEmpty {
                Text(description)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "person.2")
                        .font(Typography.caption)
                    Text("\(project.memberIds.count) members")
                        .font(Typography.caption)
                }
                .foregroundStyle(ColorTokens.textTertiary)

                Spacer()

                Text(project.updatedAt, style: .relative)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
