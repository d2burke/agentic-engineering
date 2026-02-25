import SwiftUI
import Models
import DesignSystem

// MARK: - AttachmentsView

/// A grid of attachment thumbnails for a task.
///
/// Displays file attachments in a responsive grid layout. Each attachment
/// shows a thumbnail (or file type icon for non-image types), file name,
/// and file size. Tapping opens a preview, and an add button allows
/// attaching new files via the photo picker.
public struct AttachmentsView: View {
    let attachments: [Attachment]

    @State private var selectedAttachment: Attachment?
    @State private var showingPhotoPicker = false

    private let gridColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: Spacing.sm)
    ]

    public init(attachments: [Attachment]) {
        self.attachments = attachments
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if attachments.isEmpty {
                HStack {
                    Text("No attachments")
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.textTertiary)

                    Spacer()

                    addButton
                }
            } else {
                LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
                    ForEach(attachments) { attachment in
                        AttachmentThumbnailView(attachment: attachment)
                            .onTapGesture {
                                selectedAttachment = attachment
                            }
                    }

                    addTile
                }
            }
        }
        .sheet(item: $selectedAttachment) { attachment in
            AttachmentPreviewSheet(attachment: attachment)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showingPhotoPicker = true
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "paperclip")
                    .font(Typography.caption)
                Text("Add")
                    .font(Typography.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(ColorTokens.primary)
        }
    }

    private var addTile: some View {
        Button {
            showingPhotoPicker = true
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(Typography.title3)
                    .foregroundStyle(ColorTokens.textTertiary)
                Text("Add")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .strokeBorder(ColorTokens.border, style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
}

// MARK: - AttachmentThumbnailView

/// A thumbnail view for a single attachment.
struct AttachmentThumbnailView: View {
    let attachment: Attachment

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(ColorTokens.backgroundTertiary)

                if attachment.mimeType.starts(with: "image/") {
                    AsyncImage(url: attachment.url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .font(Typography.title2)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                } else {
                    Image(systemName: iconForMimeType(attachment.mimeType))
                        .font(Typography.title2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            .frame(height: 80)

            Text(attachment.fileName)
                .font(Typography.caption2)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(formattedFileSize(attachment.fileSize))
                .font(Typography.caption2)
                .foregroundStyle(ColorTokens.textTertiary)
        }
    }

    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.starts(with: "image/") { return "photo" }
        if mimeType.starts(with: "video/") { return "film" }
        if mimeType.contains("pdf") { return "doc.richtext" }
        if mimeType.contains("zip") || mimeType.contains("archive") { return "archivebox" }
        return "doc"
    }

    private func formattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - AttachmentPreviewSheet

/// A simple sheet displaying an attachment preview.
struct AttachmentPreviewSheet: View {
    let attachment: Attachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if attachment.mimeType.starts(with: "image/") {
                    AsyncImage(url: attachment.url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "doc")
                            .font(.system(size: 64))
                            .foregroundStyle(ColorTokens.textTertiary)

                        Text(attachment.fileName)
                            .font(Typography.headline)
                            .foregroundStyle(ColorTokens.textPrimary)

                        Text(attachment.mimeType)
                            .font(Typography.caption)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle(attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
