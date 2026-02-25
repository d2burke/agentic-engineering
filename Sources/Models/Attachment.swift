import Foundation

/// A file attachment associated with a task.
///
/// Conforms to `Codable` and `Sendable` for serialization and safe concurrency,
/// and `Identifiable` for SwiftUI list rendering and analytics tracking.
public struct Attachment: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let taskId: UUID
    public let fileName: String
    public let mimeType: String
    public let url: URL
    public let uploadedBy: UUID
    public let createdAt: Date
    public let fileSize: Int64

    public init(
        id: UUID = UUID(),
        taskId: UUID,
        fileName: String,
        mimeType: String,
        url: URL,
        uploadedBy: UUID,
        createdAt: Date = Date(),
        fileSize: Int64
    ) {
        self.id = id
        self.taskId = taskId
        self.fileName = fileName
        self.mimeType = mimeType
        self.url = url
        self.uploadedBy = uploadedBy
        self.createdAt = createdAt
        self.fileSize = fileSize
    }
}
