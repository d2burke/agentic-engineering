import Foundation
import CoreGraphics

// MARK: - PIIScrubber

/// Removes personally identifiable information from analytics metadata
/// before events are stored or exported.
///
/// This is a critical privacy safeguard that ensures the analytics pipeline
/// never persists raw PII even if upstream code accidentally includes it
/// in event metadata.
public struct PIIScrubber: Sendable {

    // MARK: - Sensitive Key Patterns

    /// Keys whose values should always be fully redacted, regardless of content.
    private static let sensitiveKeyPatterns: [String] = [
        "password",
        "token",
        "secret",
        "key",
        "ssn",
    ]

    // MARK: - PII Regex Patterns

    /// Matches common email address formats.
    private static let emailPattern: String =
        "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

    /// Matches US phone number formats (with or without country code,
    /// dashes, dots, spaces, and parentheses).
    private static let phonePattern: String =
        "(?:\\+?1[\\s.-]?)?(?:\\(?\\d{3}\\)?[\\s.-]?)\\d{3}[\\s.-]?\\d{4}"

    private static let emailRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: emailPattern, options: [])
    }()

    private static let phoneRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: phonePattern, options: [])
    }()

    // MARK: - Redaction Constant

    private static let redacted = "[REDACTED]"

    // MARK: - Public API

    /// Scrub PII from an analytics metadata dictionary.
    ///
    /// - Removes values matching email or phone number patterns.
    /// - Fully redacts values for keys that contain sensitive terms
    ///   (password, token, secret, key, ssn).
    ///
    /// - Parameter metadata: The raw metadata dictionary.
    /// - Returns: A sanitized copy safe for storage and export.
    public static func scrub(_ metadata: [String: String]) -> [String: String] {
        var result: [String: String] = [:]

        for (key, value) in metadata {
            let lowercasedKey = key.lowercased()

            // Check if the key itself is sensitive.
            if sensitiveKeyPatterns.contains(where: { lowercasedKey.contains($0) }) {
                result[key] = redacted
                continue
            }

            // Check if the value contains PII patterns.
            var scrubbedValue = value

            if let emailRegex = emailRegex {
                let range = NSRange(scrubbedValue.startIndex..., in: scrubbedValue)
                scrubbedValue = emailRegex.stringByReplacingMatches(
                    in: scrubbedValue,
                    options: [],
                    range: range,
                    withTemplate: redacted
                )
            }

            if let phoneRegex = phoneRegex {
                let range = NSRange(scrubbedValue.startIndex..., in: scrubbedValue)
                scrubbedValue = phoneRegex.stringByReplacingMatches(
                    in: scrubbedValue,
                    options: [],
                    range: range,
                    withTemplate: redacted
                )
            }

            result[key] = scrubbedValue
        }

        return result
    }

    /// Snap a coordinate to a 44pt grid for privacy.
    ///
    /// This prevents analytics from storing precise tap locations that
    /// could be used to infer keyboard input or other sensitive spatial
    /// patterns. The 44pt grid aligns with Apple's minimum tap target
    /// recommendation.
    ///
    /// - Parameter point: The original coordinate.
    /// - Returns: The coordinate snapped to the nearest 44pt grid intersection.
    public static func snapToGrid(_ point: CGPoint) -> CGPoint {
        let gridSize: CGFloat = 44.0
        let snappedX = (point.x / gridSize).rounded(.down) * gridSize
        let snappedY = (point.y / gridSize).rounded(.down) * gridSize
        return CGPoint(x: snappedX, y: snappedY)
    }
}
