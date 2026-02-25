# Team Task Manager — Enterprise iOS App Plan

## 1. Vision

A sample iOS Team Task Manager app (think mini-Jira) designed to showcase
enterprise-grade architecture, modularity, testability, and agentic-engineering
workflows. The app lets teams create projects, manage tasks through customizable
workflows, assign work, and collaborate in real time.

---

## 2. Architecture

### 2.1 Pattern: MVVM + Coordinator

| Layer | Responsibility |
|---|---|
| **View** | SwiftUI views, purely declarative |
| **ViewModel** | Owns presentation logic, exposes `@Published` state |
| **Model** | Domain entities, plain value types |
| **Coordinator** | Navigation flows via `NavigationStack` / sheets |
| **Repository** | Abstracts data sources (remote + local) |
| **Service** | Business logic orchestration across repositories |

### 2.2 Dependency Injection

- Protocol-oriented DI using a lightweight `DependencyContainer`.
- Every module depends on **abstractions** (protocols), never concrete types
  from other modules.
- Enables easy mocking for tests and SwiftUI previews.

### 2.3 Concurrency

- Swift Concurrency (`async/await`, `Actor`) throughout.
- `@MainActor` for all ViewModels.
- Structured concurrency with `TaskGroup` for parallel network calls.

---

## 3. Module Map (Swift Packages)

The project uses a local Swift Package monorepo structure under `Packages/` for
maximum modularity. The main Xcode project (`.xcodeproj`) consumes these as
local package dependencies.

```
TaskManager/                  ← Xcode project (app target)
├── TaskManagerApp/           ← App entry point, composition root, DI setup
│
Packages/
├── Core/                     ← Shared kernel
│   ├── Models/               ← Domain entities (Task, Project, User, Comment)
│   ├── Networking/           ← HTTP client, auth interceptor, request/response
│   ├── Persistence/          ← SwiftData stack, offline cache, sync engine
│   ├── Analytics/            ← Interaction tracking, exceptional signal detection
│   ├── Experimentation/      ← Experiment engine, A/B testing, auto-integration
│   └── Common/               ← Extensions, utilities, logging, error types
│
├── Features/                 ← Feature modules (each is a standalone package)
│   ├── Auth/                 ← Login, signup, token management, biometrics
│   ├── Projects/             ← Project list, create/edit project
│   ├── TaskBoard/            ← Kanban board, task list, filtering, drag-drop
│   ├── TaskDetail/           ← Task view/edit, comments, attachments, history
│   ├── Profile/              ← User profile, settings, notification prefs
│   └── Notifications/        ← Push notification handling, in-app feed
│
├── DesignSystem/             ← Reusable UI components, colors, typography
│   ├── Components/           ← Buttons, cards, badges, avatars, empty states
│   └── Theme/                ← Color tokens, fonts, spacing, dark mode
│
└── TestSupport/              ← Shared mocks, fixtures, helpers for tests
```

### Module Dependency Rules

```
Features/* → Core/*, DesignSystem
Core/Networking → Core/Models, Core/Common
Core/Persistence → Core/Models, Core/Common
Core/Analytics → Core/Models, Core/Common, Core/Persistence
Core/Experimentation → Core/Models, Core/Common, Core/Analytics, Core/Persistence
DesignSystem → (no internal dependencies)
TestSupport → Core/Models
```

No feature module may depend on another feature module. Cross-feature
communication happens through Coordinators in the app target.

---

## 4. Feature Breakdown & Milestones

### Milestone 0 — Project Scaffolding & Agentic Setup
- [ ] Initialize Xcode project (iOS 17+, Swift 5.9+)
- [ ] Create Swift Package structure (`Packages/`)
- [ ] Set up `CLAUDE.md` with build/test/lint commands
- [ ] Add `.gitignore`, `.swiftlint.yml`, `.swiftformat`
- [ ] Add `Makefile` with common developer commands
- [ ] Create GitHub Actions CI workflow (build + test)
- [ ] Seed `TestSupport` with fixture helpers

### Milestone 1 — Core Layer
- [ ] `Models`: `User`, `Project`, `TaskItem`, `Comment`, `Attachment`, `TaskStatus` enum
- [ ] `Networking`: generic `APIClient` protocol + `URLSession` implementation,
      `AuthInterceptor`, `Endpoint` abstraction, JSON decoding pipeline
- [ ] `Persistence`: SwiftData `ModelContainer` setup, `SyncEngine` protocol
- [ ] `Analytics`: `InteractionTracker`, `ExceptionalSignalDetector`, `SignalEvent` model
- [ ] `Common`: `AppError` enum, `Logger`, `DateFormatting`, collection extensions

