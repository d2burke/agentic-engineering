import SwiftUI

/// A circular avatar view displaying a user's initials or image.
///
/// Falls back to showing initials derived from the user's display name
/// when no avatar URL is provided.
public struct AvatarView: View {
    private let name: String
    private let avatarURL: URL?
    private let size: CGFloat

    public init(name: String, avatarURL: URL? = nil, size: CGFloat = 32) {
        self.name = name
        self.avatarURL = avatarURL
        self.size = size
    }

    public var body: some View {
        if let avatarURL {
            AsyncImage(url: avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                initialsView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()

        return Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.blue.opacity(0.7))
            .clipShape(Circle())
    }
}
