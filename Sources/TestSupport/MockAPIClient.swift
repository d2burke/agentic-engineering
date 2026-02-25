import Foundation
import Networking

/// A mock API client for use in unit and integration tests.
///
/// `MockAPIClient` conforms to `APIClientProtocol` and records every
/// endpoint invocation so tests can assert on which requests were made.
/// Responses (or errors) are configured via closures before each test.
///
/// ## Usage
/// ```swift
/// let mock = MockAPIClient(baseURL: URL(string: "https://test.api")!)
/// mock.requestHandler = { endpoint in
///     return try JSONEncoder().encode(Fixtures.user())
/// }
/// ```
public final class MockAPIClient: APIClientProtocol, @unchecked Sendable {

    // MARK: - APIClientProtocol Properties

    /// The base URL used by this mock client.
    public let baseURL: URL

    /// The current auth token. Set via `setAuthToken(_:)`.
    public private(set) var authToken: String?

    // MARK: - Recording

    /// All endpoints that have been passed to `request(_:)` or `request(_ endpoint:)`.
    public private(set) var calledEndpoints: [Endpoint] = []

    /// The number of requests that have been made.
    public var callCount: Int { calledEndpoints.count }

    /// The most recent endpoint called, or `nil` if no requests have been made.
    public var lastEndpoint: Endpoint? { calledEndpoints.last }

    // MARK: - Configurable Handlers

    /// A closure invoked for `request<T>(_ endpoint:)`. Return encoded `Data`
    /// or throw an error to simulate a failure.
    /// The default handler throws `APIError.invalidResponse`.
    public var requestHandler: ((Endpoint) throws -> Data)?

    /// A closure invoked for `request(_ endpoint:)` (void return).
    /// Throw an error to simulate a failure.
    public var voidRequestHandler: ((Endpoint) throws -> Void)?

    // MARK: - JSON Decoder

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Init

    /// Creates a mock API client with the given base URL.
    ///
    /// - Parameter baseURL: The base URL to report. Defaults to a test URL.
    public init(baseURL: URL = URL(string: "https://api.test.taskmanager.com/v1")!) {
        self.baseURL = baseURL
    }

    // MARK: - APIClientProtocol Conformance

    /// Records the token for subsequent inspection in tests.
    public func setAuthToken(_ token: String?) async {
        authToken = token
    }

    /// Executes the `requestHandler` closure and decodes the returned data.
    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        calledEndpoints.append(endpoint)
        guard let handler = requestHandler else {
            throw APIError.invalidResponse
        }
        let data = try handler(endpoint)
        return try decoder.decode(T.self, from: data)
    }

    /// Executes the `voidRequestHandler` closure.
    public func request(_ endpoint: Endpoint) async throws {
        calledEndpoints.append(endpoint)
        if let handler = voidRequestHandler {
            try handler(endpoint)
        }
    }

    // MARK: - Helpers

    /// Resets all recorded state and clears handlers.
    public func reset() {
        calledEndpoints.removeAll()
        authToken = nil
        requestHandler = nil
        voidRequestHandler = nil
    }

    /// Configures the mock to return the given `Encodable` value for all typed requests.
    public func stub<T: Encodable>(response value: T) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        requestHandler = { _ in
            try encoder.encode(value)
        }
    }

    /// Configures the mock to throw the given error for all requests.
    public func stub(error: Error) {
        requestHandler = { _ in throw error }
        voidRequestHandler = { _ in throw error }
    }
}
