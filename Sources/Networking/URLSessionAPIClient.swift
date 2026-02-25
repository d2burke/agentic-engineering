import Foundation
import Common

/// Production implementation of `APIClientProtocol` using `URLSession`.
///
/// This actor provides thread-safe network communication with automatic
/// JSON decoding, authentication token injection, and structured error mapping.
/// All HTTP status codes are translated into typed `APIError` cases for
/// consistent error handling throughout the application.
public actor URLSessionAPIClient: APIClientProtocol {
    /// The base URL for all API requests.
    public let baseURL: URL

    /// The current authentication token, if set.
    public private(set) var authToken: String?

    /// The URL session used for executing requests.
    private let session: URLSession

    /// JSON decoder configured with snake_case key conversion for API responses.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Creates a new API client.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL of the API server.
    ///   - session: The URL session to use. Defaults to `.shared`.
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Sets or clears the authentication token.
    public func setAuthToken(_ token: String?) {
        self.authToken = token
        if token != nil {
            AppLogger.debug("Auth token updated", category: .network)
        } else {
            AppLogger.debug("Auth token cleared", category: .network)
        }
    }

    /// Executes a request and decodes the response into the specified `Decodable` type.
    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await performRequest(endpoint)

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch let decodingError {
            AppLogger.error(
                "Decoding failed for \(T.self): \(decodingError.localizedDescription)",
                category: .network
            )
            throw APIError.decodingError(decodingError.localizedDescription)
        }
    }

    /// Executes a request that does not return a response body.
    public func request(_ endpoint: Endpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    // MARK: - Private

    /// Builds, executes, and validates an HTTP request, returning the raw response data.
    private func performRequest(_ endpoint: Endpoint) async throws -> Data {
        let urlRequest: URLRequest
        do {
            var request = try endpoint.urlRequest(baseURL: baseURL)

            // Inject auth token if available
            if let authToken {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }

            urlRequest = request
        } catch {
            throw APIError.invalidURL
        }

        AppLogger.debug(
            "\(endpoint.method.rawValue) \(urlRequest.url?.absoluteString ?? "unknown")",
            category: .network
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            AppLogger.error("Network request failed: \(error.localizedDescription)", category: .network)
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.error("Invalid response type received", category: .network)
            throw APIError.invalidResponse
        }

        AppLogger.debug(
            "Response \(httpResponse.statusCode) for \(endpoint.path) (\(data.count) bytes)",
            category: .network
        )

        try validateStatusCode(httpResponse.statusCode, data: data)

        return data
    }

    /// Maps HTTP status codes to typed `APIError` cases.
    ///
    /// Status codes in the 200-299 range are considered successful.
    /// All other codes are mapped to specific error cases for precise handling.
    private func validateStatusCode(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200 ..< 300:
            return
        case 401:
            AppLogger.warning("Unauthorized request (401)", category: .network)
            throw APIError.unauthorized
        case 404:
            AppLogger.warning("Resource not found (404)", category: .network)
            throw APIError.notFound
        case 429:
            AppLogger.warning("Rate limited (429)", category: .network)
            throw APIError.rateLimited
        case 500...:
            AppLogger.error("Server error (\(statusCode))", category: .network)
            throw APIError.serverError
        default:
            AppLogger.warning("HTTP error \(statusCode)", category: .network)
            throw APIError.httpError(statusCode: statusCode, data: data)
        }
    }
}
