import SwiftUI
import Models
import DesignSystem

// MARK: - CommentsView

/// A view displaying a list of comments with a text input for adding new ones.
///
/// Shows each comment with the author's name (derived from authorId),
/// comment body, and timestamp. Supports swipe-to-delete for the user's
/// own comments.
public struct CommentsView: View {
    @Bindable var viewModel: CommentsViewModel
    let taskId: UUID

    public init(viewModel: CommentsViewModel, taskId: UUID) {
        self.viewModel = viewModel
        self.taskId = taskId
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if viewModel.comments.isEmpty && !viewModel.isLoading {
                Text("No comments yet")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .padding(.vertical, Spacing.sm)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRowView(comment: comment) {
                        Task {
                            await viewModel.deleteComment(id: comment.id)
                        }
                    }

                    if comment.id != viewModel.comments.last?.id {
                        Divider()
                    }
                }
            }

            commentInputBar
        }
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Add a comment...", text: $viewModel.newCommentText, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await viewModel.addComment(taskId: taskId)
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(
                        viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? ColorTokens.textTertiary
                        : ColorTokens.primary
                    )
            }
            .disabled(
                viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || viewModel.isLoading
            )
        }
    }
}

// MARK: - CommentRowView

/// A single comment row displaying author info, body text, and timestamp.
struct CommentRowView: View {
    let comment: Comment
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                AvatarView(name: "User", size: 24)

                Text("User")
                    .font(Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer()

                Text(comment.createdAt, style: .relative)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Text(comment.body)
                .font(Typography.body)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .padding(.vertical, Spacing.xs)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
