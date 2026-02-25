import Foundation
import LocalAuthentication

// MARK: - BiometricType

/// The biometric authentication mechanism available on the current device.
public enum BiometricType: Sendable, Equatable {
    /// No biometric hardware or enrollment detected.
    case none
    /// Touch ID (fingerprint) is available.
    case touchID
    /// Face ID is available.
    case faceID
}

// MARK: - BiometricServiceProtocol

/// Protocol for biometric authentication capabilities.
///
/// Conforming types abstract over `LocalAuthentication` so that
/// view models can check availability and trigger authentication
/// without coupling to the system framework directly.
public protocol BiometricServiceProtocol: Sendable {
    /// Whether the device supports and has enrolled biometric authentication.
    func canUseBiometrics() -> Bool

    /// Prompt the user for biometric authentication.
    ///
    /// - Parameter reason: A human-readable string explaining why authentication is needed.
    /// - Returns: `true` if authentication succeeded.
    /// - Throws: An error if the authentication attempt fails or is cancelled.
    func authenticate(reason: String) async throws -> Bool

    /// The type of biometric hardware available on this device.
    var biometricType: BiometricType { get }
}

// MARK: - BiometricService

/// Production biometric service backed by `LAContext` from the LocalAuthentication framework.
public struct BiometricService: BiometricServiceProtocol {

    // MARK: - Initializer

    public init() {}

    // MARK: - BiometricServiceProtocol

    public var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .none
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    public func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error {
                throw BiometricError.notAvailable(error.localizedDescription)
            }
            throw BiometricError.notAvailable("Biometric authentication is not available.")
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.cancelled
            case .userFallback:
                throw BiometricError.userFallback
            case .biometryLockout:
                throw BiometricError.lockout
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            case .biometryNotAvailable:
                throw BiometricError.notAvailable("Biometry is not available on this device.")
            default:
                throw BiometricError.authenticationFailed(authError.localizedDescription)
            }
        }
    }
}

// MARK: - BiometricError

/// Errors specific to biometric authentication operations.
public enum BiometricError: Error, Equatable, Sendable {
    case notAvailable(String)
    case notEnrolled
    case lockout
    case cancelled
    case userFallback
    case authenticationFailed(String)

    public var localizedDescription: String {
        switch self {
        case .notAvailable(let reason):
            return "Biometrics not available: \(reason)"
        case .notEnrolled:
            return "No biometric credentials are enrolled on this device."
        case .lockout:
            return "Biometric authentication is locked out. Please use your passcode."
        case .cancelled:
            return "Biometric authentication was cancelled."
        case .userFallback:
            return "User chose to use password instead of biometrics."
        case .authenticationFailed(let reason):
            return "Biometric authentication failed: \(reason)"
        }
    }
}
