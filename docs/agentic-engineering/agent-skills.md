# Agent Skills — Enterprise Agentic Engineering Guide

## Overview

Agent skills define the **discrete capabilities** an AI coding agent can perform
within a software project. Each skill maps to a well-scoped responsibility with
clear inputs, outputs, and quality gates. This guide defines the skill taxonomy
for the Team Task Manager project.

---

## 1. Skill Taxonomy

### 1.1 Code Generation Skills

| Skill | Description | Trigger | Inputs | Outputs |
|---|---|---|---|---|
| `scaffold-module` | Create a new Swift Package module with standard structure | New feature request | Module name, dependencies, type (Core/Feature) | Package.swift, Sources/, Tests/, README |
| `implement-model` | Generate domain model with Codable, Sendable, Equatable | Model spec | Field names, types, relationships | Model file + unit tests |
| `implement-viewmodel` | Generate ViewModel with published state and async actions | Screen spec | State shape, actions, dependencies | ViewModel + tests + preview provider |
| `implement-view` | Generate SwiftUI view bound to ViewModel | Design spec / wireframe | Layout description, ViewModel type | SwiftUI View file |
| `implement-repository` | Generate repository protocol + concrete implementation | Data access spec | Entity type, data sources | Protocol + implementation + mock + tests |
| `implement-detector` | Generate an ExceptionalSignalDetector for interaction tracking | Signal spec | Detection rules, thresholds | Detector class + unit tests with synthetic events |

### 1.2 Testing Skills

| Skill | Description | Trigger | Inputs | Outputs |
|---|---|---|---|---|
| `generate-unit-tests` | Create XCTest/Swift Testing test cases | New or changed code | Source file, expected behaviors | Test file with named test methods |
| `generate-snapshot-tests` | Create snapshot tests for UI components | New DesignSystem component | View + preview configurations | Snapshot test + reference images |
| `generate-integration-tests` | Create integration tests for data flows | Repository or service change | Flow description, mock data | Integration test file |
| `generate-ui-tests` | Create XCUITest for critical user flows | New user-facing flow | Flow steps, assertions | UI test file |

### 1.3 Quality & Maintenance Skills

| Skill | Description | Trigger | Inputs | Outputs |
|---|---|---|---|---|
| `lint-fix` | Run SwiftLint + SwiftFormat and auto-fix | Pre-commit / CI | Source files | Fixed files, violation report |
| `dependency-audit` | Check module dependency rules are respected | New import added | Module graph | Pass/fail + violation list |
| `api-review` | Review public API surface of a module | Pre-merge | Module source | API diff, breaking change warnings |
| `accessibility-audit` | Check VoiceOver labels, Dynamic Type, contrast | UI change | View files | Audit report with fix suggestions |

### 1.4 Documentation Skills

| Skill | Description | Trigger | Inputs | Outputs |
|---|---|---|---|---|
| `document-api` | Generate DocC documentation for public APIs | New public symbol | Source files | /// doc comments |
| `document-architecture` | Update architecture decision records | Architectural change | Decision context | ADR markdown file |
| `generate-changelog` | Create changelog entry from commits | Release prep | Git log range | CHANGELOG.md entry |

---

## 2. Skill Contracts

Every skill follows a standardized contract:

```yaml
skill:
  name: implement-viewmodel
  version: 1.0

  inputs:
    required:
      - name: screen_name
        type: string
        description: "PascalCase name of the screen (e.g., TaskBoard)"
      - name: state_fields
        type: array<FieldSpec>
        description: "Published state properties"
      - name: actions
        type: array<ActionSpec>
        description: "User-triggered actions the VM handles"
    optional:
      - name: dependencies
        type: array<string>
        description: "Protocol dependencies to inject"
        default: []

  outputs:
    - file: "Sources/{screen_name}/{screen_name}ViewModel.swift"
    - file: "Tests/{screen_name}ViewModelTests.swift"

  quality_gates:
    - "All generated code compiles without warnings"
    - "All generated tests pass"
    - "SwiftLint reports zero violations"
    - "ViewModel conforms to @MainActor"
    - "All dependencies are protocol types (not concrete)"

  examples:
    - input:
        screen_name: "TaskBoard"
        state_fields:
          - { name: "tasks", type: "[TaskItem]", default: "[]" }
          - { name: "isLoading", type: "Bool", default: "false" }
          - { name: "errorMessage", type: "String?", default: "nil" }
        actions:
          - { name: "loadTasks", async: true }
          - { name: "moveTask", params: ["taskId: UUID", "to: TaskStatus"] }
        dependencies: ["TaskRepository", "InteractionTracking"]
```

---

## 3. Skill Composition

Skills can be composed into higher-order workflows:

