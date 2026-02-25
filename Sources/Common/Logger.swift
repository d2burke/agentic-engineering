import Foundation
import os

/// Centralized logging facility for the TaskManager application.
/// Wraps `os.Logger` to provide structured, categorized logging
/// that integrates with the system's unified logging infrastructure.
public struct AppLogger: Sendable {

    /// Predefined log categories aligned with application domains.
    public enum Category: String, Sendable {
        case network = "Network"
        case persistence = "Persistence"
        case auth = "Auth"
        case analytics = "Analytics"
        case sync = "Sync"
        case ui = "UI"
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.taskmanager.app"

    private static func logger(for category: Category) -> os.Logger {
        os.Logger(subsystem: subsystem, category: category.rawValue)
    }

    /// Log a debug-level message. Use for development-time diagnostics.
    public static func debug(_ message: String, category: Category) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    /// Log an info-level message. Use for general operational events.
    public static func info(_ message: String, category: Category) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    /// Log a warning-level message. Use for recoverable issues.
    public static func warning(_ message: String, category: Category) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    /// Log an error-level message. Use for failures requiring attention.
    public static func error(_ message: String, category: Category) {
        logger(for: category).error("\(message, privacy: .public)")
    }
}
