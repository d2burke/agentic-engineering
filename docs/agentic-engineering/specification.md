# Specification — Enterprise Agentic Engineering Guide

## Overview

This guide defines **how to write specifications** that AI agents can consume,
validate, and implement with high fidelity. Specifications are the primary
interface between human intent and agent execution. A well-written spec
eliminates ambiguity and enables autonomous, verifiable work.

---

## 1. Specification Hierarchy

```
Product Vision (human-authored, high-level)
    │
    ▼
Feature Spec (human + agent co-authored)
    │
    ▼
Module Spec (agent-generated, human-reviewed)
    │
    ▼
Component Spec (agent-generated, auto-validated)
    │
    ▼
Test Spec (agent-generated from component spec)
```

Each level adds implementation detail while maintaining traceability to the
level above.

---

## 2. Feature Specification Format

### 2.1 Template

```yaml
# specs/features/{feature-name}.yaml
feature:
  name: "Task Board"
  id: "F-005"
  milestone: "M5"
  owner: "team-task-manager"
  status: draft | approved | in-progress | complete

  description: |
    A Kanban-style board that displays project tasks organized by status
    columns. Users can view, filter, and drag tasks between columns to
    update their status.

  user_stories:
    - id: "US-005-01"
      as: "team member"
      i_want: "to see all tasks in my project organized by status"
      so_that: "I can understand project progress at a glance"
      acceptance_criteria:
        - "Tasks are displayed in columns: To Do, In Progress, In Review, Done"
        - "Each task card shows title, assignee avatar, priority badge, due date"
        - "Columns show task count in header"
        - "Empty columns show an empty state message"

    - id: "US-005-02"
      as: "team member"
      i_want: "to move a task to a different status by dragging it"
      so_that: "I can update task progress quickly"
      acceptance_criteria:
        - "Drag gesture initiates from long press on task card"
        - "Drop zones highlight when dragging over valid columns"
        - "Status update is persisted immediately (optimistic update)"
        - "Interaction tracker records drag-drop events"
        - "Undo toast appears for 5 seconds after move"

    - id: "US-005-03"
      as: "team member"
      i_want: "to filter tasks by assignee, priority, or label"
      so_that: "I can focus on relevant work"
      acceptance_criteria:
        - "Filter bar appears below navigation title"
        - "Multiple filters can be combined (AND logic)"
        - "Active filter count shown as badge"
        - "Clearing filters restores full board view"

  dependencies:
    modules: [Core/Models, Core/Networking, Core/Persistence, Core/Analytics]
    features: [Auth]    # Must be logged in

  interaction_tracking:
    tracked_events:
      - event: "board_view"
        type: navigate
        screen: "TaskBoard"
      - event: "task_drag"
        type: gesture
        screen: "TaskBoard"
        metadata: ["from_status", "to_status", "duration_ms"]
      - event: "filter_applied"
        type: tap
        screen: "TaskBoard"
        metadata: ["filter_type", "filter_value"]
    exceptional_signals:
      - "Rage taps on task cards (possible unresponsive drag initiation)"
      - "Dead taps on column headers (may expect tap-to-filter)"
      - "Excessive scrolling within single column (too many tasks?)"
      - "Abandon: enters board → leaves within 3s without interaction"

  non_functional:
    performance:
      - "Board renders within 300ms for up to 200 tasks"
      - "Drag animation runs at 60fps"
      - "Filter application < 100ms"
    accessibility:
      - "All task cards have VoiceOver labels: '{title}, {status}, assigned to {name}'"
      - "Drag-drop has keyboard alternative (move menu)"
      - "Minimum tap target 44×44pt"
    privacy:
      - "Task content is never included in interaction tracking metadata"
      - "Only status enum values are tracked, not custom labels"

  experiments:
    potential:
      - name: "column-header-tap-filter"
        hypothesis: "Making column headers tappable to filter reduces dead taps"
        primary_metric: "dead_tap_rate_task_board"
      - name: "task-card-swipe-actions"
        hypothesis: "Swipe actions on task cards reduce navigation depth"
        primary_metric: "task_status_change_time"
```

### 2.2 Feature Spec Checklist

- [ ] All user stories have testable acceptance criteria
- [ ] Dependencies are listed (modules and features)
- [ ] Interaction tracking events are defined for key user actions
- [ ] Exceptional signals are anticipated
- [ ] Non-functional requirements cover performance, accessibility, privacy
- [ ] Potential experiments are identified for future optimization

---

## 3. Module Specification Format

### 3.1 Template

