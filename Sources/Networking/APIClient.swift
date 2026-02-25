import Foundation

/// Protocol defining the contract for an API client capable of executing
/// network requests against a remote server.
///
/// Implementations must be `Sendable` to allow safe usage across concurrency
/// domains (e.g., from multiple async tasks or actors).
public protocol APIClientProtocol: Sendable {
    /// The base URL of the API server (e.g., "https://api.taskmanager.com/v1").
    var baseURL: URL { get }

    /// The current authentication token, if any.
    /// Setting this value causes subsequent requests to include a Bearer token header.
    var authToken: String? { get }

    /// Sets the authentication token for subsequent requests.
    ///
    /// - Parameter token: The Bearer token string, or `nil` to clear authentication.
    func setAuthToken(_ token: String?) async

    /// Executes an API request and decodes the response body into the specified type.
    ///
    /// - Parameter endpoint: The endpoint descriptor for the request.
    /// - Throws: `APIError` if the request fails or the response cannot be decoded.
    /// - Returns: The decoded response object.
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T

    /// Executes an API request that does not return a response body.
    ///
    /// Useful for DELETE operations or other fire-and-forget endpoints
    /// where only the HTTP status code matters.
    ///
    /// - Parameter endpoint: The endpoint descriptor for the request.
    /// - Throws: `APIError` if the request fails.
    func request(_ endpoint: Endpoint) async throws
}
