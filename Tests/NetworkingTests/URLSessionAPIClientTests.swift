import XCTest
@testable import Networking
import Models

// MARK: - Mock URLProtocol

/// A custom URLProtocol subclass that intercepts all HTTP requests during testing,
/// allowing us to return predetermined responses without hitting the network.
final class MockURLProtocol: URLProtocol {
    /// Handler closure that provides the mock response for each request.
    /// Set this before running tests to control the response behavior.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Captures the most recent request for inspection in test assertions.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        MockURLProtocol.lastRequest = request

        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("MockURLProtocol.requestHandler is not set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op: cleanup is not needed for mock protocol
    }
}

// MARK: - URLSessionAPIClient Tests

final class URLSessionAPIClientTests: XCTestCase {
    private var client: URLSessionAPIClient!
    private var baseURL: URL!

    override func setUp() {
        super.setUp()
        baseURL = URL(string: "https://api.taskmanager.test/v1")!

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        client = URLSessionAPIClient(baseURL: baseURL, session: session)

        // Reset mock state
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastRequest = nil
    }

    override func tearDown() {
        client = nil
        baseURL = nil
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastRequest = nil
        super.tearDown()
    }

    // MARK: - Request Building Tests

    func testRequestBuildsCorrectURLRequest() async throws {
        // Arrange: configure mock to return empty success response
        let endpoint = Endpoint(
            path: "/test/resource",
            method: .get,
            queryItems: [URLQueryItem(name: "page", value: "1")]
        )

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{}".data(using: .utf8)!)
        }

        // Act
        let _: [String: String] = try await client.request(endpoint)

        // Assert
        let capturedRequest = MockURLProtocol.lastRequest
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
        XCTAssertTrue(capturedRequest?.url?.absoluteString.contains("/test/resource") == true)
        XCTAssertTrue(capturedRequest?.url?.absoluteString.contains("page=1") == true)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testAuthTokenIsInjectedIntoRequest() async throws {
        // Arrange
        let endpoint = Endpoint(path: "/secure/data", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{}".data(using: .utf8)!)
        }

        // Act: set token and make request
        await client.setAuthToken("test-token-abc123")
        let _: [String: String] = try await client.request(endpoint)

        // Assert
        let capturedRequest = MockURLProtocol.lastRequest
        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer test-token-abc123"
        )
    }

    func testRequestWithoutAuthTokenHasNoAuthorizationHeader() async throws {
        // Arrange
        let endpoint = Endpoint(path: "/public/data", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{}".data(using: .utf8)!)
        }

        // Act
        let _: [String: String] = try await client.request(endpoint)

        // Assert
        let capturedRequest = MockURLProtocol.lastRequest
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - Error Mapping Tests

    func testUnauthorizedErrorMapping() async {
        // Arrange
        let endpoint = Endpoint(path: "/protected", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert
        do {
            let _: [String: String] = try await client.request(endpoint)
            XCTFail("Expected APIError.unauthorized to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNotFoundErrorMapping() async {
        // Arrange
        let endpoint = Endpoint(path: "/missing", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert
        do {
            let _: [String: String] = try await client.request(endpoint)
            XCTFail("Expected APIError.notFound to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRateLimitedErrorMapping() async {
        // Arrange
        let endpoint = Endpoint(path: "/rate-limited", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert
        do {
            let _: [String: String] = try await client.request(endpoint)
            XCTFail("Expected APIError.rateLimited to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .rateLimited)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testServerErrorMapping() async {
        // Arrange
        let endpoint = Endpoint(path: "/server-error", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert
        do {
            let _: [String: String] = try await client.request(endpoint)
            XCTFail("Expected APIError.serverError to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .serverError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHTTPErrorMappingForGenericClientError() async {
        // Arrange
        let endpoint = Endpoint(path: "/bad-request", method: .post, body: Data())

        let responseBody = "{\"error\": \"bad request\"}".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseBody)
        }

        // Act & Assert
        do {
            let _: [String: String] = try await client.request(endpoint)
            XCTFail("Expected APIError.httpError to be thrown")
        } catch let error as APIError {
            if case let .httpError(statusCode, data) = error {
                XCTAssertEqual(statusCode, 400)
                XCTAssertEqual(data, responseBody)
            } else {
                XCTFail("Expected .httpError but got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Decoding Tests

    func testSuccessfulJSONDecoding() async throws {
        // Arrange: a simple Codable struct for testing
        struct TestResponse: Codable, Sendable, Equatable {
            let message: String
            let count: Int
        }

        let responseJSON = """
        {"message": "hello", "count": 42}
        """.data(using: .utf8)!

        let endpoint = Endpoint(path: "/test", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON)
        }

        // Act
        let result: TestResponse = try await client.request(endpoint)

        // Assert
        XCTAssertEqual(result.message, "hello")
        XCTAssertEqual(result.count, 42)
    }

    func testDecodingErrorForInvalidJSON() async {
        // Arrange
        struct TestResponse: Codable, Sendable {
            let value: Int
        }

        let invalidJSON = "not json".data(using: .utf8)!
        let endpoint = Endpoint(path: "/test", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, invalidJSON)
        }

        // Act & Assert
        do {
            let _: TestResponse = try await client.request(endpoint)
            XCTFail("Expected APIError.decodingError to be thrown")
        } catch let error as APIError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected .decodingError but got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSnakeCaseKeyDecoding() async throws {
        // Arrange: verify convertFromSnakeCase is active
        struct SnakeCaseResponse: Codable, Sendable {
            let userName: String
            let totalCount: Int
        }

        let responseJSON = """
        {"user_name": "alice", "total_count": 7}
        """.data(using: .utf8)!

        let endpoint = Endpoint(path: "/test", method: .get)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseJSON)
        }

        // Act
        let result: SnakeCaseResponse = try await client.request(endpoint)

        // Assert
        XCTAssertEqual(result.userName, "alice")
        XCTAssertEqual(result.totalCount, 7)
    }

    func testVoidRequestDoesNotThrowOnSuccess() async throws {
        // Arrange
        let endpoint = Endpoint(path: "/action", method: .post)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert: should not throw
        try await client.request(endpoint)
    }
}
