import XCTest
@testable import Profile
import Models
import Common

// MARK: - Mock User Repository

/// In-memory mock conforming to `UserRepositoryProtocol` for testing.
private final class MockUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    var fetchCurrentUserResult: Result<User, Error> = .failure(AppError.notFound)
    var updateProfileResult: Result<User, Error> = .failure(AppError.notFound)
    var fetchUserResult: Result<User, Error> = .failure(AppError.notFound)

    var fetchCurrentUserCallCount = 0
    var updateProfileCallCount = 0
    var lastUpdateDisplayName: String?
    var lastUpdateAvatarURL: URL?

    func fetchCurrentUser() async throws -> User {
        fetchCurrentUserCallCount += 1
        switch fetchCurrentUserResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }

    func updateProfile(displayName: String?, avatarURL: URL?) async throws -> User {
        updateProfileCallCount += 1
        lastUpdateDisplayName = displayName
        lastUpdateAvatarURL = avatarURL
        switch updateProfileResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }

    func fetchUser(id: UUID) async throws -> User {
        switch fetchUserResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Tests

@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeFixtureUser(
        displayName: String = "Test User",
        email: String = "test@example.com"
    ) -> User {
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            email: email,
            displayName: displayName,
            avatarURL: URL(string: "https://example.com/avatar.jpg")
        )
    }

    // MARK: - Load Profile

    func test_loadProfile_successPopulatesUser() async {
        let repository = MockUserRepository()
        let fixtureUser = makeFixtureUser()
        repository.fetchCurrentUserResult = .success(fixtureUser)

        let viewModel = ProfileViewModel(userRepository: repository)

        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.user?.id, fixtureUser.id)
        XCTAssertEqual(viewModel.user?.email, fixtureUser.email)
        XCTAssertEqual(viewModel.user?.displayName, fixtureUser.displayName)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(repository.fetchCurrentUserCallCount, 1)
    }

    func test_loadProfile_failureShowsErrorMessage() async {
        let repository = MockUserRepository()
        repository.fetchCurrentUserResult = .failure(AppError.network("Connection lost"))

        let viewModel = ProfileViewModel(userRepository: repository)

        await viewModel.loadProfile()

        XCTAssertNil(viewModel.user)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Update Profile

    func test_updateProfile_sendsCorrectData() async {
        let repository = MockUserRepository()
        let originalUser = makeFixtureUser()
        repository.fetchCurrentUserResult = .success(originalUser)

        let updatedUser = makeFixtureUser(displayName: "Updated Name")
        repository.updateProfileResult = .success(updatedUser)

        let viewModel = ProfileViewModel(userRepository: repository)
        await viewModel.loadProfile()

        let newAvatarURL = URL(string: "https://example.com/new-avatar.jpg")
        await viewModel.updateProfile(displayName: "Updated Name", avatarURL: newAvatarURL)

        XCTAssertEqual(repository.updateProfileCallCount, 1)
        XCTAssertEqual(repository.lastUpdateDisplayName, "Updated Name")
        XCTAssertEqual(repository.lastUpdateAvatarURL, newAvatarURL)
        XCTAssertEqual(viewModel.user?.displayName, "Updated Name")
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_updateProfile_emptyDisplayNameShowsError() async {
        let repository = MockUserRepository()
        let viewModel = ProfileViewModel(userRepository: repository)

        await viewModel.updateProfile(displayName: "   ", avatarURL: nil)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Display name cannot be empty.")
        XCTAssertEqual(repository.updateProfileCallCount, 0)
    }

    func test_updateProfile_failureShowsErrorMessage() async {
        let repository = MockUserRepository()
        repository.updateProfileResult = .failure(AppError.network("Server unavailable"))

        let viewModel = ProfileViewModel(userRepository: repository)

        await viewModel.updateProfile(displayName: "Valid Name", avatarURL: nil)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Editing Mode

    func test_startEditing_populatesEditingFields() async {
        let repository = MockUserRepository()
        let fixtureUser = makeFixtureUser()
        repository.fetchCurrentUserResult = .success(fixtureUser)

        let viewModel = ProfileViewModel(userRepository: repository)
        await viewModel.loadProfile()

        viewModel.startEditing()

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.editingDisplayName, fixtureUser.displayName)
        XCTAssertEqual(viewModel.editingAvatarURL, fixtureUser.avatarURL?.absoluteString ?? "")
    }

    func test_cancelEditing_clearsEditingState() async {
        let repository = MockUserRepository()
        let fixtureUser = makeFixtureUser()
        repository.fetchCurrentUserResult = .success(fixtureUser)

        let viewModel = ProfileViewModel(userRepository: repository)
        await viewModel.loadProfile()

        viewModel.startEditing()
        viewModel.editingDisplayName = "Changed Name"
        viewModel.cancelEditing()

        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.editingDisplayName, "")
        XCTAssertEqual(viewModel.editingAvatarURL, "")
    }

    func test_saveEdits_callsUpdateWithEditingValues() async {
        let repository = MockUserRepository()
        let fixtureUser = makeFixtureUser()
        repository.fetchCurrentUserResult = .success(fixtureUser)

        let updatedUser = makeFixtureUser(displayName: "Edited Name")
        repository.updateProfileResult = .success(updatedUser)

        let viewModel = ProfileViewModel(userRepository: repository)
        await viewModel.loadProfile()

        viewModel.startEditing()
        viewModel.editingDisplayName = "Edited Name"
        viewModel.editingAvatarURL = ""

        await viewModel.saveEdits()

        XCTAssertEqual(repository.lastUpdateDisplayName, "Edited Name")
        XCTAssertNil(repository.lastUpdateAvatarURL)
        XCTAssertFalse(viewModel.isEditing)
    }
}
