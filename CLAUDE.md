# Team Task Manager — Agentic Engineering Guide

## Project Overview

Enterprise iOS Team Task Manager (mini-Jira) using MVVM + Coordinator, Swift
Package monorepo, and protocol-oriented dependency injection.

## Build Commands

```bash
# Build all targets (macOS, for CI/local validation)
swift build

# Build for iOS Simulator (requires Xcode)
xcodebuild build -scheme TaskManager -destination 'platform=iOS Simulator,name=iPhone 16'

# Run all tests
swift test

# Run tests for a specific module
swift test --filter ModelsTests
swift test --filter NetworkingTests
swift test --filter AnalyticsTests

# Lint
swiftlint lint --strict
swiftformat --lint .

# Format
swiftformat .
```

## Architecture

- **Pattern**: MVVM + Coordinator
- **DI**: Protocol-based `DependencyContainer` at app root
- **Concurrency**: Swift Concurrency (`async/await`, `@MainActor` ViewModels)
- **Persistence**: SwiftData with offline queue
- **Analytics**: `InteractionTracker` → `ExceptionalSignalDetector` → `SignalExporter`

## Module Dependency Rules

```
Features/* → Core/*, DesignSystem        (features depend on core + design system)
Core/Networking → Models, Common          (networking uses models)
Core/Persistence → Models, Common         (persistence uses models)
Core/Analytics → Models, Common           (analytics uses models)
DesignSystem → Models                     (design system uses models for display)
TestSupport → Models, Common, Networking, Analytics
```

**CRITICAL**: No feature module may depend on another feature module. Cross-feature
communication happens through Coordinators in the app target.

## Module Map

| Module | Purpose |
|---|---|
| `Common` | Shared utilities, error types, logging, extensions |
| `Models` | Domain entities: User, Project, TaskItem, Comment, etc. |
| `Networking` | APIClient protocol, URLSession impl, endpoints |
| `Persistence` | SwiftData container, offline queue, sync engine |
| `Analytics` | Interaction tracking, signal detectors, exporters |
| `DesignSystem` | Reusable UI components, color tokens, typography |
| `Auth` | Login, signup, keychain, biometrics |
| `Projects` | Project CRUD, list/detail views |
| `TaskBoard` | Kanban board, task list, filtering |
| `TaskDetail` | Task view/edit, comments, attachments, activity log |
| `Profile` | User profile, app settings |
| `Notifications` | Push notifications, in-app feed, deep linking |
| `TestSupport` | Shared mocks, fixtures, test helpers |
| `TaskManagerApp` | App entry point, composition root, coordinators |

## Conventions

- **Naming**: PascalCase types, camelCase properties/methods
- **ViewModels**: `@MainActor`, `@Observable`, protocol dependencies
- **Views**: SwiftUI, bind to ViewModel via `@State` or `@Environment`
- **Repositories**: Protocol + concrete impl, always async
- **Tests**: `test_{method}_{scenario}_{expected}` naming
- **Interaction Tracking**: Every feature screen must use `.trackInteraction(screen:)`
  modifier. All user actions that change state should emit `InteractionEvent`s.
  This data feeds the Experimentation Agent (M9) for autonomous optimization.

## Experimentation Readiness

All feature code must be designed for experimentation:

1. **Feature flags**: Key UI behaviors should be toggleable via `FeatureFlags`
2. **Metric emission**: User actions emit `InteractionEvent` with typed metadata
3. **Signal detection**: Screens attach `.trackInteraction(screen:)` for automatic
   rage tap, dead tap, and abandon detection
4. **Variant isolation**: UI components should accept configuration parameters
   that can be varied in experiments