### Milestone 2 — Design System
- [ ] Color palette (light + dark), typography scale
- [ ] Core components: `PrimaryButton`, `TaskCard`, `AvatarView`, `StatusBadge`,
      `EmptyStateView`, `LoadingOverlay`
- [ ] SwiftUI previews for every component

### Milestone 3 — Auth Feature
- [ ] Login screen (email + password)
- [ ] Sign-up screen with form validation
- [ ] Token storage in Keychain (`KeychainService`)
- [ ] Biometric unlock (Face ID / Touch ID)
- [ ] Auth state coordinator (logged-in vs. onboarding flow)

### Milestone 4 — Projects Feature
- [ ] Project list (pull-to-refresh, empty state)
- [ ] Create / edit project sheet
- [ ] Project detail → navigates to Task Board
- [ ] Repository: remote + local cache with optimistic updates

### Milestone 5 — Task Board & Task Detail
- [ ] Kanban-style board with columns (To Do → In Progress → In Review → Done)
- [ ] Task list view (alternate layout)
- [ ] Filtering by assignee, priority, label
- [ ] Task detail: title, description (Markdown), assignee, due date, priority
- [ ] Comments thread with add/edit/delete
- [ ] File attachments (photo picker + camera)
- [ ] Activity / history log on each task

### Milestone 6 — Profile & Notifications
- [ ] User profile view & edit
- [ ] App settings (theme, notification prefs)
- [ ] Push notification registration (APNs)
- [ ] In-app notification feed
- [ ] Deep linking from notification → task detail

### Milestone 7 — Offline & Sync
- [ ] Offline queue for create/update operations
- [ ] Background sync with conflict resolution (last-write-wins or merge)
- [ ] Network reachability monitor (`NWPathMonitor`)
- [ ] Sync status indicator in UI

### Milestone 8 — User Interaction Tracking (Exceptional Signals)
- [ ] `InteractionEvent` model: event type, timestamp, screen, metadata, severity
- [ ] `InteractionTracker` service: captures and buffers raw interaction events
- [ ] Exceptional signal detectors:
  - [ ] **Rage Tap Detector** — 3+ taps within 1s on the same region
  - [ ] **Dead Tap Detector** — tap with no UI state change within 300ms
  - [ ] **Error Burst Detector** — 3+ errors within 30s for the same user flow
  - [ ] **Abandon Detector** — multi-step flow exited before completion
  - [ ] **Long Press Frustration** — press > 2s on non-long-press targets
  - [ ] **Excessive Scroll Detector** — rapid bidirectional scrolling (confusion signal)
  - [ ] **Latency Spike Detector** — UI response > 500ms after interaction
- [ ] `SignalAggregator`: deduplicates, scores severity, groups correlated signals
- [ ] `SignalPersistence`: local SwiftData store with configurable retention (default 7 days)
- [ ] `SignalExporter` protocol: pluggable backends (console, file, remote API)
  - [ ] `ConsoleSignalExporter` — debug builds, logs to unified logging
  - [ ] `FileSignalExporter` — writes JSONL to app container for diagnostics
  - [ ] `RemoteSignalExporter` — batched HTTP upload with retry + backoff
- [ ] Privacy controls: PII scrubbing, opt-out toggle, data retention policy
- [ ] SwiftUI `ViewModifier` for automatic tracking (`.trackInteraction(screen:)`)
- [ ] Developer dashboard view (debug builds only): live signal feed + heatmap
- [ ] Unit tests for each detector with synthetic event sequences
- [ ] Integration test: end-to-end from raw tap → detector → aggregator → exporter

### Milestone 9 — Experimentation Agent & Auto-Optimization
- [ ] `DiscoveredPattern` and `Hypothesis` models
- [ ] `SignalAnalyzer` protocol + implementation: pattern detection over signal windows
- [ ] `HypothesisGenerator`: converts patterns into ranked, actionable hypotheses
- [ ] `Experiment`, `Variant`, `Guardrail` models
- [ ] `ExperimentDesigner`: creates experiment specs from hypotheses with metric targets
- [ ] `ExperimentRunner`: manages variant allocation, feature flag toggling, duration tracking
- [ ] `MetricComputer`: aggregates raw interaction events into experiment metrics
- [ ] `GuardrailEvaluator`: evaluates hard, soft, and value guardrails against results
- [ ] `StatisticalEngine`: t-test / chi-squared, p-value, confidence intervals
- [ ] `AutoIntegrator`: merges winning variant code, removes feature flags, logs outcome
- [ ] `ExperimentRegistry`: persistent log of all experiments with full provenance
- [ ] Decision engine: auto-integrate | flag-for-review | rollback flow
- [ ] Post-integration monitor: 14-day watch period with rollback triggers
- [ ] Value guardrail checks: dark pattern detection, attention exploitation, privacy regression
- [ ] Debug dashboard: experiment status, live metrics, guardrail health
- [ ] Unit tests for StatisticalEngine, GuardrailEvaluator, HypothesisGenerator
- [ ] Integration test: end-to-end from signal → hypothesis → experiment → evaluation → integrate

