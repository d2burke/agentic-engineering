import Foundation

/// Represents a user in the TaskManager application.
///
/// Conforms to `Codable` and `Sendable` for serialization and safe concurrency,
/// `Identifiable` for SwiftUI list rendering and analytics event correlation,
/// and `Hashable` for use in sets, dictionary keys, and diffable data sources.
public struct User: Codable, Sendable, Identifiable, Equatable, Hashable {
    public let id: UUID
    public var email: String
    public var displayName: String
    public var avatarURL: URL?
    public var role: UserRole
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        avatarURL: URL? = nil,
        role: UserRole = .member,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// The role a user holds within a project or the organization.
public enum UserRole: String, Codable, Sendable, CaseIterable, Identifiable, Hashable {
    case admin
    case member
    case viewer

    public var id: String { rawValue }

    /// A human-readable label suitable for display in the UI.
    public var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .member: return "Member"
        case .viewer: return "Viewer"
        }
    }
}
