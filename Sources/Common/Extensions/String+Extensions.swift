import Foundation

public extension String {
    /// Whether the string is a structurally valid email address.
    ///
    /// Uses a practical regex that covers the vast majority of valid addresses
    /// per RFC 5322 without being overly permissive.
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Whether the string contains at least one non-whitespace character.
    var isNotEmpty: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns a copy of the string truncated to the given maximum length,
    /// appending an ellipsis if truncation occurred.
    ///
    /// - Parameter length: The maximum number of characters before truncation.
    /// - Returns: The original string if it fits, or a truncated version with "..." appended.
    func truncated(to length: Int) -> String {
        guard count > length else { return self }
        return String(prefix(length)) + "..."
    }

    /// The initials derived from the first letter of each whitespace-separated word.
    ///
    /// For example, `"John Doe"` yields `"JD"`, and `"alice"` yields `"A"`.
    /// Returns an empty string if the string is empty or contains only whitespace.
    var initials: String {
        split(separator: " ")
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
}
