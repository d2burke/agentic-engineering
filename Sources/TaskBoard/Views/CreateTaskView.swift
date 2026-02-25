import SwiftUI
import Models
import Analytics
import DesignSystem

// MARK: - CreateTaskView

/// A sheet form for creating a new task.
///
/// Provides fields for all task properties including title, description,
/// status, priority, assignee, due date, and labels. Interaction tracking
/// is applied for the experimentation analytics pipeline.
public struct CreateTaskView: View {
    @Bindable var viewModel: CreateTaskViewModel
    let projectId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var newLabel: String = ""
    @State private var showDatePicker = false

    public init(viewModel: CreateTaskViewModel, projectId: UUID) {
        self.viewModel = viewModel
        self.projectId = projectId
    }

    public var body: some View {
        NavigationStack {
            Form {
                titleSection
                descriptionSection
                statusAndPrioritySection
                dueDateSection
                labelsSection

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Typography.footnote)
                            .foregroundStyle(ColorTokens.error)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.save(projectId: projectId)
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
            .trackInteraction(screen: "CreateTask")
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("Task Title", text: $viewModel.title)
                .font(Typography.body)
        } header: {
            Text("Title")
                .font(Typography.caption)
        }
    }

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $viewModel.taskDescription)
                .font(Typography.body)
                .frame(minHeight: 80)
        } header: {
            Text("Description")
                .font(Typography.caption)
        }
    }

    private var statusAndPrioritySection: some View {
        Section {
            Picker("Status", selection: $viewModel.status) {
                ForEach(TaskStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }

            Picker("Priority", selection: $viewModel.priority) {
                ForEach(TaskPriority.allCases) { priority in
                    Text(priority.displayName).tag(priority)
                }
            }
        } header: {
            Text("Status & Priority")
                .font(Typography.caption)
        }
    }

    private var dueDateSection: some View {
        Section {
            Toggle("Set Due Date", isOn: $showDatePicker)

            if showDatePicker {
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { viewModel.dueDate ?? Date() },
                        set: { viewModel.dueDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
            }
        } header: {
            Text("Due Date")
                .font(Typography.caption)
        }
        .onChange(of: showDatePicker) { _, isOn in
            if !isOn {
                viewModel.dueDate = nil
            }
        }
    }

    private var labelsSection: some View {
        Section {
            ForEach(viewModel.labels, id: \.self) { label in
                HStack {
                    Text(label)
                        .font(Typography.body)
                    Spacer()
                    Button {
                        viewModel.labels.removeAll { $0 == label }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(ColorTokens.destructive)
                    }
                }
            }

            HStack {
                TextField("Add label", text: $newLabel)
                    .font(Typography.body)

                Button {
                    let trimmed = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !viewModel.labels.contains(trimmed) else { return }
                    viewModel.labels.append(trimmed)
                    newLabel = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(ColorTokens.primary)
                }
                .disabled(newLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("Labels")
                .font(Typography.caption)
        }
    }
}
