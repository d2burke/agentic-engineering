import Foundation
import Analytics
import Models

// MARK: - DashboardDataServiceProtocol

/// Contract for fetching all dashboard data sections.
///
/// Implementations may hit a live API, read from a local cache, or
/// generate mock data. The Experimentation Agent in M9 will depend
/// on the same protocol for autonomous signal consumption.
public protocol DashboardDataServiceProtocol: Sendable {
    /// Fetches aggregated business metrics for the given time range.
    func fetchBusinessMetrics(timeRange: DashboardTimeRange) async throws -> BusinessMetrics

    /// Fetches application performance metrics for the given time range.
    func fetchAppPerformance(timeRange: DashboardTimeRange) async throws -> AppPerformanceMetrics

    /// Fetches interaction signal metrics for the given time range.
    func fetchInteractionSignals(timeRange: DashboardTimeRange) async throws -> InteractionSignalMetrics

    /// Fetches agentic work metrics for the given time range.
    func fetchAgenticWork(timeRange: DashboardTimeRange) async throws -> AgenticWorkMetrics

    /// Fetches active dashboard alerts.
    func fetchAlerts() async throws -> [DashboardAlert]

    /// Acknowledges (dismisses) a specific alert.
    func acknowledgeAlert(id: UUID) async throws
}

// MARK: - MockDashboardDataService

/// A mock implementation that generates rich, realistic sample data
/// for development and demo purposes.
///
/// Uses deterministic seeds derived from the time range so the
/// dashboard looks consistent during demos while still varying
/// across range selections.
public final class MockDashboardDataService: DashboardDataServiceProtocol, @unchecked Sendable {

    // MARK: - State

    /// Tracks acknowledged alert IDs across calls.
    private var acknowledgedAlertIds: Set<UUID> = []
    private let lock = NSLock()

    /// Optional simulated latency for testing loading states.
    public var simulatedLatency: UInt64

    /// Optional error to throw for testing error states.
    public var stubbedError: Error?

    // MARK: - Deterministic IDs

    /// Fixed UUIDs for reproducible data across invocations.
    private enum IDs {
        static let alert1 = UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!
        static let alert2 = UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!
        static let alert3 = UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!
        static let experiment1 = UUID(uuidString: "E0000000-0000-0000-0000-000000000001")!
        static let experiment2 = UUID(uuidString: "E0000000-0000-0000-0000-000000000002")!
        static let experiment3 = UUID(uuidString: "E0000000-0000-0000-0000-000000000003")!
        static let experiment4 = UUID(uuidString: "E0000000-0000-0000-0000-000000000004")!
        static let experiment5 = UUID(uuidString: "E0000000-0000-0000-0000-000000000005")!
    }

    // MARK: - Init

    /// Creates a mock data service.
    ///
    /// - Parameter simulatedLatency: Nanoseconds of artificial delay.
    ///   Defaults to 200ms for realistic loading indicator behavior.
    public init(simulatedLatency: UInt64 = 200_000_000) {
        self.simulatedLatency = simulatedLatency
    }

    // MARK: - Protocol Conformance

