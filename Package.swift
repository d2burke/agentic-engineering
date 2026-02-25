// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TaskManager",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // MARK: - Core Libraries
        .library(name: "Common", targets: ["Common"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Analytics", targets: ["Analytics"]),

        // MARK: - Design System
        .library(name: "DesignSystem", targets: ["DesignSystem"]),

        // MARK: - Features
        .library(name: "Auth", targets: ["Auth"]),
        .library(name: "Projects", targets: ["Projects"]),
        .library(name: "TaskBoard", targets: ["TaskBoard"]),
        .library(name: "TaskDetail", targets: ["TaskDetail"]),
        .library(name: "Profile", targets: ["Profile"]),
        .library(name: "Notifications", targets: ["Notifications"]),
        .library(name: "Dashboard", targets: ["Dashboard"]),

        // MARK: - App
        .library(name: "TaskManagerApp", targets: ["TaskManagerApp"]),

        // MARK: - Test Support
        .library(name: "TestSupport", targets: ["TestSupport"]),
    ],
    targets: [
        // MARK: - Core Targets

        .target(name: "Common"),

        .target(
            name: "Models",
            dependencies: ["Common"]
        ),

        .target(
            name: "Networking",
            dependencies: ["Models", "Common"]
        ),

        .target(
            name: "Persistence",
            dependencies: ["Models", "Common"]
        ),

        .target(
            name: "Analytics",
            dependencies: ["Models", "Common"]
        ),

        // MARK: - Design System

        .target(
            name: "DesignSystem",
            dependencies: ["Models"]
        ),

        // MARK: - Feature Targets

        .target(
            name: "Auth",
            dependencies: ["Models", "Common", "Networking", "DesignSystem", "Analytics"]
        ),

        .target(
            name: "Projects",
            dependencies: ["Models", "Common", "Networking", "Persistence", "DesignSystem", "Analytics"]
        ),

        .target(
            name: "TaskBoard",
            dependencies: ["Models", "Common", "Networking", "Persistence", "DesignSystem", "Analytics"]
        ),

        .target(
            name: "TaskDetail",
            dependencies: ["Models", "Common", "Networking", "Persistence", "DesignSystem", "Analytics"]
        ),

        .target(
            name: "Profile",
            dependencies: ["Models", "Common", "Networking", "Persistence", "DesignSystem", "Analytics"]
        ),

        .target(
            name: "Notifications",
            dependencies: ["Models", "Common", "Networking", "DesignSystem", "Analytics"]
        ),

        .target(
            name: "Dashboard",
            dependencies: ["Models", "Common", "Networking", "Persistence", "DesignSystem", "Analytics"]
        ),

        // MARK: - App Target

        .target(
            name: "TaskManagerApp",
            dependencies: [
                "Common", "Models", "Networking", "Persistence", "Analytics",
                "DesignSystem", "Auth", "Projects", "TaskBoard", "TaskDetail",
                "Profile", "Notifications", "Dashboard",
            ]
        ),

        // MARK: - Test Support

        .target(
            name: "TestSupport",
            dependencies: ["Models", "Common", "Networking", "Analytics"]
        ),

        // MARK: - Test Targets

        .testTarget(name: "CommonTests", dependencies: ["Common"]),
        .testTarget(name: "ModelsTests", dependencies: ["Models", "TestSupport"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking", "Models", "Common", "TestSupport"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Models", "Common", "TestSupport"]),
        .testTarget(name: "AnalyticsTests", dependencies: ["Analytics", "Models", "Common", "TestSupport"]),
        .testTarget(name: "AuthTests", dependencies: ["Auth", "Models", "Common", "TestSupport"]),
        .testTarget(name: "ProjectsTests", dependencies: ["Projects", "Models", "Common", "TestSupport"]),
        .testTarget(name: "TaskBoardTests", dependencies: ["TaskBoard", "Models", "Common", "TestSupport"]),
        .testTarget(name: "TaskDetailTests", dependencies: ["TaskDetail", "Models", "Common", "TestSupport"]),
        .testTarget(name: "ProfileTests", dependencies: ["Profile", "Models", "Common", "TestSupport"]),
        .testTarget(name: "NotificationsTests", dependencies: ["Notifications", "Models", "Common", "Analytics", "TestSupport"]),
        .testTarget(name: "DashboardTests", dependencies: ["Dashboard", "Models", "Common", "Analytics", "TestSupport"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem", "Models"]),
    ]
)
