import Foundation

/// HTTP methods supported by the API client.
///
/// Each case maps directly to its corresponding HTTP verb string,
/// used when constructing `URLRequest` instances for API communication.
public enum HTTPMethod: String, Sendable, Equatable, Hashable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