    public func fetchBusinessMetrics(timeRange: DashboardTimeRange) async throws -> BusinessMetrics {
        try throwIfStubbed()
        try await simulateDelay()

        let calendar = Calendar.current
        let now = Date()
        let dayCount = daysForRange(timeRange)

        // Growth trend: realistic DAU with weekday/weekend seasonality
        let growthTrend: [TimeSeriesPoint] = (0..<dayCount).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(dayCount - 1 - dayOffset), to: now)!
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let base: Double = 1250
            let noise = Double(dayOffset % 7) * 15.0
            let seasonality: Double = isWeekend ? -200 : 0
            let growth = Double(dayOffset) * 8.0
            return TimeSeriesPoint(date: date, value: base + noise + seasonality + growth)
        }

        let activeUsers = ActiveUserMetrics(
            dau: 1_342,
            wau: 4_891,
            mau: 12_450,
            growthTrend: growthTrend
        )

        let projectMetrics = ProjectMetrics(
            totalProjects: 87,
            activeProjects: 34,
            createdThisPeriod: dayCount > 7 ? 12 : 3
        )

        // Throughput trend: tasks completed per day
        let throughputTrend: [TimeSeriesPoint] = (0..<dayCount).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(dayCount - 1 - dayOffset), to: now)!
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let base: Double = isWeekend ? 5 : 18
            let variance = Double((dayOffset * 7 + 3) % 11) - 5.0
            return TimeSeriesPoint(date: date, value: max(1, base + variance))
        }

        let taskMetrics = TaskMetrics(
            totalTasks: 1_456,
            completedThisPeriod: dayCount > 7 ? 234 : 42,
            completionRate: 0.73,
            averageCompletionTime: 172_800, // 2 days in seconds
            statusDistribution: [
                TaskStatus.todo.rawValue: 312,
                TaskStatus.inProgress.rawValue: 198,
                TaskStatus.inReview.rawValue: 87,
                TaskStatus.done.rawValue: 789,
                TaskStatus.archived.rawValue: 70
            ],
            priorityDistribution: [
                TaskPriority.low.rawValue: 342,
                TaskPriority.medium.rawValue: 567,
                TaskPriority.high.rawValue: 398,
                TaskPriority.critical.rawValue: 149
            ],
            throughputTrend: throughputTrend
        )

        let teamVelocity: [VelocityDataPoint] = (0..<7).map { weekIndex in
            let date = calendar.date(byAdding: .weekOfYear, value: -(6 - weekIndex), to: now)!
            let completed = 28 + (weekIndex * 3) + ((weekIndex * 5) % 7)
            let created = 32 + (weekIndex * 2) + ((weekIndex * 3) % 5)
            return VelocityDataPoint(
                periodLabel: "Week \(weekIndex + 1)",
                tasksCompleted: completed,
                tasksCreated: created,
                date: date
            )
        }

        let topContributors: [ContributorStats] = [
            ContributorStats(
                userId: UUID(uuidString: "C0000000-0000-0000-0000-000000000001")!,
                displayName: "Alice Chen",
                tasksCompleted: 47,
                tasksCreated: 23,
                commentsAdded: 112
            ),
            ContributorStats(
                userId: UUID(uuidString: "C0000000-0000-0000-0000-000000000002")!,
                displayName: "Bob Martinez",
                tasksCompleted: 39,
                tasksCreated: 31,
                commentsAdded: 89
            ),
            ContributorStats(
                userId: UUID(uuidString: "C0000000-0000-0000-0000-000000000003")!,
                displayName: "Carol Davis",
                tasksCompleted: 35,
                tasksCreated: 18,
                commentsAdded: 76
            ),
            ContributorStats(
                userId: UUID(uuidString: "C0000000-0000-0000-0000-000000000004")!,
                displayName: "David Kim",
                tasksCompleted: 28,
                tasksCreated: 42,
                commentsAdded: 54
            ),
            ContributorStats(
                userId: UUID(uuidString: "C0000000-0000-0000-0000-000000000005")!,
                displayName: "Eva Johansson",
                tasksCompleted: 24,
                tasksCreated: 15,
                commentsAdded: 98
            ),
            ContributorStats(
                userId: UUID(uuidString: "C0000000-0000-0000-0000-000000000006")!,
                displayName: "Frank Okafor",
                tasksCompleted: 21,
                tasksCreated: 27,
                commentsAdded: 43
            ),
        ]

        return BusinessMetrics(
            activeUsers: activeUsers,
            projectMetrics: projectMetrics,
            taskMetrics: taskMetrics,
            teamVelocity: teamVelocity,
            topContributors: topContributors
        )
    }

    public func fetchAppPerformance(timeRange: DashboardTimeRange) async throws -> AppPerformanceMetrics {
        try throwIfStubbed()
        try await simulateDelay()

        let calendar = Calendar.current
        let now = Date()
        let dayCount = daysForRange(timeRange)

        let launchTime = LatencyMetric(p50: 320, p95: 780, p99: 1_450)

        let screens = ["TaskBoard", "TaskDetail", "ProjectList", "ProjectDetail",
                       "Profile", "Settings", "NotificationFeed", "CreateTask"]
        let screenLoadTimes: [ScreenPerformance] = screens.enumerated().map { index, name in
            let baseP50: Double = 120 + Double(index) * 35
            return ScreenPerformance(
                screenName: name,
                loadTime: LatencyMetric(
                    p50: baseP50,
                    p95: baseP50 * 2.2,
                    p99: baseP50 * 3.8
                ),
                viewCount: 12_000 - index * 1_400 + ((index * 7) % 500)
            )
        }

        let networkMetrics = NetworkPerformanceMetrics(
            requestLatency: LatencyMetric(p50: 145, p95: 420, p99: 890),
            errorRate: 0.023,
            totalRequests: 284_500,
            failedRequests: 6_543,
            latencyTrend: makeTimeSeries(dayCount: dayCount, base: 145, variance: 30, now: now)
        )

        let memoryUsage = makeTimeSeries(dayCount: dayCount, base: 85, variance: 15, now: now)
        let cpuUsage = makeTimeSeries(dayCount: dayCount, base: 22, variance: 8, now: now)

        // Crash trend: small daily crash rate fluctuations
        let crashTrend: [TimeSeriesPoint] = (0..<dayCount).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(dayCount - 1 - dayOffset), to: now)!
            let base = 0.45
            let noise = Double((dayOffset * 13) % 7) * 0.05 - 0.15
            return TimeSeriesPoint(date: date, value: max(0.1, base + noise))
        }

        return AppPerformanceMetrics(
            crashRate: 0.48,
            crashFreeSessions: 99.52,
            launchTime: launchTime,
            screenLoadTimes: screenLoadTimes,
            networkMetrics: networkMetrics,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            offlineQueueDepth: 3,
            syncSuccessRate: 0.987,
            crashTrend: crashTrend
        )
    }

    public func fetchInteractionSignals(timeRange: DashboardTimeRange) async throws -> InteractionSignalMetrics {
        try throwIfStubbed()
        try await simulateDelay()

        let now = Date()
        let dayCount = daysForRange(timeRange)

        let recentSignals: [SignalFeedItem] = [
            SignalFeedItem(
                signalType: .rageTap,
                severity: .high,
                screen: "TaskBoard",
                description: "5 rapid taps on unresponsive filter button",
                timestamp: now.addingTimeInterval(-120),
                triggeringEventCount: 5
            ),
            SignalFeedItem(
                signalType: .deadTap,
                severity: .medium,
                screen: "TaskDetail",
                description: "Tap on non-interactive status label produced no response",
                timestamp: now.addingTimeInterval(-340),
                triggeringEventCount: 1
            ),
            SignalFeedItem(
                signalType: .abandon,
                severity: .medium,
                screen: "CreateTask",
                description: "User navigated away after 3 seconds without any interaction",
                timestamp: now.addingTimeInterval(-890),
                triggeringEventCount: 3
            ),
            SignalFeedItem(
                signalType: .latencySpike,
                severity: .high,
                screen: "ProjectList",
                description: "Screen load took 4.2s (p99 threshold: 1.5s)",
                timestamp: now.addingTimeInterval(-1500),
                triggeringEventCount: 1
            ),
            SignalFeedItem(
                signalType: .errorBurst,
                severity: .critical,
                screen: "TaskBoard",
                description: "12 API errors in 30 second window",
                timestamp: now.addingTimeInterval(-2100),
                triggeringEventCount: 12
            ),
            SignalFeedItem(
                signalType: .rageTap,
                severity: .medium,
                screen: "ProjectDetail",
                description: "3 rapid taps on member avatar with no navigation",
                timestamp: now.addingTimeInterval(-3600),
                triggeringEventCount: 3
            ),
            SignalFeedItem(
                signalType: .excessiveScroll,
                severity: .low,
                screen: "NotificationFeed",
                description: "Continuous scrolling for 45 seconds without settling",
                timestamp: now.addingTimeInterval(-5400),
                triggeringEventCount: 8
            ),
            SignalFeedItem(
                signalType: .deadTap,
                severity: .low,
                screen: "Profile",
                description: "Tap on avatar area in header - no action bound",
                timestamp: now.addingTimeInterval(-7200),
                triggeringEventCount: 1
            ),
        ]

        let signalsByScreen: [ScreenSignalSummary] = [
            ScreenSignalSummary(
                screenName: "TaskBoard",
                rageTapCount: 34,
                deadTapCount: 12,
                abandonCount: 8,
                latencySpikeCount: 5,
                totalSignals: 59,
                severityBreakdown: [
                    Severity.low.rawValue: 10,
                    Severity.medium.rawValue: 28,
                    Severity.high.rawValue: 16,
                    Severity.critical.rawValue: 5
                ]
            ),
            ScreenSignalSummary(
                screenName: "TaskDetail",
                rageTapCount: 8,
                deadTapCount: 22,
                abandonCount: 5,
                latencySpikeCount: 2,
                totalSignals: 37,
                severityBreakdown: [
                    Severity.low.rawValue: 15,
                    Severity.medium.rawValue: 18,
                    Severity.high.rawValue: 4,
                    Severity.critical.rawValue: 0
                ]
            ),
            ScreenSignalSummary(
                screenName: "ProjectList",
                rageTapCount: 5,
                deadTapCount: 3,
                abandonCount: 12,
                latencySpikeCount: 8,
                totalSignals: 28,
                severityBreakdown: [
                    Severity.low.rawValue: 8,
                    Severity.medium.rawValue: 12,
                    Severity.high.rawValue: 6,
                    Severity.critical.rawValue: 2
                ]
            ),
            ScreenSignalSummary(
                screenName: "CreateTask",
                rageTapCount: 2,
                deadTapCount: 6,
                abandonCount: 18,
                latencySpikeCount: 1,
                totalSignals: 27,
                severityBreakdown: [
                    Severity.low.rawValue: 12,
                    Severity.medium.rawValue: 11,
                    Severity.high.rawValue: 4,
                    Severity.critical.rawValue: 0
                ]
            ),
            ScreenSignalSummary(
                screenName: "NotificationFeed",
                rageTapCount: 3,
                deadTapCount: 4,
                abandonCount: 2,
                latencySpikeCount: 1,
                totalSignals: 10,
                severityBreakdown: [
                    Severity.low.rawValue: 6,
                    Severity.medium.rawValue: 3,
                    Severity.high.rawValue: 1,
                    Severity.critical.rawValue: 0
                ]
            ),
        ]

        let trendTypes: [SignalType] = [.rageTap, .deadTap, .abandon, .latencySpike, .errorBurst]
        let signalTrends: [SignalTrendData] = trendTypes.enumerated().map { index, signalType in
            let base: Double = 12 - Double(index) * 2
            let points = makeTimeSeries(dayCount: dayCount, base: base, variance: 4, now: now)
            return SignalTrendData(signalType: signalType, dataPoints: points)
        }

        let topFrictionPoints: [FrictionPoint] = [
            FrictionPoint(
                screen: "TaskBoard",
                signalType: .rageTap,
                count: 34,
                severity: .high,
                trend: .increasing,
                description: "Filter button on TaskBoard is unresponsive during data loads"
            ),
            FrictionPoint(
                screen: "TaskDetail",
                signalType: .deadTap,
                count: 22,
                severity: .medium,
                trend: .stable,
                description: "Status label looks tappable but has no interaction handler"
            ),
            FrictionPoint(
                screen: "CreateTask",
                signalType: .abandon,
                count: 18,
                severity: .medium,
                trend: .increasing,
                description: "Users abandoning task creation form - possible UX complexity issue"
            ),
            FrictionPoint(
                screen: "ProjectList",
                signalType: .latencySpike,
                count: 8,
                severity: .high,
                trend: .decreasing,
                description: "Slow initial load when project list exceeds 50 items"
            ),
            FrictionPoint(
                screen: "TaskBoard",
                signalType: .errorBurst,
                count: 5,
                severity: .critical,
                trend: .stable,
                description: "Intermittent API failures during board column reordering"
            ),
        ]

        let detectorHealth: [DetectorHealthMetric] = [
            DetectorHealthMetric(
                detectorName: "RageTapDetector",
                signalType: .rageTap,
                totalDetections: 156,
                estimatedFalsePositiveRate: 0.08,
                lastDetection: now.addingTimeInterval(-120),
                isActive: true
            ),
            DetectorHealthMetric(
                detectorName: "DeadTapDetector",
                signalType: .deadTap,
                totalDetections: 89,
                estimatedFalsePositiveRate: 0.12,
                lastDetection: now.addingTimeInterval(-340),
                isActive: true
            ),
            DetectorHealthMetric(
                detectorName: "AbandonDetector",
                signalType: .abandon,
                totalDetections: 67,
                estimatedFalsePositiveRate: 0.15,
                lastDetection: now.addingTimeInterval(-890),
                isActive: true
            ),
            DetectorHealthMetric(
                detectorName: "LatencySpikeDetector",
                signalType: .latencySpike,
                totalDetections: 23,
                estimatedFalsePositiveRate: 0.05,
                lastDetection: now.addingTimeInterval(-1500),
                isActive: true
            ),
            DetectorHealthMetric(
                detectorName: "ErrorBurstDetector",
                signalType: .errorBurst,
                totalDetections: 12,
                estimatedFalsePositiveRate: 0.03,
                lastDetection: now.addingTimeInterval(-2100),
                isActive: true
            ),
        ]

        let totalSignals = signalsByScreen.reduce(0) { $0 + $1.totalSignals }
        let hours = Double(dayCount) * 24.0
        let signalRate = Double(totalSignals) / max(hours, 1)

        return InteractionSignalMetrics(
            recentSignals: recentSignals,
            signalsByScreen: signalsByScreen,
            signalTrends: signalTrends,
            topFrictionPoints: topFrictionPoints,
            detectorHealth: detectorHealth,
            totalSignals: totalSignals,
            signalRate: signalRate
        )
    }

    public func fetchAgenticWork(timeRange: DashboardTimeRange) async throws -> AgenticWorkMetrics {
        try throwIfStubbed()
        try await simulateDelay()

        let now = Date()
        let calendar = Calendar.current

        let pipelineStatus: [PipelineItem] = [
            PipelineItem(
                featureName: "Smart Task Prioritization",
                milestone: "M7",
                status: .completed,
                assignedAgent: "Implementer",
                startedAt: calendar.date(byAdding: .day, value: -14, to: now),
                completedAt: calendar.date(byAdding: .day, value: -2, to: now)
            ),
            PipelineItem(
                featureName: "Drag-and-Drop Board Reorder",
                milestone: "M7",
                status: .testing,
                assignedAgent: "Tester",
                startedAt: calendar.date(byAdding: .day, value: -7, to: now)
            ),
            PipelineItem(
                featureName: "Offline Conflict Resolution UI",
                milestone: "M8",
                status: .inProgress,
                assignedAgent: "Implementer",
                startedAt: calendar.date(byAdding: .day, value: -3, to: now)
            ),
            PipelineItem(
                featureName: "Advanced Filter Persistence",
                milestone: "M8",
                status: .reviewing,
                assignedAgent: "Reviewer",
                startedAt: calendar.date(byAdding: .day, value: -5, to: now)
            ),
            PipelineItem(
                featureName: "Team Activity Feed",
                milestone: "M9",
                status: .planned
            ),
            PipelineItem(
                featureName: "Experimentation Agent Integration",
                milestone: "M9",
                status: .planned
            ),
        ]

        let experiments: [ExperimentSummary] = [
            ExperimentSummary(
                id: IDs.experiment1,
                name: "TaskBoard Column Width Optimization",
                hypothesis: "Wider columns reduce horizontal scroll rage taps by 30%",
                status: .concluded,
                primaryMetric: "rage_tap_rate",
                primaryMetricResult: -0.42,
                outcome: .positive,
                startDate: calendar.date(byAdding: .day, value: -21, to: now),
                endDate: calendar.date(byAdding: .day, value: -7, to: now),
                autoIntegrated: true
            ),
            ExperimentSummary(
                id: IDs.experiment2,
                name: "Create Task Form Simplification",
                hypothesis: "Reducing required fields from 5 to 3 decreases abandon rate by 25%",
                status: .running,
                primaryMetric: "abandon_rate",
                startDate: calendar.date(byAdding: .day, value: -5, to: now)
            ),
            ExperimentSummary(
                id: IDs.experiment3,
                name: "ProjectList Pagination vs Infinite Scroll",
                hypothesis: "Infinite scroll reduces latency spikes on large project lists by 40%",
                status: .running,
                primaryMetric: "latency_spike_count",
                startDate: calendar.date(byAdding: .day, value: -3, to: now)
            ),
            ExperimentSummary(
                id: IDs.experiment4,
                name: "Notification Badge Placement",
                hypothesis: "Moving badge to tab bar increases notification tap rate by 15%",
                status: .concluded,
                primaryMetric: "notification_tap_rate",
                primaryMetricResult: 0.08,
                outcome: .inconclusive,
                startDate: calendar.date(byAdding: .day, value: -30, to: now),
                endDate: calendar.date(byAdding: .day, value: -14, to: now)
            ),
            ExperimentSummary(
                id: IDs.experiment5,
                name: "Dark Mode Default for Night Sessions",
                hypothesis: "Auto dark mode after 8pm reduces error burst signals by 20%",
                status: .draft,
                primaryMetric: "error_burst_rate"
            ),
        ]

        let activeExperiments: [ActiveExperimentStatus] = [
            ActiveExperimentStatus(
                id: IDs.experiment2,
                experimentName: "Create Task Form Simplification",
                hypothesis: "Reducing required fields from 5 to 3 decreases abandon rate by 25%",
                variantNames: ["Control (5 fields)", "Variant A (3 fields)", "Variant B (3 fields + progressive)"],
                primaryMetric: "abandon_rate",
                currentMetricValue: -0.18,
                targetMetricValue: -0.25,
                guardrailStatuses: [
                    GuardrailStatus(
                        name: "Task Completion Rate",
                        metric: "task_completion_rate",
                        threshold: -0.05,
                        currentValue: 0.02,
                        isPassing: true,
                        tier: .hard
                    ),
                    GuardrailStatus(
                        name: "Crash Free Sessions",
                        metric: "crash_free_sessions",
                        threshold: 0.995,
                        currentValue: 0.998,
                        isPassing: true,
                        tier: .hard
                    ),
                    GuardrailStatus(
                        name: "Time to Create Task",
                        metric: "avg_task_creation_time",
                        threshold: 45.0,
                        currentValue: 32.0,
                        isPassing: true,
                        tier: .soft
                    ),
                ],
                progress: 0.65,
                startDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                estimatedEndDate: calendar.date(byAdding: .day, value: 3, to: now)!,
                sampleSize: 2_340
            ),
            ActiveExperimentStatus(
                id: IDs.experiment3,
                experimentName: "ProjectList Pagination vs Infinite Scroll",
                hypothesis: "Infinite scroll reduces latency spikes on large project lists by 40%",
                variantNames: ["Control (Pagination)", "Variant (Infinite Scroll)"],
                primaryMetric: "latency_spike_count",
                currentMetricValue: -0.31,
                targetMetricValue: -0.40,
                guardrailStatuses: [
                    GuardrailStatus(
                        name: "Memory Usage",
                        metric: "peak_memory_mb",
                        threshold: 200.0,
                        currentValue: 178.0,
                        isPassing: true,
                        tier: .hard
                    ),
                    GuardrailStatus(
                        name: "Scroll Jank Rate",
                        metric: "dropped_frames_pct",
                        threshold: 0.05,
                        currentValue: 0.03,
                        isPassing: true,
                        tier: .soft
                    ),
                ],
                progress: 0.38,
                startDate: calendar.date(byAdding: .day, value: -3, to: now)!,
                estimatedEndDate: calendar.date(byAdding: .day, value: 5, to: now)!,
                sampleSize: 1_120
            ),
        ]

        let experimentStats = ExperimentOverallStats(
            totalExperiments: 18,
            winRate: 0.56,
            autoIntegrationRate: 0.70,
            averageDuration: 604_800, // 7 days
            experimentsThisPeriod: 3
        )

        let agentActivityLog: [AgentActivityEntry] = [
            AgentActivityEntry(
                agentRole: "Experimenter",
                action: "experiment_started",
                description: "Started experiment: Create Task Form Simplification",
                timestamp: calendar.date(byAdding: .day, value: -5, to: now)!,
                relatedExperimentId: IDs.experiment2,
                relatedFeature: "CreateTask",
                status: .completed
            ),
            AgentActivityEntry(
                agentRole: "Planner",
                action: "hypothesis_generated",
                description: "Generated hypothesis for ProjectList infinite scroll based on latency spike signals",
                timestamp: calendar.date(byAdding: .day, value: -4, to: now)!,
                relatedExperimentId: IDs.experiment3,
                relatedFeature: "ProjectList",
                status: .completed
            ),
            AgentActivityEntry(
                agentRole: "Implementer",
                action: "variant_implemented",
                description: "Implemented infinite scroll variant for ProjectList experiment",
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                relatedExperimentId: IDs.experiment3,
                relatedFeature: "ProjectList",
                status: .completed
            ),
            AgentActivityEntry(
                agentRole: "Experimenter",
                action: "experiment_started",
                description: "Started experiment: ProjectList Pagination vs Infinite Scroll",
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                relatedExperimentId: IDs.experiment3,
                relatedFeature: "ProjectList",
                status: .completed
            ),
            AgentActivityEntry(
                agentRole: "Evaluator",
                action: "guardrail_check",
                description: "All guardrails passing for Create Task Form Simplification (day 5/8)",
                timestamp: now.addingTimeInterval(-3600),
                relatedExperimentId: IDs.experiment2,
                relatedFeature: "CreateTask",
                status: .completed
            ),
            AgentActivityEntry(
                agentRole: "Evaluator",
                action: "guardrail_check",
                description: "All guardrails passing for ProjectList experiment (day 3/8)",
                timestamp: now.addingTimeInterval(-1800),
                relatedExperimentId: IDs.experiment3,
                relatedFeature: "ProjectList",
                status: .completed
            ),
            AgentActivityEntry(
                agentRole: "Planner",
                action: "signal_analysis",
                description: "Analyzing increasing rage tap trend on TaskBoard filter controls",
                timestamp: now.addingTimeInterval(-600),
                relatedFeature: "TaskBoard",
                status: .started
            ),
        ]

        let orchestrationState = OrchestrationStatus(
            currentPhase: "EXECUTING",
            activeAgents: 3,
            pendingTasks: 2,
            lastActivity: now.addingTimeInterval(-600)
        )

        return AgenticWorkMetrics(
            pipelineStatus: pipelineStatus,
            experiments: experiments,
            activeExperiments: activeExperiments,
            experimentStats: experimentStats,
            agentActivityLog: agentActivityLog,
            orchestrationState: orchestrationState
        )
    }

    public func fetchAlerts() async throws -> [DashboardAlert] {
        try throwIfStubbed()
        try await simulateDelay()

        let now = Date()

        let allAlerts: [DashboardAlert] = [
            DashboardAlert(
                id: IDs.alert1,
                type: .crashRateSpike,
                title: "Crash Rate Elevated",
                message: "Crash rate increased to 0.8% in the last hour, up from 0.4% baseline.",
                severity: .high,
                timestamp: now.addingTimeInterval(-1800)
            ),
            DashboardAlert(
                id: IDs.alert2,
                type: .experimentAutoIntegrated,
                title: "Experiment Auto-Integrated",
                message: "TaskBoard Column Width Optimization concluded with positive outcome and was auto-integrated.",
                severity: .low,
                timestamp: now.addingTimeInterval(-86400),
                relatedExperimentId: IDs.experiment1
            ),
            DashboardAlert(
                id: IDs.alert3,
                type: .signalBurst,
                title: "Signal Burst Detected",
                message: "12 error burst signals on TaskBoard in the last 30 minutes.",
                severity: .critical,
                timestamp: now.addingTimeInterval(-900)
            ),
        ]

        lock.lock()
        let acknowledged = acknowledgedAlertIds
        lock.unlock()

        return allAlerts.filter { !acknowledged.contains($0.id) }
    }

    public func acknowledgeAlert(id: UUID) async throws {
        try throwIfStubbed()
        try await simulateDelay()

        lock.lock()
        acknowledgedAlertIds.insert(id)
        lock.unlock()
    }

    // MARK: - Private Helpers

    private func daysForRange(_ range: DashboardTimeRange) -> Int {
        switch range {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }

    private func makeTimeSeries(
        dayCount: Int,
        base: Double,
        variance: Double,
        now: Date
    ) -> [TimeSeriesPoint] {
        let calendar = Calendar.current
        return (0..<dayCount).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -(dayCount - 1 - dayOffset), to: now)!
            let noise = Double((dayOffset * 17 + 5) % 13) / 13.0 * variance * 2 - variance
            return TimeSeriesPoint(date: date, value: max(0, base + noise))
        }
    }

    private func simulateDelay() async throws {
        if simulatedLatency > 0 {
            try await Task.sleep(nanoseconds: simulatedLatency)
        }
    }

    private func throwIfStubbed() throws {
        if let stubbedError {
            throw stubbedError
        }
    }
}