```
implement-feature = scaffold-module
                  → implement-model
                  → implement-repository
                  → implement-viewmodel
                  → implement-view
                  → generate-unit-tests
                  → generate-snapshot-tests
                  → lint-fix
                  → dependency-audit
```

The orchestration layer (see `agent-orchestration.md`) manages this sequencing.

---

## 4. Skill Discovery & Registration

### 4.1 CLAUDE.md Integration

Skills are registered in the project's `CLAUDE.md` so the agent knows what
capabilities are available:

```markdown
## Available Skills

### Code Generation
- `scaffold-module <name> --type core|feature` — Create new Swift Package module
- `implement-model <spec-file>` — Generate model from YAML spec
- `implement-viewmodel <spec-file>` — Generate ViewModel from YAML spec

### Testing
- `generate-unit-tests <source-file>` — Generate tests for a source file
- `generate-snapshot-tests <view-file>` — Generate snapshot tests

### Quality
- `lint-fix` — Auto-fix lint violations
- `dependency-audit` — Verify module dependency rules
```

### 4.2 Contextual Skill Selection

The agent selects skills based on:

1. **User intent** — What the developer asked for
2. **File context** — What files are open or recently modified
3. **Project state** — Current milestone, failing tests, pending TODOs
4. **Dependency graph** — What modules are affected

---

## 5. Skill Quality Assurance

### 5.1 Skill Testing

Every skill is validated against reference implementations:

```
specs/
├── skills/
│   ├── implement-viewmodel/
│   │   ├── input.yaml          ← Sample input
│   │   ├── expected/           ← Expected output files
│   │   └── test.sh             ← Validation script
│   ├── implement-repository/
│   │   ├── input.yaml
│   │   ├── expected/
│   │   └── test.sh
│   └── ...
```

### 5.2 Skill Metrics

Track per-skill performance:

| Metric | Target |
|---|---|
| Compilation success rate | > 95% |
| Test pass rate (generated tests) | > 90% |
| Lint violation count | 0 |
| Human edit rate (post-generation) | < 20% of lines |
| Time to generate | < 30s per skill invocation |

---

## 6. Interaction Tracking Skills

Specific skills for the interaction tracking subsystem:

| Skill | Description |
|---|---|
| `implement-detector` | Generate a new `ExceptionalSignalDetector` with configurable thresholds |
| `implement-exporter` | Generate a new `SignalExporter` backend (console, file, remote) |
| `generate-synthetic-events` | Create realistic interaction event sequences for testing detectors |
| `calibrate-detector` | Adjust detector thresholds based on test signal-to-noise ratio |
| `privacy-audit` | Verify PII scrubbing and data retention compliance in analytics code |

---

## 7. Experimentation Agent Skills

Skills for the autonomous experimentation lifecycle:

| Skill | Description |
|---|---|
| `analyze-signals` | Ingest exceptional signal window and discover UX/perf patterns |
| `generate-hypothesis` | Convert a `DiscoveredPattern` into a ranked `Hypothesis` with root cause, proposal, and expected impact |
| `design-experiment` | Create a full `Experiment` spec with variants, metrics, guardrails, and allocation strategy |
| `implement-variant` | Generate code for an experiment variant behind a feature flag |
| `run-experiment` | Start experiment: activate feature flags, begin metric collection, monitor guardrails |
| `evaluate-experiment` | Compute statistical significance, evaluate guardrails, produce evaluation report |
| `auto-integrate` | Merge winning variant, remove feature flag, update changelog, log to experiment registry |
| `rollback-experiment` | Revert variant code, disable feature flags, log negative outcome |
| `calibrate-guardrails` | Adjust guardrail thresholds based on historical experiment data and false positive rates |
| `audit-value-alignment` | Review proposed experiment for dark patterns, privacy regression, accessibility compliance |

### 7.1 Experimentation Skill Composition

```
analyze-signals
    → generate-hypothesis
        → design-experiment         ← human approval gate
            → implement-variant
                → run-experiment
                    → evaluate-experiment
                        → auto-integrate   (if all guardrails pass)
                        → rollback         (if hard guardrail violated)
                        → flag-for-review  (if soft guardrail warning)
```

### 7.2 Experimentation Skill Metrics

| Metric | Target |
|---|---|
| Pattern discovery precision | > 70% (true positives among flagged patterns) |
| Hypothesis accuracy | > 40% (experiments with positive primary metric) |
| Experiment design approval rate | > 80% (human approves on first review) |
| Guardrail coverage | 100% (every experiment has crash rate + core metric guardrails) |
| Auto-integration safety | 100% (zero auto-integrated experiments later rolled back) |
| Value alignment pass rate | 100% (no ethical violations in shipped experiments) |
