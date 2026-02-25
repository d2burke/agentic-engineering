import SwiftUI

// MARK: - AvatarView

/// A circular avatar displaying either a remote image or the user's
/// initials on a deterministically colored background.
///
/// The background color is derived from a hash of the user's name,
/// ensuring the same name always gets the same color for visual
/// consistency across the application.
public struct AvatarView: View {
    private let name: String
    private let imageURL: URL?
    private let size: CGFloat

    /// - Parameters:
    ///   - name: The user's display name (used for initials and color).
    ///   - imageURL: Optional remote image URL. If `nil`, initials are shown.
    ///   - size: The diameter of the avatar circle. Default is 36pt.
    public init(name: String, imageURL: URL? = nil, size: CGFloat = 36) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
    }

    public var body: some View {
        if let imageURL = imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    initialsView
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    initialsView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    // MARK: - Initials View

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Computed Properties

    /// Extract up to two initials from the name.
    private var initials: String {
        let components = name.split(separator: " ")
        switch components.count {
        case 0:
            return "?"
        case 1:
            return String(components[0].prefix(1)).uppercased()
        default:
            let first = String(components[0].prefix(1))
            let last = String(components[components.count - 1].prefix(1))
            return (first + last).uppercased()
        }
    }

    /// Deterministic color derived from the name's hash value.
    private var avatarColor: Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint, .cyan, .brown
        ]
        // Use a stable hash: sum of scalar values to avoid cross-run hash randomization.
        let stableHash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[abs(stableHash) % colors.count]
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Avatar Views") {
    HStack(spacing: 16) {
        AvatarView(name: "Alice Johnson")
        AvatarView(name: "Bob Smith", size: 48)
        AvatarView(name: "Charlie")
        AvatarView(name: "Diana Prince", size: 24)
    }
    .padding()
}
#endif
