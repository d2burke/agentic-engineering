import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - CreateEditProjectView

/// A sheet form for creating or editing a project.
///
/// Contains fields for the project name (required) and description (optional),
/// with save and cancel actions. Interaction tracking is applied for the
/// experimentation analytics pipeline.
public struct CreateEditProjectView: View {
    @Bindable var viewModel: CreateEditProjectViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: CreateEditProjectViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $viewModel.name)
                        .font(Typography.body)
                } header: {
                    Text("Name")
                        .font(Typography.caption)
                } footer: {
                    Text("Required")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                Section {
                    TextEditor(text: $viewModel.projectDescription)
                        .font(Typography.body)
                        .frame(minHeight: 100)
                } header: {
                    Text("Description")
                        .font(Typography.caption)
                } footer: {
                    Text("Optional")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Typography.footnote)
                            .foregroundStyle(ColorTokens.error)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .overlay {
                LoadingOverlay(isShowing: viewModel.isLoading)
            }
            .onChange(of: viewModel.isSaved) { _, isSaved in
                if isSaved {
                    dismiss()
                }
            }
            .trackInteraction(screen: "CreateEditProject")
        }
    }

    private var navigationTitle: String {
        switch viewModel.mode {
        case .create:
            return "New Project"
        case .edit:
            return "Edit Project"
        }
    }
}
