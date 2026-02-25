# Verification & Evaluation — Enterprise Agentic Engineering Guide

## Overview

This guide defines **how to verify correctness** and **evaluate quality** of
agent-generated code, experiments, and their outcomes. Verification ensures
things work. Evaluation ensures things work *well* — for users, for the
business, and for human values.

---

## 1. Verification Layers

### 1.1 The Verification Pyramid

```
                    ┌─────────────┐
                    │   Human     │  Manual review of critical paths,
                    │   Review    │  experiment designs, ethical concerns
                    ├─────────────┤
                    │   E2E /     │  Full user flows in simulator,
                    │   UI Tests  │  experiment variant validation
                    ├─────────────┤
                    │ Integration │  Module boundaries, data flow,
                    │   Tests     │  detector → aggregator → exporter
                    ├─────────────┤
                    │   Unit      │  ViewModels, Services, Detectors,
                    │   Tests     │  Repositories, Exporters
                    ├─────────────┤
                    │   Static    │  Compiler, SwiftLint, SwiftFormat,
                    │  Analysis   │  dependency audit, schema validation
                    └─────────────┘
```

Each layer catches different classes of defects. All layers run in CI.

---

## 2. Static Verification

### 2.1 Compiler

```yaml
verification:
  compiler:
    swift_version: "5.9"
    strict_concurrency: complete     # -strict-concurrency=complete
    warnings_as_errors: true         # -warnings-as-errors (CI only)
    targets:
      - TaskManager
      - all packages under Packages/
```

### 2.2 Linting & Formatting

```yaml
verification:
  swiftlint:
    config: .swiftlint.yml
    mode: strict                     # --strict flag
    custom_rules:
      - no_force_unwrap             # Ban force unwraps
      - no_force_cast               # Ban force casts
      - required_interaction_tracking # Feature views must use .trackInteraction()

  swiftformat:
    config: .swiftformat
    mode: lint                       # --lint (check only, no modify)
```

### 2.3 Module Dependency Audit

```yaml
verification:
  dependency_audit:
    rules:
      - "Features/* must not import other Features/*"
      - "DesignSystem must not import Core/*"
      - "Core/Analytics must not import Features/*"
      - "No circular dependencies"
    enforcement: ci_blocking         # Fails the build
```

### 2.4 Specification Schema Validation

```yaml
verification:
  spec_validation:
    schemas:
      - specs/schemas/feature-spec.schema.yaml
      - specs/schemas/module-spec.schema.yaml
      - specs/schemas/component-spec.schema.yaml
      - specs/schemas/experiment-spec.schema.yaml
    check: "All YAML specs validate against their schema"
    enforcement: ci_blocking
```

---

## 3. Unit Test Verification

### 3.1 Conventions

```yaml
verification:
  unit_tests:
    framework: [XCTest, SwiftTesting]
    naming: "test_{methodUnderTest}_{scenario}_{expectedResult}"
    structure:
      - arrange: "Set up dependencies, mocks, initial state"
      - act: "Call the method under test"
      - assert: "Verify expected outcome"
    coverage:
      minimum: 80%                   # Per module
      critical_paths: 95%            # ViewModels, Detectors, Services

    mocking:
      approach: "Protocol-based mocks in TestSupport package"
      no_mocking_frameworks: true    # Hand-written mocks for transparency
```

### 3.2 Detector Unit Tests

Each `ExceptionalSignalDetector` requires specific test patterns:

```swift
// Example: RageTapDetector tests
final class RageTapDetectorTests: XCTestCase {

    // MARK: - Positive detection

    func test_rageTap_threeRapidTaps_sameRegion_detects() {
        let detector = RageTapDetector(threshold: 3, windowSeconds: 1.0)
        let events = SyntheticEvents.rapidTaps(
            count: 3,
            interval: 0.2,
            region: CGPoint(x: 100, y: 200),
            screen: "TaskBoard"
        )
        events.forEach { detector.feed($0) }

        let signals = detector.detectSignals()
        XCTAssertEqual(signals.count, 1)
        XCTAssertEqual(signals.first?.type, .rageTap)
        XCTAssertEqual(signals.first?.severity, .high)
    }

    // MARK: - Negative (should not detect)

    func test_rageTap_twoTaps_doesNotDetect() {
        // Below threshold
    }

    func test_rageTap_threeSlowTaps_doesNotDetect() {
        // Outside time window
    }

    func test_rageTap_threeRapidTaps_differentRegions_doesNotDetect() {
        // Not same area
    }

    // MARK: - Edge cases

    func test_rageTap_exactlyAtThreshold_detects() { }
    func test_rageTap_reset_clearsState() { }
    func test_rageTap_multipleRageSessions_detectsBoth() { }
}
```

### 3.3 Experiment Guardrail Tests

