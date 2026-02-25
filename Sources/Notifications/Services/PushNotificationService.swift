import Foundation
import UserNotifications
import Models
import Common
import Networking

// MARK: - PushNotificationServiceProtocol

/// Defines the contract for managing push notification permissions and device registration.
///
/// Conforming types handle the full lifecycle of push notification setup:
/// requesting user permission, registering the device token with the backend,
/// and querying the current permission state.
public protocol PushNotificationServiceProtocol: Sendable {
    /// Requests push notification permission from the user.
    ///
    /// - Throws: An error if the permission request fails at the system level.
    /// - Returns: `true` if the user granted permission, `false` otherwise.
    @discardableResult
    func requestPermission() async throws -> Bool

    /// Registers the device token with the backend API for push delivery.
    ///
    /// - Parameter token: The raw device token data provided by APNs.
    /// - Throws: An error if the registration API call fails.
    func registerDeviceToken(_ token: Data) async throws

    /// Whether the user has currently granted notification permission.
    var isPermissionGranted: Bool { get }
}

// MARK: - PushNotificationService

/// Production implementation of `PushNotificationServiceProtocol` using
/// `UNUserNotificationCenter` for permission management and the API client
/// for device token registration.
public final class PushNotificationService: PushNotificationServiceProtocol, @unchecked Sendable {

    // MARK: - State

    /// Tracks whether notification permission is currently granted.
    /// Updated after each permission request or status check.
    private var _isPermissionGranted: Bool = false

    /// Thread-safe lock for protecting mutable state.
    private let lock = NSLock()

    // MARK: - Dependencies

    /// The notification center used for permission requests.
    private let notificationCenter: UNUserNotificationCenter

    /// The API client for device token registration.
    private let apiClient: any APIClientProtocol

    // MARK: - Init

    /// Creates a new push notification service.
    ///
    /// - Parameters:
    ///   - apiClient: The API client for backend communication.
    ///   - notificationCenter: The notification center to use. Defaults to `.current()`.
    public init(
        apiClient: any APIClientProtocol,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.apiClient = apiClient
        self.notificationCenter = notificationCenter
    }

    // MARK: - PushNotificationServiceProtocol

    public var isPermissionGranted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isPermissionGranted
    }

    @discardableResult
    public func requestPermission() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        let granted = try await notificationCenter.requestAuthorization(options: options)

        lock.lock()
        _isPermissionGranted = granted
        lock.unlock()

        if granted {
            AppLogger.info("Push notification permission granted", category: .ui)
        } else {
            AppLogger.info("Push notification permission denied", category: .ui)
        }

        return granted
    }

    public func registerDeviceToken(_ token: Data) async throws {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        let payload = DeviceTokenPayload(
            token: tokenString,
            platform: "ios"
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(payload)

        let endpoint = NotificationEndpoints.registerDevice(body: body)
        try await apiClient.request(endpoint) as DeviceRegistrationResponse

        AppLogger.info("Device token registered successfully", category: .network)
    }
}

// MARK: - Request/Response Types

/// Payload sent to the backend when registering a device token.
private struct DeviceTokenPayload: Encodable, Sendable {
    let token: String
    let platform: String
}

/// Response from the device registration endpoint.
private struct DeviceRegistrationResponse: Decodable, Sendable {
    // The server may return an ID or status; we only need to confirm success.
}
