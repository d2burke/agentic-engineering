import Foundation
import Models

/// Factory methods for creating test data with sensible defaults.
///
/// Each method returns a fully populated model instance. All parameters
/// have default values, so callers can override only the fields relevant
/// to a given test case while leaving the rest deterministic.
public enum Fixtures {

    // MARK: - Deterministic Identifiers

    /// A set of fixed UUIDs for reproducible test data.
    public static let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    public static let projectId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    public static let taskId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    public static let commentId = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    public static let attachmentId = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    public static let notificationId = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!

    /// A fixed reference date for deterministic timestamps.
    public static let referenceDate = Date(timeIntervalSinceReferenceDate: 700_000_000)

    // MARK: - Factory Methods

    /// Creates a `User` with sensible defaults.
    public static func user(
        id: UUID = Fixtures.userId,
        email: String = "test@example.com",
        displayName: String = "Test User",
        avatarURL: URL? = nil,
        role: UserRole = .member,
        createdAt: Date = Fixtures.referenceDate,
        updatedAt: Date = Fixtures.referenceDate
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            avatarURL: avatarURL,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a `Project` with sensible defaults.
    public static func project(
        id: UUID = Fixtures.projectId,
        name: String = "Test Project",
        projectDescription: String? = "A test project for unit tests.",
        ownerId: UUID = Fixtures.userId,
        memberIds: [UUID] = [],
        createdAt: Date = Fixtures.referenceDate,
        updatedAt: Date = Fixtures.referenceDate
    ) -> Project {
        Project(
            id: id,
            name: name,
            projectDescription: projectDescription,
            ownerId: ownerId,
            memberIds: memberIds,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a `TaskItem` with sensible defaults.
    public static func taskItem(
        id: UUID = Fixtures.taskId,
        title: String = "Test Task",
        taskDescription: String? = "A test task for unit tests.",
        status: TaskStatus = .todo,
        priority: TaskPriority = .medium,
        projectId: UUID = Fixtures.projectId,
        assigneeId: UUID? = Fixtures.userId,
        reporterId: UUID = Fixtures.userId,
        tags: [String] = ["test"],
        dueDate: Date? = nil,
        createdAt: Date = Fixtures.referenceDate,
        updatedAt: Date = Fixtures.referenceDate,
        attachmentIds: [UUID] = [],
        commentCount: Int = 0
    ) -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            taskDescription: taskDescription,
            status: status,
            priority: priority,
            projectId: projectId,
            assigneeId: assigneeId,
            reporterId: reporterId,
            tags: tags,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            attachmentIds: attachmentIds,
            commentCount: commentCount
        )
    }

    /// Creates a `Comment` with sensible defaults.
    public static func comment(
        id: UUID = Fixtures.commentId,
        taskId: UUID = Fixtures.taskId,
        authorId: UUID = Fixtures.userId,
        body: String = "This is a test comment.",
        createdAt: Date = Fixtures.referenceDate,
        updatedAt: Date = Fixtures.referenceDate
    ) -> Comment {
        Comment(
            id: id,
            taskId: taskId,
            authorId: authorId,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates an `Attachment` with sensible defaults.
    public static func attachment(
        id: UUID = Fixtures.attachmentId,
        taskId: UUID = Fixtures.taskId,
        fileName: String = "screenshot.png",
        mimeType: String = "image/png",
        url: URL = URL(string: "https://cdn.example.com/files/screenshot.png")!,
        uploadedBy: UUID = Fixtures.userId,
        createdAt: Date = Fixtures.referenceDate,
        fileSize: Int64 = 1_048_576
    ) -> Attachment {
        Attachment(
            id: id,
            taskId: taskId,
            fileName: fileName,
            mimeType: mimeType,
            url: url,
            uploadedBy: uploadedBy,
            createdAt: createdAt,
            fileSize: fileSize
        )
    }

    /// Creates a `NotificationItem` with sensible defaults.
    public static func notificationItem(
        id: UUID = Fixtures.notificationId,
        userId: UUID = Fixtures.userId,
        type: NotificationType = .taskAssigned,
        title: String = "Task Assigned",
        body: String = "You have been assigned a new task.",
        relatedTaskId: UUID? = Fixtures.taskId,
        relatedProjectId: UUID? = Fixtures.projectId,
        isRead: Bool = false,
        createdAt: Date = Fixtures.referenceDate
    ) -> NotificationItem {
        NotificationItem(
            id: id,
            userId: userId,
            type: type,
            title: title,
            body: body,
            relatedTaskId: relatedTaskId,
            relatedProjectId: relatedProjectId,
            isRead: isRead,
            createdAt: createdAt
        )
    }
}
