import Foundation
import Models

// MARK: - DashboardAuthGateProtocol

/// Checks whether the current user has dashboard access and determines
/// which panels they may view.
///
/// This gate is evaluated both at initial dashboard load (to decide which
/// tabs to render) and on each panel switch (to prevent deep-link bypasses).
public protocol DashboardAuthGateProtocol: Sendable {
    /// Returns the dashboard access level for the given user.
    func accessLevel(for user: User) -> DashboardAccessLevel

    /// Returns whether the user may view the specified panel.
    func canAccess(panel: DashboardPanel, user: User) -> Bool
}

// MARK: - DashboardAuthGate

/// Concrete implementation mapping `UserRole` to `DashboardAccessLevel`
/// and enforcing per-panel visibility rules.
///
/// Access matrix:
/// - **admin** -> all panels (business, appPerformance, interactionSignals, agenticWork, alerts)
/// - **member** -> business + appPerformance + alerts
/// - **viewer** -> business only
public struct DashboardAuthGate: DashboardAuthGateProtocol, Sendable {

    public init() {}

    public func accessLevel(for user: User) -> DashboardAccessLevel {
        switch user.role {
        case .admin:
            return .admin
        case .member:
            return .member
        case .viewer:
            return .viewer
        }
    }

    public func canAccess(panel: DashboardPanel, user: User) -> Bool {
        let level = accessLevel(for: user)
        return Self.allowedPanels(for: level).contains(panel)
    }

    /// Returns the set of panels accessible for a given access level.
    public static func allowedPanels(for level: DashboardAccessLevel) -> Set<DashboardPanel> {
        switch level {
        case .admin:
            return Set(DashboardPanel.allCases)
        case .member:
            return [.business, .appPerformance, .alerts]
        case .viewer:
            return [.business]
        }
    }
}