```yaml
# specs/modules/{module-name}.yaml
module:
  name: "Core/Analytics"
  package: "Analytics"
  path: "Packages/Core/Analytics"

  purpose: |
    Provides user interaction tracking, exceptional signal detection, and
    a pluggable export pipeline. Consumed by all feature modules via the
    `.trackInteraction(screen:)` SwiftUI ViewModifier.

  public_api:
    protocols:
      - name: InteractionTracking
        methods:
          - "func track(_ event: InteractionEvent)"
          - "func registerDetector(_ detector: ExceptionalSignalDetector)"
          - "func registerExporter(_ exporter: SignalExporter)"
          - "var signalStream: AsyncStream<ExceptionalSignal> { get }"

      - name: ExceptionalSignalDetector
        methods:
          - "var signalType: SignalType { get }"
          - "func feed(_ event: InteractionEvent)"
          - "func detectSignals() -> [ExceptionalSignal]"
          - "func reset()"

      - name: SignalExporter
        methods:
          - "func export(_ signals: [ExceptionalSignal]) async throws"
          - "func flush() async throws"

    structs:
      - name: InteractionEvent
        fields:
          - { name: id, type: UUID }
          - { name: type, type: InteractionType }
          - { name: timestamp, type: Date }
          - { name: screen, type: String }
          - { name: point, type: "CGPoint?" }
          - { name: metadata, type: "[String: String]" }
          - { name: duration, type: "TimeInterval?" }

      - name: ExceptionalSignal
        fields:
          - { name: id, type: UUID }
          - { name: type, type: SignalType }
          - { name: severity, type: Severity }
          - { name: timestamp, type: Date }
          - { name: screen, type: String }
          - { name: triggeringEvents, type: "[UUID]" }
          - { name: correlationId, type: "String?" }
          - { name: description, type: String }

    enums:
      - name: InteractionType
        cases: [tap, scroll, navigate, error, longPress, drag, swipe]
      - name: SignalType
        cases: [rageTap, deadTap, errorBurst, abandon, longPressFrustration,
                excessiveScroll, latencySpike]
      - name: Severity
        cases: [low, medium, high, critical]

  dependencies:
    internal: [Core/Models, Core/Common, Core/Persistence]
    external: []

  constraints:
    - "Zero main-thread allocations in event tracking path"
    - "Ring buffer capacity: 500 events"
    - "Detector evaluation cadence: every 1 second"
    - "Export batch size: max 50 signals"
    - "All coordinates snapped to 44×44pt grid for privacy"
    - "PII scrubber runs before any persistence or export"

  testing:
    unit:
      - "Each detector tested with synthetic event sequences"
      - "PIIScrubber tested with known PII patterns"
      - "Ring buffer tested at capacity boundary"
    integration:
      - "End-to-end: raw event → detector → aggregator → exporter"
      - "SwiftData round-trip for signal persistence"
```

---

## 4. Component Specification Format

### 4.1 ViewModel Spec

```yaml
# specs/components/task-board-viewmodel.yaml
component:
  type: viewmodel
  name: TaskBoardViewModel
  module: Features/TaskBoard

  state:
    - { name: columns, type: "[BoardColumn]", default: "[]" }
    - { name: tasks, type: "[TaskItem]", default: "[]" }
    - { name: activeFilters, type: "Set<TaskFilter>", default: "[]" }
    - { name: isLoading, type: Bool, default: "false" }
    - { name: errorMessage, type: "String?", default: "nil" }
    - { name: dragState, type: "DragState?", default: "nil" }

  actions:
    - name: loadBoard
      async: true
      description: "Fetch tasks for the current project, group by status"
      side_effects: ["updates columns", "updates tasks", "tracks board_view event"]

    - name: moveTask
      params: ["taskId: UUID", "toStatus: TaskStatus"]
      async: true
      description: "Move task to new status column (optimistic update)"
      side_effects: ["reorders tasks", "persists change", "shows undo toast",
                     "tracks task_drag event"]

    - name: applyFilter
      params: ["filter: TaskFilter"]
      description: "Add filter, recompute visible tasks"
      side_effects: ["updates activeFilters", "tracks filter_applied event"]

    - name: clearFilters
      description: "Remove all filters"
      side_effects: ["clears activeFilters"]

  dependencies:
    - { protocol: TaskRepository, purpose: "CRUD for tasks" }
    - { protocol: InteractionTracking, purpose: "Event tracking" }

  interaction_tracking:
    screen_name: "TaskBoard"
    auto_track: true     # Uses .trackInteraction(screen:) modifier
```

### 4.2 View Spec

