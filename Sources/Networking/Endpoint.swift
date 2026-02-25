import Foundation

/// Describes a single API endpoint, encapsulating the path, HTTP method,
/// headers, query parameters, and optional request body.
///
/// Use `urlRequest(baseURL:)` to convert an `Endpoint` into a fully-formed
/// `URLRequest` ready for execution by the API client.
public struct Endpoint: Sendable {
    /// The path component of the URL (e.g., "/auth/login").
    public let path: String

    /// The HTTP method for this request.
    public let method: HTTPMethod

    /// Additional HTTP headers to include in the request.
    public let headers: [String: String]

    /// Optional query string parameters appended to the URL.
    public let queryItems: [URLQueryItem]?

    /// Optional HTTP body data (typically JSON-encoded).
    public let body: Data?

    /// Creates a new endpoint descriptor.
    ///
    /// - Parameters:
    ///   - path: The URL path component.
    ///   - method: The HTTP method. Defaults to `.get`.
    ///   - headers: Additional headers. Defaults to an empty dictionary.
    ///   - queryItems: Optional query parameters. Defaults to `nil`.
    ///   - body: Optional request body. Defaults to `nil`.
    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    /// Constructs a `URLRequest` by resolving this endpoint against the given base URL.
    ///
    /// - Parameter baseURL: The base URL of the API server.
    /// - Throws: `APIError.invalidURL` if a valid URL cannot be constructed.
    /// - Returns: A configured `URLRequest` ready for execution.
    public func urlRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)

        if let queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Set default content type for requests with a body
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Apply Accept header by default
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Apply custom headers (may override defaults)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body

        return request
    }
}
