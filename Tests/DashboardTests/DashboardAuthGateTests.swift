import Testing
import Foundation
@testable import Dashboard
@testable import Models

// MARK: - Test Helpers

private func makeUser(role: UserRole) -> User {
    User(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        email: "test@example.com",
        displayName: "Test User",
        role: role
    )
}

// MARK: - Tests

@Suite("DashboardAuthGate Tests")
struct DashboardAuthGateTests {

    let authGate = DashboardAuthGate()

    // MARK: - Access Level Mapping

    @Test("Admin user maps to admin access level")
    func adminUserMapsToAdmin() {
        let user = makeUser(role: .admin)
        let level = authGate.accessLevel(for: user)
        #expect(level == .admin)
    }

    @Test("Member user maps to member access level")
    func memberUserMapsToMember() {
        let user = makeUser(role: .member)
        let level = authGate.accessLevel(for: user)
        #expect(level == .member)
    }

    @Test("Viewer user maps to viewer access level")
    func viewerUserMapsToViewer() {
        let user = makeUser(role: .viewer)
        let level = authGate.accessLevel(for: user)
        #expect(level == .viewer)
    }

    // MARK: - Admin Panel Access

    @Test("Admin can access all panels")
    func adminCanAccessAllPanels() {
        let user = makeUser(role: .admin)
        for panel in DashboardPanel.allCases {
            #expect(authGate.canAccess(panel: panel, user: user),
                    "Admin should access \(panel.rawValue)")
        }
    }

    @Test("Admin allowed panels include every panel")
    func adminAllowedPanelsComplete() {
        let allowed = DashboardAuthGate.allowedPanels(for: .admin)
        #expect(allowed == Set(DashboardPanel.allCases))
    }

    // MARK: - Member Panel Access

    @Test("Member can access business panel")
    func memberCanAccessBusiness() {
        let user = makeUser(role: .member)
        #expect(authGate.canAccess(panel: .business, user: user))
    }

    @Test("Member can access appPerformance panel")
    func memberCanAccessAppPerformance() {
        let user = makeUser(role: .member)
        #expect(authGate.canAccess(panel: .appPerformance, user: user))
    }

    @Test("Member can access alerts panel")
    func memberCanAccessAlerts() {
        let user = makeUser(role: .member)
        #expect(authGate.canAccess(panel: .alerts, user: user))
    }

    @Test("Member cannot access interactionSignals panel")
    func memberCannotAccessInteractionSignals() {
        let user = makeUser(role: .member)
        #expect(!authGate.canAccess(panel: .interactionSignals, user: user))
    }

    @Test("Member cannot access agenticWork panel")
    func memberCannotAccessAgenticWork() {
        let user = makeUser(role: .member)
        #expect(!authGate.canAccess(panel: .agenticWork, user: user))
    }

    @Test("Member allowed panels are business, appPerformance, and alerts")
    func memberAllowedPanelsCorrect() {
        let allowed = DashboardAuthGate.allowedPanels(for: .member)
        #expect(allowed == [.business, .appPerformance, .alerts])
    }

    // MARK: - Viewer Panel Access

    @Test("Viewer can access business panel")
    func viewerCanAccessBusiness() {
        let user = makeUser(role: .viewer)
        #expect(authGate.canAccess(panel: .business, user: user))
    }

    @Test("Viewer cannot access appPerformance panel")
    func viewerCannotAccessAppPerformance() {
        let user = makeUser(role: .viewer)
        #expect(!authGate.canAccess(panel: .appPerformance, user: user))
    }

    @Test("Viewer cannot access interactionSignals panel")
    func viewerCannotAccessInteractionSignals() {
        let user = makeUser(role: .viewer)
        #expect(!authGate.canAccess(panel: .interactionSignals, user: user))
    }

    @Test("Viewer cannot access agenticWork panel")
    func viewerCannotAccessAgenticWork() {
        let user = makeUser(role: .viewer)
        #expect(!authGate.canAccess(panel: .agenticWork, user: user))
    }

    @Test("Viewer cannot access alerts panel")
    func viewerCannotAccessAlerts() {
        let user = makeUser(role: .viewer)
        #expect(!authGate.canAccess(panel: .alerts, user: user))
    }

    @Test("Viewer allowed panels are business only")
    func viewerAllowedPanelsCorrect() {
        let allowed = DashboardAuthGate.allowedPanels(for: .viewer)
        #expect(allowed == [.business])
    }

    // MARK: - Each Panel Checked Across Roles

    @Test("Business panel accessible to all roles")
    func businessPanelAccessibleToAll() {
        for role in UserRole.allCases {
            let user = makeUser(role: role)
            #expect(authGate.canAccess(panel: .business, user: user),
                    "\(role.rawValue) should access business panel")
        }
    }

    @Test("AppPerformance panel accessible to admin and member only")
    func appPerformancePanelAccessControl() {
        let admin = makeUser(role: .admin)
        let member = makeUser(role: .member)
        let viewer = makeUser(role: .viewer)

        #expect(authGate.canAccess(panel: .appPerformance, user: admin))
        #expect(authGate.canAccess(panel: .appPerformance, user: member))
        #expect(!authGate.canAccess(panel: .appPerformance, user: viewer))
    }

    @Test("InteractionSignals panel accessible to admin only")
    func interactionSignalsPanelAccessControl() {
        let admin = makeUser(role: .admin)
        let member = makeUser(role: .member)
        let viewer = makeUser(role: .viewer)

        #expect(authGate.canAccess(panel: .interactionSignals, user: admin))
        #expect(!authGate.canAccess(panel: .interactionSignals, user: member))
        #expect(!authGate.canAccess(panel: .interactionSignals, user: viewer))
    }

    @Test("AgenticWork panel accessible to admin only")
    func agenticWorkPanelAccessControl() {
        let admin = makeUser(role: .admin)
        let member = makeUser(role: .member)
        let viewer = makeUser(role: .viewer)

        #expect(authGate.canAccess(panel: .agenticWork, user: admin))
        #expect(!authGate.canAccess(panel: .agenticWork, user: member))
        #expect(!authGate.canAccess(panel: .agenticWork, user: viewer))
    }

    @Test("Alerts panel accessible to admin and member only")
    func alertsPanelAccessControl() {
        let admin = makeUser(role: .admin)
        let member = makeUser(role: .member)
        let viewer = makeUser(role: .viewer)

        #expect(authGate.canAccess(panel: .alerts, user: admin))
        #expect(authGate.canAccess(panel: .alerts, user: member))
        #expect(!authGate.canAccess(panel: .alerts, user: viewer))
    }
}