```yaml
# specs/components/task-board-view.yaml
component:
  type: view
  name: TaskBoardView
  module: Features/TaskBoard

  layout:
    - NavigationStack
      - VStack
        - FilterBar (horizontal scroll, chip-style filters)
        - ScrollView(.horizontal)
          - LazyHStack
            - ForEach column in columns:
              - BoardColumnView
                - Column header (title + count badge)
                - LazyVStack
                  - ForEach task in column.tasks:
                    - TaskCardView (draggable)

  bindings:
    viewmodel: TaskBoardViewModel
    navigation:
      - "Tap task card → push TaskDetailView"
      - "Tap '+' in column → sheet CreateTaskView (pre-filled status)"

  design_system_components:
    - TaskCard
    - StatusBadge
    - AvatarView
    - EmptyStateView (per column)
    - LoadingOverlay

  accessibility:
    - "Board announced as 'Task board with {n} columns'"
    - "Each column announced as '{status} column, {n} tasks'"
    - "Drag alternative: context menu with 'Move to...' options"
```

---

## 5. Experiment Specification Format

```yaml
# specs/experiments/{experiment-name}.yaml
experiment:
  name: "column-header-tap-filter"
  id: "EXP-2026-003"
  status: proposed | approved | running | evaluating | concluded
  hypothesis_id: "HYP-2026-007"

  hypothesis:
    observation: "42 dead taps on TaskBoard column headers in past 7 days"
    root_cause: "Users expect column headers to be interactive"
    proposal: "Make column headers tappable to toggle filter by that status"
    confidence: 0.75

  variants:
    - id: control
      description: "Current behavior — column headers are static labels"
      changes: []

    - id: treatment_a
      description: "Tapping column header filters board to that status only"
      changes:
        - file: "Features/TaskBoard/Views/BoardColumnHeaderView.swift"
          type: modify
          description: "Add onTapGesture that calls viewModel.toggleColumnFilter"
        - file: "Features/TaskBoard/ViewModels/TaskBoardViewModel.swift"
          type: modify
          description: "Add toggleColumnFilter(status:) action"

  metrics:
    primary:
      name: "dead_tap_rate_task_board"
      baseline: 6.0            # per user per day
      target: 2.0              # 67% reduction
      significance: 0.05       # p-value threshold
    secondary:
      - name: "filter_usage_rate"
        expected: increase
      - name: "time_to_find_task"
        expected: decrease

  guardrails:
    hard:
      - { metric: "crash_rate", operator: "<=", threshold: 0.001 }
      - { metric: "task_completion_rate", operator: ">=", threshold: 0.95 }
    soft:
      - { metric: "session_duration", operator: "within", threshold: "±15%" }
    value:
      - "No dark patterns: filter is clearly visible and reversible"
      - "Accessibility: filter state announced to VoiceOver"

  allocation:
    strategy: percentage
    split: { control: 50, treatment_a: 50 }
    min_sample: 500            # users per variant

  duration:
    minimum: 7d
    maximum: 21d

  auto_integrate:
    enabled: true
    conditions:
      - "primary metric achieves target with p < 0.05"
      - "all hard guardrails pass"
      - "all value guardrails pass"
      - "no soft guardrail warnings"
```

---

## 6. Specification Validation Rules

### 6.1 Automated Checks

| Rule | Scope | Check |
|---|---|---|
| Schema validity | All specs | YAML conforms to spec schema |
| ID uniqueness | All specs | No duplicate IDs across specs |
| Dependency existence | Feature, Module | Referenced modules/features exist |
| Acceptance criteria testability | Feature | Each AC maps to at least one test |
| API consistency | Module | Public API matches implementation |
| Interaction events defined | Feature | All screens have tracking events |
| Experiment metric existence | Experiment | Primary metric is tracked in analytics |
| Guardrail completeness | Experiment | Hard guardrails cover crash rate + core metrics |

### 6.2 Human Review Checks

| Check | Reviewer |
|---|---|
| Business value alignment | Product owner |
| UX coherence | Design lead |
| Privacy compliance | Privacy officer |
| Ethical guardrails | Ethics review board |
| Experiment design validity | Data science lead |

---

## 7. Specification-Driven Development Workflow

```
1. Human writes Feature Spec (high-level user stories)
        │
        ▼
2. Planner Agent generates Module Specs from Feature Spec
        │
        ▼
3. Human reviews & approves Module Specs
        │
        ▼
4. Implementer Agent generates Component Specs from Module Specs
        │
        ▼
5. Tester Agent generates Test Specs from Component Specs
        │
        ▼
6. Implementer Agent writes code from Component Specs
        │
        ▼
7. Tester Agent validates code against Test Specs
        │
        ▼
8. Reviewer Agent validates code against Module + Feature Specs
        │
        ▼
9. Experimenter Agent generates Experiment Specs from interaction data
        │
        ▼
10. Cycle repeats with refinements
```

Every artifact is traceable: `Feature Spec → Module Spec → Component Spec →
Code → Tests → Experiment`. No code exists without a spec. No spec exists
without a user story. No experiment exists without observed data.