```swift
final class GuardrailEvaluatorTests: XCTestCase {

    func test_hardGuardrail_crashRateExceeded_returnsRollback() {
        let guardrail = Guardrail(
            metric: "crash_rate",
            operator: .lessThan,
            threshold: 0.001,
            action: .rollback
        )
        let result = MetricResult(name: "crash_rate", value: 0.005)

        let evaluation = GuardrailEvaluator.evaluate(guardrail, against: result)
        XCTAssertEqual(evaluation, .violated(.rollback))
    }

    func test_allGuardrailsPass_returnsApproved() { }
    func test_softGuardrailWarning_returnsFlagForReview() { }
    func test_valueGuardrailViolation_returnsBlockIntegration() { }
}
```

---

## 4. Integration Test Verification

### 4.1 Analytics Pipeline Integration

```swift
final class AnalyticsPipelineIntegrationTests: XCTestCase {

    func test_endToEnd_rawTap_toDetector_toAggregator_toExporter() async {
        // Arrange
        let exporter = MockSignalExporter()
        let tracker = InteractionTracker(
            detectors: [RageTapDetector()],
            aggregator: SignalAggregator(),
            exporters: [exporter]
        )

        // Act — simulate rage taps
        for i in 0..<5 {
            tracker.track(InteractionEvent(
                type: .tap,
                timestamp: Date().addingTimeInterval(Double(i) * 0.15),
                screen: "TaskBoard",
                point: CGPoint(x: 100, y: 200)
            ))
        }

        // Wait for detector cycle
        try await Task.sleep(for: .seconds(1.5))

        // Assert
        XCTAssertFalse(exporter.exportedSignals.isEmpty)
        XCTAssertEqual(exporter.exportedSignals.first?.type, .rageTap)
    }
}
```

### 4.2 Repository Integration

```swift
final class TaskRepositoryIntegrationTests: XCTestCase {

    func test_createTask_persistsToSwiftData_andSyncsToRemote() async { }
    func test_offlineCreate_queuesSync_completesWhenOnline() async { }
    func test_conflictResolution_lastWriteWins() async { }
}
```

---

## 5. UI Test Verification

### 5.1 Critical Flow Tests

```yaml
verification:
  ui_tests:
    critical_flows:
      - name: "Login → View Board → Move Task"
        steps:
          - launch app
          - enter email and password
          - tap login
          - verify board screen appears
          - long press on first task card
          - drag to "In Progress" column
          - verify task appears in new column
          - verify undo toast appears

      - name: "Create Task → Edit → Complete"
        steps:
          - navigate to project
          - tap "+" in To Do column
          - fill in task title and description
          - tap save
          - verify task appears in To Do
          - tap task to open detail
          - change status to Done
          - verify task moves to Done column

      - name: "Experiment Variant Validation"
        steps:
          - enable treatment feature flag
          - navigate to TaskBoard
          - tap column header
          - verify filter is applied
          - verify VoiceOver announces filter state
          - disable feature flag
          - verify original behavior restored
```

---

## 6. Experiment Evaluation

### 6.1 Statistical Evaluation Framework

```yaml
evaluation:
  experiments:
    statistical_method: "Frequentist (two-tailed t-test)"
    significance_level: 0.05        # p-value threshold
    power: 0.80                     # 1 - β
    minimum_detectable_effect: 0.10  # 10% relative change
    correction: "Bonferroni"         # For multiple comparisons

    sample_size_calculation:
      method: "power analysis"
      inputs:
        - baseline_conversion_rate
        - minimum_detectable_effect
        - significance_level
        - power
      output: "required sample size per variant"
```

### 6.2 Metric Evaluation Pipeline

```
Raw Interaction Data
        │
        ▼
┌─────────────────┐
│ Metric Computer  │  Aggregates raw events into metrics
│                  │  (e.g., dead_tap_rate = dead_taps / total_taps)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Segment Splitter │  Splits by experiment variant
│                  │  (control vs. treatment)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Statistical Test │  t-test, chi-squared, Mann-Whitney U
│                  │  depending on metric distribution
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Guardrail Check  │  Evaluate all guardrails
│                  │  (hard → value → soft)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Decision Engine  │  auto-integrate | flag-for-review | rollback
└─────────────────┘
```

### 6.3 Evaluation Report Format

