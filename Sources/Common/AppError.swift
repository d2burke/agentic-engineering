import Foundation

/// Unified error type for the TaskManager application.
/// All domain-specific errors are represented as cases with associated context strings,
/// enabling consistent error handling, logging, and analytics tracking across modules.
public enum AppError: Error, Equatable, Sendable {
    case network(String)
    case decoding(String)
    case persistence(String)
    case auth(String)
    case validation(String)
    case notFound
    case unauthorized
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .network(let message):
            return "Network error: \(message)"
        case .decoding(let message):
            return "Decoding error: \(message)"
        case .persistence(let message):
            return "Persistence error: \(message)"
        case .auth(let message):
            return "Authentication error: \(message)"
        case .validation(let message):
            return "Validation error: \(message)"
        case .notFound:
            return "The requested resource was not found."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
