import Foundation

/// Manages authentication token lifecycle and injects authorization headers
/// into outgoing HTTP requests.
///
/// This actor provides thread-safe access to the auth token, ensuring that
/// concurrent requests all receive the correct authorization header without
/// data races.
public actor AuthInterceptor {
    /// The current Bearer token, or `nil` if unauthenticated.
    private var token: String?

    /// Creates a new interceptor, optionally pre-configured with a token.
    ///
    /// - Parameter token: An initial Bearer token, or `nil`.
    public init(token: String? = nil) {
        self.token = token
    }

    /// Returns a copy of the request with the `Authorization: Bearer` header
    /// added if a token is available. If no token is set, the request is
    /// returned unmodified.
    ///
    /// - Parameter request: The original URL request.
    /// - Returns: A new request with the authorization header injected.
    public func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        if let token {
            mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return mutableRequest
    }

    /// Sets the authentication token.
    ///
    /// - Parameter token: The new Bearer token, or `nil` to clear authentication.
    public func setToken(_ token: String?) {
        self.token = token
    }

    /// Clears the stored authentication token.
    public func clearToken() {
        self.token = nil
    }

    /// Whether the interceptor currently holds a valid authentication token.
    public var isAuthenticated: Bool {
        token != nil
    }
}