```yaml
# Generated by the Experimentation Agent after experiment concludes
evaluation_report:
  experiment_id: "EXP-2026-003"
  experiment_name: "column-header-tap-filter"
  duration: "2026-02-10 to 2026-02-17"
  total_users: 1247
  users_per_variant:
    control: 631
    treatment_a: 616

  primary_metric:
    name: "dead_tap_rate_task_board"
    control:
      mean: 5.8
      std: 2.1
      n: 631
    treatment_a:
      mean: 1.9
      std: 1.4
      n: 616
    relative_change: "-67.2%"
    p_value: 0.0001
    confidence_interval: "[-72.1%, -62.3%]"
    significant: true
    verdict: positive

  secondary_metrics:
    - name: "filter_usage_rate"
      control: 0.12
      treatment_a: 0.38
      relative_change: "+216%"
      verdict: positive

    - name: "time_to_find_task"
      control: 8.2s
      treatment_a: 5.1s
      relative_change: "-37.8%"
      verdict: positive

  guardrail_results:
    hard:
      - { metric: "crash_rate", value: 0.0008, threshold: 0.001, status: pass }
      - { metric: "task_completion_rate", value: 0.97, threshold: 0.95, status: pass }
    value:
      - { check: "No dark patterns", status: pass, notes: "Filter is clearly visible and reversible" }
      - { check: "Accessibility", status: pass, notes: "VoiceOver announces filter state" }
    soft:
      - { metric: "session_duration", control: 12.3m, treatment: 11.8m, change: "-4.1%", status: pass }

  recommendation: auto_integrate
  confidence: high
  learnings: |
    Users strongly expect column headers to be interactive. The 67% reduction
    in dead taps confirms the hypothesis. Filter usage tripled, suggesting
    unmet demand for quick filtering. Time-to-find-task improvement indicates
    genuine workflow enhancement, not just error reduction.

  follow_up_experiments:
    - "Test multi-column filter (tap multiple headers)"
    - "Test filter persistence across sessions"
```

---

## 7. Continuous Evaluation

### 7.1 Post-Integration Monitoring

After an experiment is auto-integrated, monitoring continues:

```yaml
evaluation:
  post_integration:
    monitoring_period: 14d          # Watch for 2 weeks after merge
    metrics_tracked:
      - "dead_tap_rate_task_board"   # Should stay at treatment level
      - "crash_rate"                 # Should remain stable
      - "task_completion_rate"       # Should remain stable
      - "user_complaint_signals"     # Should not increase

    rollback_trigger:
      - "Any hard guardrail metric degrades beyond threshold"
      - "3+ user complaints mentioning the changed behavior"

    success_criteria:
      - "Metrics remain at treatment-level for full monitoring period"
      - "No rollback triggers fired"
      - "Experiment marked as 'permanently integrated'"
```

### 7.2 Agent Performance Evaluation

Evaluate the agents themselves:

| Metric | Target | Measurement |
|---|---|---|
| Code compilation rate | > 95% | % of generated code that compiles first try |
| Test generation accuracy | > 90% | % of generated tests that pass on correct code |
| Spec-to-code fidelity | > 95% | % of spec requirements reflected in code |
| Experiment hypothesis accuracy | > 40% | % of experiments with positive primary metric |
| Auto-integration safety | 100% | Zero auto-integrated experiments later rolled back |
| Guardrail false positive rate | < 10% | % of safe experiments blocked by guardrails |
| Review feedback loops | < 2 avg | Average reviewer-implementer round-trips |
| Time to feature | Decreasing | Trend of time from spec approval to integration |

### 7.3 Value Alignment Evaluation

Beyond metrics, evaluate that the system respects human values:

```yaml
evaluation:
  value_alignment:
    quarterly_review:
      - question: "Has any auto-integrated experiment made the app more addictive without being more useful?"
        evaluator: ethics_board
      - question: "Has interaction tracking expanded beyond what users consented to?"
        evaluator: privacy_officer
      - question: "Have experiments disproportionately affected any user demographic?"
        evaluator: inclusion_team
      - question: "Are guardrails still calibrated correctly for current user base?"
        evaluator: data_science_lead
      - question: "Has the experimentation agent proposed anything that a reasonable user would find objectionable?"
        evaluator: product_lead

    automated:
      - check: "No new PII fields added to InteractionEvent without privacy review"
      - check: "No experiment variant increases screen time without proportional task completion increase"
      - check: "All UI changes maintain WCAG AA accessibility rating"
      - check: "Experiment allocation is randomized, not targeted at vulnerable groups"
```

---

## 8. Verification & Evaluation Checklist

### Per-Commit
- [ ] Compiles with zero warnings
- [ ] All unit tests pass
- [ ] SwiftLint clean
- [ ] SwiftFormat clean
- [ ] Module dependency rules respected

### Per-Pull Request
- [ ] All per-commit checks pass
- [ ] Integration tests pass
- [ ] Snapshot tests pass (or diffs approved)
- [ ] New code has corresponding tests
- [ ] Spec traceability verified (code → spec → user story)
- [ ] Interaction tracking events added for new screens/actions

### Per-Milestone
- [ ] UI tests for critical flows pass
- [ ] Code coverage meets thresholds
- [ ] Accessibility audit passes
- [ ] Performance benchmarks within targets
- [ ] All specs marked complete match implementation

### Per-Experiment
- [ ] Experiment spec approved by human
- [ ] Variants compile and pass all tests
- [ ] Feature flags correctly gate variant code
- [ ] Guardrails defined for all critical metrics
- [ ] Value guardrails reviewed by appropriate stakeholders
- [ ] Statistical significance achieved before conclusion
- [ ] Post-integration monitoring active for 14 days

### Quarterly
- [ ] Agent performance metrics reviewed
- [ ] Value alignment evaluation conducted
- [ ] Guardrail thresholds recalibrated
- [ ] Experiment registry audited
- [ ] Interaction tracking privacy audit completed
