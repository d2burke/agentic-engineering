import XCTest
@testable import Auth
import Models
import Common

// MARK: - Mock Auth Service

/// In-memory mock conforming to `AuthServiceProtocol` for testing sign-up flows.
private actor MockAuthService: AuthServiceProtocol {
    var loginResult: Result<User, Error> = .failure(AppError.auth("Not configured"))
    var signUpResult: Result<User, Error> = .failure(AppError.auth("Not configured"))
    var logoutError: Error?
    private var _currentUser: User?
    var signUpCallCount = 0

    func configure(signUpResult: Result<User, Error>) {
        self.signUpResult = signUpResult
    }

    var currentUser: User? {
        _currentUser
    }

    var isAuthenticated: Bool {
        _currentUser != nil
    }

    func login(email: String, password: String) async throws -> User {
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
        if let error = logoutError {
            throw error
        }
        _currentUser = nil
    }
}

// MARK: - Tests

@MainActor
final class SignUpViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeFixtureUser() -> User {
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            email: "newuser@example.com",
            displayName: "New User"
        )
    }

    // MARK: - Validation — Password Mismatch

    func test_validation_passwordMismatchIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.displayName = "Test"
        viewModel.password = "password123"
        viewModel.confirmPassword = "differentpassword"

        XCTAssertFalse(viewModel.doPasswordsMatch)
        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertNotNil(viewModel.confirmPasswordValidationMessage)
    }

    // MARK: - Validation — Short Password

    func test_validation_shortPasswordIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.displayName = "Test"
        viewModel.password = "short"
        viewModel.confirmPassword = "short"

        XCTAssertFalse(viewModel.isPasswordValid)
        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertNotNil(viewModel.passwordValidationMessage)
    }

    // MARK: - Validation — Empty Display Name

    func test_validation_emptyDisplayNameIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.displayName = ""

        XCTAssertFalse(viewModel.isDisplayNameValid)
        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_validation_whitespaceOnlyDisplayNameIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.displayName = "   "

        XCTAssertFalse(viewModel.isDisplayNameValid)
        XCTAssertFalse(viewModel.isFormValid)
    }

    // MARK: - Validation — Invalid Email

    func test_validation_invalidEmailIsInvalid() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.displayName = "Test"
        viewModel.email = "notanemail"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        XCTAssertFalse(viewModel.isEmailValid)
        XCTAssertFalse(viewModel.isFormValid)
    }

    // MARK: - Validation — Valid Form

    func test_validation_allValidFieldsAreValid() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.displayName = "Test User"
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        XCTAssertTrue(viewModel.isFormValid)
    }

    // MARK: - Signup Success

    func test_signUp_successSetsIsSignedUp() async {
        let authService = MockAuthService()
        let fixtureUser = makeFixtureUser()
        await authService.configure(signUpResult: .success(fixtureUser))

        let viewModel = SignUpViewModel(authService: authService)
        viewModel.displayName = "New User"
        viewModel.email = "newuser@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        await viewModel.signUp()

        XCTAssertTrue(viewModel.isSignedUp)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Signup Failure

    func test_signUp_failureShowsErrorMessage() async {
        let authService = MockAuthService()
        await authService.configure(signUpResult: .failure(AppError.auth("Email already exists")))

        let viewModel = SignUpViewModel(authService: authService)
        viewModel.displayName = "New User"
        viewModel.email = "existing@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        await viewModel.signUp()

        XCTAssertFalse(viewModel.isSignedUp)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Signup with Invalid Form

    func test_signUp_invalidFormShowsValidationError() async {
        let authService = MockAuthService()
        let viewModel = SignUpViewModel(authService: authService)

        viewModel.displayName = ""
        viewModel.email = "bad"
        viewModel.password = "short"
        viewModel.confirmPassword = "mismatch"

        await viewModel.signUp()

        XCTAssertFalse(viewModel.isSignedUp)
        XCTAssertNotNil(viewModel.errorMessage)
        // Verify the service was never called
        let callCount = await authService.signUpCallCount
        XCTAssertEqual(callCount, 0)
    }
}
