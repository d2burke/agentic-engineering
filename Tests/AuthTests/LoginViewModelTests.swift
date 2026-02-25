import XCTest
@testable import Auth
import Models
import Common

// MARK: - Mock Auth Service

/// In-memory mock conforming to `AuthServiceProtocol` for testing.
private actor MockAuthService: AuthServiceProtocol {
    var loginResult: Result<User, Error> = .failure(AppError.auth("Not configured"))
    var signUpResult: Result<User, Error> = .failure(AppError.auth("Not configured"))
    var logoutError: Error?
    private var _currentUser: User?
    var loginCallCount = 0
    var signUpCallCount = 0
    var logoutCallCount = 0

    func configure(loginResult: Result<User, Error>) {
        self.loginResult = loginResult
    }

    func configure(signUpResult: Result<User, Error>) {
        self.signUpResult = signUpResult
    }

    func configure(currentUser: User?) {
        self._currentUser = currentUser
    }

    var currentUser: User? {
        _currentUser
    }

    var isAuthenticated: Bool {
        _currentUser != nil
    }

    func login(email: String, password: String) async throws -> User {
        loginCallCount += 1
        switch loginResult {
        case .success(let user):
            _currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        signUpCallCount += 1
        switch signUpResult {
        case .success(let user):
            _currentUser = user
            return user
        case .failure(let error):
            throw error
        }
    }

    func logout() async throws {
        logoutCallCount += 1
        if let error = logoutError {
            throw error
        }
        _currentUser = nil
    }
}

// MARK: - Mock Biometric Service

/// Mock biometric service for testing.
private struct MockBiometricService: BiometricServiceProtocol {
    var canUseBiometricsResult: Bool = false
    var authenticateResult: Result<Bool, Error> = .success(false)
    var biometricTypeValue: BiometricType = .none

    func canUseBiometrics() -> Bool {
        canUseBiometricsResult
    }

    func authenticate(reason: String) async throws -> Bool {
        switch authenticateResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    var biometricType: BiometricType {
        biometricTypeValue
    }
}

// MARK: - Tests

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeFixtureUser() -> User {
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            email: "test@example.com",
            displayName: "Test User"
        )
    }

    // MARK: - Initial State

    func test_initialState_allFieldsAreEmpty() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAuthenticated)
    }

    // MARK: - Validation

    func test_validation_emptyEmailIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = ""
        XCTAssertFalse(viewModel.isEmailValid)
        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_validation_invalidEmailFormat() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = "not-an-email"
        viewModel.password = "password123"

        XCTAssertFalse(viewModel.isEmailValid)
        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertNotNil(viewModel.emailValidationMessage)
    }

    func test_validation_validEmailFormat() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = "user@example.com"
        XCTAssertTrue(viewModel.isEmailValid)
        XCTAssertNil(viewModel.emailValidationMessage)
    }

    func test_validation_emptyPasswordIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.password = ""

        XCTAssertFalse(viewModel.isPasswordValid)
        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_validation_whitespaceOnlyPasswordIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.password = "   "

        XCTAssertFalse(viewModel.isPasswordValid)
        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_validation_validFormReturnsTrue() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.password = "password123"

        XCTAssertTrue(viewModel.isFormValid)
    }

    // MARK: - Login Success

    func test_login_successUpdatesIsAuthenticated() async {
        let authService = MockAuthService()
        let fixtureUser = makeFixtureUser()
        await authService.configure(loginResult: .success(fixtureUser))

        let viewModel = LoginViewModel(authService: authService)
        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        await viewModel.login()

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Login Failure

    func test_login_failureShowsErrorMessage() async {
        let authService = MockAuthService()
        await authService.configure(loginResult: .failure(AppError.auth("Invalid credentials")))

        let viewModel = LoginViewModel(authService: authService)
        viewModel.email = "test@example.com"
        viewModel.password = "wrongpassword"

        await viewModel.login()

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_login_invalidFormShowsValidationError() async {
        let authService = MockAuthService()
        let viewModel = LoginViewModel(authService: authService)

        viewModel.email = "invalid"
        viewModel.password = ""

        await viewModel.login()

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email and password.")
    }

    // MARK: - Biometric Login

    func test_biometricLogin_unavailableShowsError() async {
        let authService = MockAuthService()
        let biometricService = MockBiometricService(canUseBiometricsResult: false)
        let viewModel = LoginViewModel(
            authService: authService,
            biometricService: biometricService
        )

        await viewModel.loginWithBiometrics()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isAuthenticated)
    }
}
