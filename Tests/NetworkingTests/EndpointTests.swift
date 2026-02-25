import XCTest
@testable import Networking
import Models

final class EndpointTests: XCTestCase {
    private let baseURL = URL(string: "https://api.taskmanager.test/v1")!

    // MARK: - Endpoint URL Request Construction

    func testEndpointCreatesValidURLRequest() throws {
        // Arrange
        let endpoint = Endpoint(
            path: "/test",
            method: .get,
            headers: ["X-Custom": "value"],
            queryItems: [URLQueryItem(name: "key", value: "val")]
        )

        // Act
        let request = try endpoint.urlRequest(baseURL: baseURL)

        // Assert
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url?.absoluteString.contains("/test") == true)
        XCTAssertTrue(request.url?.absoluteString.contains("key=val") == true)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "value")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testEndpointWithBodySetsContentType() throws {
        // Arrange
        let body = "{\"key\":\"value\"}".data(using: .utf8)!
        let endpoint = Endpoint(
            path: "/test",
            method: .post,
            body: body
        )

        // Act
        let request = try endpoint.urlRequest(baseURL: baseURL)

        // Assert
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpBody, body)
    }

    func testEndpointWithoutBodyDoesNotSetContentType() throws {
        // Arrange
        let endpoint = Endpoint(path: "/test", method: .get)

        // Act
        let request = try endpoint.urlRequest(baseURL: baseURL)

        // Assert
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    // MARK: - Auth Endpoints

    func testLoginEndpoint() throws {
        // Arrange
        let endpoint = AuthEndpoints.login(email: "user@test.com", password: "secret")

        // Act
        let request = try endpoint.urlRequest(baseURL: baseURL)

        // Assert
        XCTAssertEqual(endpoint.path, "/auth/login")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertNotNil(endpoint.body)

        // Verify body contains expected fields
        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["email"], "user@test.com")
        XCTAssertEqual(bodyDict?["password"], "secret")
    }

    func testSignUpEndpoint() throws {
        // Arrange
        let endpoint = AuthEndpoints.signUp(email: "new@test.com", password: "pw123", displayName: "New User")

        // Assert
        XCTAssertEqual(endpoint.path, "/auth/signup")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["email"], "new@test.com")
        XCTAssertEqual(bodyDict?["password"], "pw123")
        XCTAssertEqual(bodyDict?["display_name"], "New User")
    }

    func testRefreshTokenEndpoint() throws {
        // Arrange
        let endpoint = AuthEndpoints.refreshToken(token: "refresh-token-xyz")

        // Assert
        XCTAssertEqual(endpoint.path, "/auth/refresh")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["refresh_token"], "refresh-token-xyz")
    }

    func testLogoutEndpoint() {
        // Arrange
        let endpoint = AuthEndpoints.logout

        // Assert
        XCTAssertEqual(endpoint.path, "/auth/logout")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.body)
    }

    // MARK: - Project Endpoints

    func testProjectListEndpoint() {
        let endpoint = ProjectEndpoints.list
        XCTAssertEqual(endpoint.path, "/projects")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.body)
    }

    func testProjectGetEndpoint() {
        let projectId = UUID()
        let endpoint = ProjectEndpoints.get(id: projectId)
        XCTAssertEqual(endpoint.path, "/projects/\(projectId.uuidString)")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testProjectCreateEndpoint() throws {
        let endpoint = ProjectEndpoints.create(name: "New Project", description: "A description")
        XCTAssertEqual(endpoint.path, "/projects")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["name"], "New Project")
        XCTAssertEqual(bodyDict?["description"], "A description")
    }

    func testProjectCreateEndpointWithoutDescription() throws {
        let endpoint = ProjectEndpoints.create(name: "Simple Project", description: nil)
        XCTAssertEqual(endpoint.path, "/projects")
        XCTAssertEqual(endpoint.method, .post)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["name"], "Simple Project")
        XCTAssertNil(bodyDict?["description"])
    }

    func testProjectUpdateEndpoint() throws {
        let projectId = UUID()
        let endpoint = ProjectEndpoints.update(id: projectId, name: "Updated", description: "New desc")
        XCTAssertEqual(endpoint.path, "/projects/\(projectId.uuidString)")
        XCTAssertEqual(endpoint.method, .put)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["name"], "Updated")
        XCTAssertEqual(bodyDict?["description"], "New desc")
    }

    func testProjectDeleteEndpoint() {
        let projectId = UUID()
        let endpoint = ProjectEndpoints.delete(id: projectId)
        XCTAssertEqual(endpoint.path, "/projects/\(projectId.uuidString)")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertNil(endpoint.body)
    }

    func testProjectAddMemberEndpoint() throws {
        let projectId = UUID()
        let userId = UUID()
        let endpoint = ProjectEndpoints.addMember(projectId: projectId, userId: userId)
        XCTAssertEqual(endpoint.path, "/projects/\(projectId.uuidString)/members")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["user_id"], userId.uuidString)
    }

    // MARK: - Task Endpoints

    func testTaskListEndpoint() {
        let projectId = UUID()
        let endpoint = TaskEndpoints.list(projectId: projectId)
        XCTAssertEqual(endpoint.path, "/projects/\(projectId.uuidString)/tasks")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testTaskGetEndpoint() {
        let taskId = UUID()
        let endpoint = TaskEndpoints.get(id: taskId)
        XCTAssertEqual(endpoint.path, "/tasks/\(taskId.uuidString)")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testTaskCreateEndpoint() throws {
        let projectId = UUID()
        let assigneeId = UUID()
        let dueDate = Date(timeIntervalSince1970: 1700000000)

        let endpoint = TaskEndpoints.create(
            title: "New Task",
            taskDescription: "Do something",
            status: .todo,
            priority: .high,
            projectId: projectId,
            assigneeId: assigneeId,
            dueDate: dueDate,
            tags: ["urgent", "backend"]
        )

        XCTAssertEqual(endpoint.path, "/tasks")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: Any]
        XCTAssertEqual(bodyDict?["title"] as? String, "New Task")
        XCTAssertEqual(bodyDict?["description"] as? String, "Do something")
        XCTAssertEqual(bodyDict?["status"] as? String, "todo")
        XCTAssertEqual(bodyDict?["priority"] as? String, "high")
        XCTAssertEqual(bodyDict?["project_id"] as? String, projectId.uuidString)
        XCTAssertEqual(bodyDict?["assignee_id"] as? String, assigneeId.uuidString)
        XCTAssertEqual(bodyDict?["tags"] as? [String], ["urgent", "backend"])
    }

    func testTaskDeleteEndpoint() {
        let taskId = UUID()
        let endpoint = TaskEndpoints.delete(id: taskId)
        XCTAssertEqual(endpoint.path, "/tasks/\(taskId.uuidString)")
        XCTAssertEqual(endpoint.method, .delete)
    }

    func testTaskUpdateStatusEndpoint() throws {
        let taskId = UUID()
        let endpoint = TaskEndpoints.updateStatus(id: taskId, status: .done)
        XCTAssertEqual(endpoint.path, "/tasks/\(taskId.uuidString)/status")
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["status"], "done")
    }

    // MARK: - Comment Endpoints

    func testCommentListEndpoint() {
        let taskId = UUID()
        let endpoint = CommentEndpoints.list(taskId: taskId)
        XCTAssertEqual(endpoint.path, "/tasks/\(taskId.uuidString)/comments")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testCommentCreateEndpoint() throws {
        let taskId = UUID()
        let endpoint = CommentEndpoints.create(taskId: taskId, body: "Great work!")
        XCTAssertEqual(endpoint.path, "/tasks/\(taskId.uuidString)/comments")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["body"], "Great work!")
    }

    func testCommentDeleteEndpoint() {
        let commentId = UUID()
        let endpoint = CommentEndpoints.delete(id: commentId)
        XCTAssertEqual(endpoint.path, "/comments/\(commentId.uuidString)")
        XCTAssertEqual(endpoint.method, .delete)
    }

    // MARK: - User Endpoints

    func testUserMeEndpoint() {
        let endpoint = UserEndpoints.me
        XCTAssertEqual(endpoint.path, "/users/me")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testUserGetEndpoint() {
        let userId = UUID()
        let endpoint = UserEndpoints.get(id: userId)
        XCTAssertEqual(endpoint.path, "/users/\(userId.uuidString)")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testUserUpdateProfileEndpoint() throws {
        let avatarURL = URL(string: "https://cdn.test.com/avatar.jpg")!
        let endpoint = UserEndpoints.updateProfile(displayName: "Alice", avatarURL: avatarURL)
        XCTAssertEqual(endpoint.path, "/users/me")
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["display_name"], "Alice")
        XCTAssertEqual(bodyDict?["avatar_url"], "https://cdn.test.com/avatar.jpg")
    }

    // MARK: - Notification Endpoints

    func testNotificationListEndpoint() {
        let endpoint = NotificationEndpoints.list
        XCTAssertEqual(endpoint.path, "/notifications")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testNotificationMarkReadEndpoint() {
        let notifId = UUID()
        let endpoint = NotificationEndpoints.markRead(id: notifId)
        XCTAssertEqual(endpoint.path, "/notifications/\(notifId.uuidString)/read")
        XCTAssertEqual(endpoint.method, .patch)
    }

    func testNotificationMarkAllReadEndpoint() {
        let endpoint = NotificationEndpoints.markAllRead
        XCTAssertEqual(endpoint.path, "/notifications/read-all")
        XCTAssertEqual(endpoint.method, .post)
    }

    func testNotificationRegisterDeviceEndpoint() throws {
        let endpoint = NotificationEndpoints.registerDevice(token: "device-token-abc")
        XCTAssertEqual(endpoint.path, "/notifications/devices")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)

        let bodyDict = try JSONSerialization.jsonObject(with: endpoint.body!, options: []) as? [String: String]
        XCTAssertEqual(bodyDict?["device_token"], "device-token-abc")
    }
}
