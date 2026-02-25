import Foundation

/// Centralized date formatting utilities.
/// Uses cached formatters to avoid the cost of repeated instantiation.
public enum DateFormatting {

    // MARK: - Formatters

    /// Formatter for relative date descriptions (e.g. "2 hours ago", "yesterday").
    public static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter
    }()

    /// ISO 8601 formatter for API serialization and round-tripping.
    public static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Human-readable display formatter (e.g. "Jan 15, 2025 at 3:30 PM").
    public static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Formatting Methods

    /// Returns a relative description of the date (e.g. "2 hours ago").
    public static func relativeString(from date: Date, relativeTo now: Date = Date()) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: now)
    }

    /// Returns a human-readable display string (e.g. "Jan 15, 2025 at 3:30 PM").
    public static func displayString(from date: Date) -> String {
        displayFormatter.string(from: date)
    }

    /// Returns an ISO 8601 string suitable for API communication.
    public static func iso8601String(from date: Date) -> String {
        iso8601Formatter.string(from: date)
    }

    /// Parses an ISO 8601 string back into a `Date`.
    public static func date(fromISO8601 string: String) -> Date? {
        iso8601Formatter.date(from: string)
    }
}

// MARK: - Date Convenience Extensions

public extension Date {
    /// A relative description of this date compared to now (e.g. "2 hours ago").
    var relativeString: String {
        DateFormatting.relativeString(from: self)
    }

    /// A human-readable display string (e.g. "Jan 15, 2025 at 3:30 PM").
    var displayString: String {
        DateFormatting.displayString(from: self)
    }

    /// An ISO 8601 formatted string for this date.
    var iso8601String: String {
        DateFormatting.iso8601String(from: self)
    }
}