### Milestone 10 — Polish & Advanced
- [ ] Accessibility audit (VoiceOver, Dynamic Type)
- [ ] Localization scaffolding (en, es, ja)
- [ ] Widget extension (upcoming tasks)
- [ ] App Intents / Siri Shortcuts ("Show my tasks")
- [ ] Performance profiling & optimization

---

## 5. Testing Strategy

| Level | Tool | Location | Coverage Target |
|---|---|---|---|
| **Unit** | XCTest + Swift Testing | Each package `Tests/` | ViewModels, Services, Repositories |
| **Snapshot** | swift-snapshot-testing | `Tests/Snapshot/` | DesignSystem components, key screens |
| **Integration** | XCTest | `Tests/Integration/` | API client ↔ mock server, persistence round-trips |
| **UI** | XCUITest | `TaskManagerUITests/` | Critical flows (login → create task → complete) |

### Test Conventions
- Every feature module includes its own test target.
- `TestSupport` package provides shared mocks and fixtures.
- CI runs full test suite on every push.

---

## 6. Agentic Engineering Setup

### 6.1 `CLAUDE.md`
Root-level file with:
- Build commands: `xcodebuild build -scheme TaskManager -destination 'platform=iOS Simulator,name=iPhone 16'`
- Test commands: `xcodebuild test -scheme TaskManager ...`
- Lint commands: `swiftlint lint --strict`, `swiftformat --lint .`
- Module map and dependency rules
- Code conventions (naming, architecture patterns, file organization)

### 6.2 `Makefile`
```
make build        # Build the app
make test         # Run all tests
make lint         # SwiftLint + SwiftFormat check
make format       # Auto-format code
make clean        # Clean build artifacts
make test-unit    # Unit tests only
make test-ui      # UI tests only
```

### 6.3 CI/CD (GitHub Actions)
- **PR checks**: build + test + lint on every pull request
- **Main branch**: build + test + lint + snapshot comparison

### 6.4 Code Quality
- **SwiftLint**: enforced rules for style consistency
- **SwiftFormat**: auto-formatting on save / pre-commit
- **Strict compiler warnings**: `-warnings-as-errors` in CI

---

## 7. Tech Stack Summary

| Concern | Choice |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Architecture | MVVM + Coordinator |
| Navigation | NavigationStack + Coordinator pattern |
| Networking | URLSession + async/await |
| Persistence | SwiftData |
| Auth token storage | Keychain Services |
| DI | Protocol-based container |
| Image loading | AsyncImage + disk cache |
| Linting | SwiftLint |
| Formatting | SwiftFormat |
| Testing | XCTest, Swift Testing, swift-snapshot-testing |
| CI | GitHub Actions |
| Min deployment | iOS 17.0 |
| Swift version | 5.9+ |

---

## 8. User Interaction Tracking — Architecture Deep Dive

### 8.1 Signal Pipeline

```
┌──────────────┐    ┌───────────────────┐    ┌──────────────────┐    ┌────────────────┐
│  Raw Events  │───▶│  Signal Detectors │───▶│  SignalAggregator │───▶│ SignalExporter │
│  (UI layer)  │    │  (pattern match)  │    │  (dedup + score)  │    │ (output sink)  │
└──────────────┘    └───────────────────┘    └──────────────────┘    └────────────────┘
       │                     │                        │                      │
  Touch/Scroll          Rage, Dead,              Severity score,       Console, File,
  Tap, Navigate         Abandon, etc.            correlation ID        Remote API
```

### 8.2 Core Protocols

```swift
// Every detector conforms to this
protocol ExceptionalSignalDetector {
    var signalType: SignalType { get }
    func feed(_ event: InteractionEvent)
    func detectSignals() -> [ExceptionalSignal]
    func reset()
}

// Pluggable output destination
protocol SignalExporter {
    func export(_ signals: [ExceptionalSignal]) async throws
    func flush() async throws
}

// Central tracker — injected app-wide
protocol InteractionTracking {
    func track(_ event: InteractionEvent)
    func registerDetector(_ detector: ExceptionalSignalDetector)
    func registerExporter(_ exporter: SignalExporter)
    var signalStream: AsyncStream<ExceptionalSignal> { get }
}
```

### 8.3 Event Model

