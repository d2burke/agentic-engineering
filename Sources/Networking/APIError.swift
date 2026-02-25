import Foundation

/// Errors that can occur during API communication.
///
/// Each case represents a distinct failure mode, enabling precise error handling
/// in the networking layer. Conforms to `Equatable` for testing and `Sendable`
/// for safe usage across concurrency boundaries.
public enum APIError: Error, Sendable, Equatable {
    /// The URL could not be constructed from the endpoint configuration.
    case invalidURL

    /// The server response was not a valid HTTP response.
    case invalidResponse

    /// The server returned a non-success HTTP status code.
    /// Contains the status code and optional response body for diagnostics.
    case httpError(statusCode: Int, data: Data?)

    /// The response body could not be decoded into the expected type.
    /// Contains a description of the decoding failure.
    case decodingError(String)

    /// A transport-level network error occurred (e.g., no connectivity, timeout).
    case networkError(String)

    /// The request was rejected due to missing or invalid authentication (HTTP 401).
    case unauthorized

    /// The requested resource does not exist (HTTP 404).
    case notFound

    /// The client has exceeded the server's rate limit (HTTP 429).
    case rateLimited

    /// An internal server error occurred (HTTP 500+).
    case serverError

    // MARK: - Equatable

    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case let (.httpError(lhsCode, lhsData), .httpError(rhsCode, rhsData)):
            return lhsCode == rhsCode && lhsData == rhsData
        case let (.decodingError(lhsMsg), .decodingError(rhsMsg)):
            return lhsMsg == rhsMsg
        case let (.networkError(lhsMsg), .networkError(rhsMsg)):
            return lhsMsg == rhsMsg
        case (.unauthorized, .unauthorized):
            return true
        case (.notFound, .notFound):
            return true
        case (.rateLimited, .rateLimited):
            return true
        case (.serverError, .serverError):
            return true
        default:
            return false
        }
    }
}