```swift
struct InteractionEvent: Codable, Sendable {
    let id: UUID
    let type: InteractionType          // .tap, .scroll, .navigate, .error, .longPress
    let timestamp: Date
    let screen: String                 // e.g. "TaskBoard", "TaskDetail"
    let point: CGPoint?                // tap location (nil for non-spatial events)
    let metadata: [String: String]     // extensible key-value context
    let duration: TimeInterval?        // for long presses, scroll sessions
}

struct ExceptionalSignal: Codable, Sendable {
    let id: UUID
    let type: SignalType               // .rageTap, .deadTap, .errorBurst, etc.
    let severity: Severity             // .low, .medium, .high, .critical
    let timestamp: Date
    let screen: String
    let triggeringEvents: [UUID]       // references to raw InteractionEvents
    let correlationId: String?         // groups related signals
    let description: String            // human-readable summary
}
```

### 8.4 Privacy & Performance

- **Privacy**: All `InteractionEvent.point` coordinates are snapped to a 44×44pt
  grid (minimum tap target size) so individual UI elements cannot be fingerprinted.
  `metadata` values are scrubbed of PII via a configurable `PIIScrubber` before
  persistence. Users can opt out entirely via Settings.
- **Performance**: Events are buffered in a ring buffer (capacity: 500) on a
  background actor. Detectors run every 1s on the buffer. Exported signals are
  batched (max 50 per upload) with exponential backoff on failure. Zero
  allocations on the main thread — the SwiftUI `ViewModifier` posts events via
  `DispatchQueue.global()`.

---

## 9. Experimentation Agent — Architecture Deep Dive

### 9.1 Pipeline

```
┌──────────────┐   ┌────────────────┐   ┌────────────────┐   ┌────────────────┐
│ Interaction  │──▶│ Signal         │──▶│ Hypothesis     │──▶│ Experiment     │
│ Tracking     │   │ Analyzer       │   │ Generator      │   │ Designer       │
│ (Core/       │   │ (pattern       │   │ (root cause +  │   │ (variants,     │
│  Analytics)  │   │  detection)    │   │  proposal)     │   │  allocation,   │
└──────────────┘   └────────────────┘   └────────────────┘   │  guardrails)   │
                                                              └───────┬────────┘
                                                                      │
┌──────────────┐   ┌────────────────┐   ┌────────────────┐   ┌───────▼────────┐
│ Experiment   │◀──│ Auto-          │◀──│ Guardrail      │◀──│ Experiment     │
│ Registry     │   │ Integrator     │   │ Evaluator      │   │ Runner         │
│ (provenance  │   │ (merge or      │   │ (hard/soft/    │   │ (feature flags │
│  log)        │   │  rollback)     │   │  value gates)  │   │  + monitoring) │
└──────────────┘   └────────────────┘   └────────────────┘   └────────────────┘
```

### 9.2 Key Protocols

```swift
protocol SignalAnalyzer {
    func analyze(signals: [ExceptionalSignal], window: DateInterval) async -> [DiscoveredPattern]
}

protocol HypothesisGenerating {
    func generateHypotheses(from patterns: [DiscoveredPattern]) async -> [Hypothesis]
}

protocol ExperimentDesigning {
    func design(from hypothesis: Hypothesis) async -> Experiment
}

protocol ExperimentRunning {
    func start(_ experiment: Experiment) async throws
    func stop(_ experimentId: UUID) async throws
    var activeExperiments: [Experiment] { get }
}

protocol GuardrailEvaluating {
    func evaluate(_ experiment: Experiment, results: ExperimentResults) -> GuardrailVerdict
}

protocol AutoIntegrating {
    func integrate(_ experiment: Experiment, winningVariant: Variant) async throws
    func rollback(_ experiment: Experiment) async throws
}
```

### 9.3 Guardrail Tiers

| Tier | Examples | On Violation |
|---|---|---|
| **Hard** | Crash rate, data loss, core completion rate | Immediate rollback |
| **Value** | Dark patterns, privacy regression, accessibility | Block + ethics review |
| **Soft** | Session duration shift, engagement change | Flag for human review |

### 9.4 Auto-Integration Conditions

An experiment is auto-integrated **only** when ALL of the following hold:

1. Primary metric achieves target with p < 0.05
2. All hard guardrails pass
3. All value guardrails pass
4. No soft guardrail warnings (or warnings are human-approved)
5. Minimum sample size reached per variant
6. Minimum duration elapsed

If any condition fails, the experiment requires human review or is rolled back.

---

## 10. Implementation Order

We will implement in milestone order (M0 → M10). Each milestone produces a
working, testable increment. The agentic scaffolding (M0) comes first so that
every subsequent milestone benefits from CI, linting, and `CLAUDE.md` guidance.

Within each milestone, the order is: **models → protocols → implementations →
tests → UI → integration**.
