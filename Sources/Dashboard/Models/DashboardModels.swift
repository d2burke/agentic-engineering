import Foundation
import Models
import Analytics

// MARK: - Time Range

/// Time range for all dashboard queries.
///
/// Provides predefined intervals aligned with common analytics reporting
/// periods. Each case carries a raw-value label suitable for API queries
/// and computed properties for display and date arithmetic.
public enum DashboardTimeRange: String, CaseIterable, Identifiable, Sendable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case quarter = "90d"

    public var id: String { rawValue }

    /// Human-readable label for picker controls and chart headers.
    public var displayName: String {
        switch self {
        case .day: return "Last 24 Hours"
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .quarter: return "Last 90 Days"
        }
    }

    /// The calendar-based `DateInterval` ending at the current moment.
    public var dateInterval: DateInterval {
        let now = Date()
        let calendar = Calendar.current
        let start: Date
        switch self {
        case .day:
            start = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .quarter:
            start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        }
        return DateInterval(start: start, end: now)
    }
}

// MARK: - Dashboard Panel

/// Identifies which panel is currently selected in the dashboard.
public enum DashboardPanel: String, CaseIterable, Identifiable, Sendable {
    case business
    case appPerformance
    case interactionSignals
    case agenticWork
    case alerts

    public var id: String { rawValue }

    /// Human-readable label for tab controls.
    public var displayName: String {
        switch self {
        case .business: return "Business"
        case .appPerformance: return "Performance"
        case .interactionSignals: return "Signals"
        case .agenticWork: return "Agentic"
        case .alerts: return "Alerts"
        }
    }

    /// SF Symbol name for tab icons.
    public var iconName: String {
        switch self {
        case .business: return "chart.bar.xaxis"
        case .appPerformance: return "speedometer"
        case .interactionSignals: return "waveform.path.ecg"
        case .agenticWork: return "cpu"
        case .alerts: return "bell.badge"
        }
    }
}

// MARK: - Time Series

/// A single (date, value) data point for plotting time-series charts.
public struct TimeSeriesPoint: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let value: Double

    public init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

// MARK: - === Business Metrics ===

/// Aggregate business-level metrics for the selected time range.
public struct BusinessMetrics: Codable, Sendable, Equatable {
    public let activeUsers: ActiveUserMetrics
    public let projectMetrics: ProjectMetrics
    public let taskMetrics: TaskMetrics
    public let teamVelocity: [VelocityDataPoint]
    public let topContributors: [ContributorStats]

    public init(
        activeUsers: ActiveUserMetrics,
        projectMetrics: ProjectMetrics,
        taskMetrics: TaskMetrics,
        teamVelocity: [VelocityDataPoint],
        topContributors: [ContributorStats]
    ) {
        self.activeUsers = activeUsers
        self.projectMetrics = projectMetrics
        self.taskMetrics = taskMetrics
        self.teamVelocity = teamVelocity
        self.topContributors = topContributors
    }
}

/// Daily, weekly, and monthly active user counts with growth trend.
public struct ActiveUserMetrics: Codable, Sendable, Equatable {
    public let dau: Int
    public let wau: Int
    public let mau: Int
    public let growthTrend: [TimeSeriesPoint]

    public init(dau: Int, wau: Int, mau: Int, growthTrend: [TimeSeriesPoint]) {
        self.dau = dau
        self.wau = wau
        self.mau = mau
        self.growthTrend = growthTrend
    }
}

/// High-level project statistics.
public struct ProjectMetrics: Codable, Sendable, Equatable {
    public let totalProjects: Int
    public let activeProjects: Int
    public let createdThisPeriod: Int

    public init(totalProjects: Int, activeProjects: Int, createdThisPeriod: Int) {
        self.totalProjects = totalProjects
        self.activeProjects = activeProjects
        self.createdThisPeriod = createdThisPeriod
    }
}

/// Task throughput, completion rates, and distribution breakdowns.
///
/// Distributions use `String` keys (matching `TaskStatus.rawValue` and
/// `TaskPriority.rawValue`) for Codable compatibility.
public struct TaskMetrics: Codable, Sendable, Equatable {
    public let totalTasks: Int
    public let completedThisPeriod: Int
    /// Fraction of tasks completed (0.0 - 1.0).
    public let completionRate: Double
    /// Average seconds from creation to completion.
    public let averageCompletionTime: TimeInterval
    /// Keys are `TaskStatus.rawValue` strings.
    public let statusDistribution: [String: Int]
    /// Keys are `TaskPriority.rawValue` strings.
    public let priorityDistribution: [String: Int]
    public let throughputTrend: [TimeSeriesPoint]

    public init(
        totalTasks: Int,
        completedThisPeriod: Int,
        completionRate: Double,
        averageCompletionTime: TimeInterval,
        statusDistribution: [String: Int],
        priorityDistribution: [String: Int],
        throughputTrend: [TimeSeriesPoint]
    ) {
        self.totalTasks = totalTasks
        self.completedThisPeriod = completedThisPeriod
        self.completionRate = completionRate
        self.averageCompletionTime = averageCompletionTime
        self.statusDistribution = statusDistribution
        self.priorityDistribution = priorityDistribution
        self.throughputTrend = throughputTrend
    }
}

/// A single velocity measurement for a sprint or reporting period.
public struct VelocityDataPoint: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let periodLabel: String
    public let tasksCompleted: Int
    public let tasksCreated: Int
    public let date: Date

    public init(
        id: UUID = UUID(),
        periodLabel: String,
        tasksCompleted: Int,
        tasksCreated: Int,
        date: Date
    ) {
        self.id = id
        self.periodLabel = periodLabel
        self.tasksCompleted = tasksCompleted
        self.tasksCreated = tasksCreated
        self.date = date
    }
}

/// Per-user contribution statistics for the leaderboard.
public struct ContributorStats: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let displayName: String
    public let tasksCompleted: Int
    public let tasksCreated: Int
    public let commentsAdded: Int

    public init(
        id: UUID = UUID(),
        userId: UUID,
        displayName: String,
        tasksCompleted: Int,
        tasksCreated: Int,
        commentsAdded: Int
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.tasksCompleted = tasksCompleted
        self.tasksCreated = tasksCreated
        self.commentsAdded = commentsAdded
    }
}

// MARK: - === App Performance ===

/// Comprehensive application performance metrics.
public struct AppPerformanceMetrics: Codable, Sendable, Equatable {
    /// Crash rate as a percentage (e.g., 0.5 means 0.5%).
    public let crashRate: Double
    /// Percentage of sessions that were crash-free (e.g., 99.5).
    public let crashFreeSessions: Double
    public let launchTime: LatencyMetric
    public let screenLoadTimes: [ScreenPerformance]
    public let networkMetrics: NetworkPerformanceMetrics
    public let memoryUsage: [TimeSeriesPoint]
    public let cpuUsage: [TimeSeriesPoint]
    public let offlineQueueDepth: Int
    /// Fraction of sync operations that succeeded (0.0 - 1.0).
    public let syncSuccessRate: Double
    public let crashTrend: [TimeSeriesPoint]

    public init(
        crashRate: Double,
        crashFreeSessions: Double,
        launchTime: LatencyMetric,
        screenLoadTimes: [ScreenPerformance],
        networkMetrics: NetworkPerformanceMetrics,
        memoryUsage: [TimeSeriesPoint],
        cpuUsage: [TimeSeriesPoint],
        offlineQueueDepth: Int,
        syncSuccessRate: Double,
        crashTrend: [TimeSeriesPoint]
    ) {
        self.crashRate = crashRate
        self.crashFreeSessions = crashFreeSessions
        self.launchTime = launchTime
        self.screenLoadTimes = screenLoadTimes
        self.networkMetrics = networkMetrics
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.offlineQueueDepth = offlineQueueDepth
        self.syncSuccessRate = syncSuccessRate
        self.crashTrend = crashTrend
    }
}

/// Percentile latency measurements (p50 / p95 / p99) in milliseconds.
public struct LatencyMetric: Codable, Sendable, Equatable {
    public let p50: TimeInterval
    public let p95: TimeInterval
    public let p99: TimeInterval

    public init(p50: TimeInterval, p95: TimeInterval, p99: TimeInterval) {
        self.p50 = p50
        self.p95 = p95
        self.p99 = p99
    }
}

/// Per-screen load performance with view count.
public struct ScreenPerformance: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let screenName: String
    public let loadTime: LatencyMetric
    public let viewCount: Int

    public init(
        id: UUID = UUID(),
        screenName: String,
        loadTime: LatencyMetric,
        viewCount: Int
    ) {
        self.id = id
        self.screenName = screenName
        self.loadTime = loadTime
        self.viewCount = viewCount
    }
}

/// Network layer performance summary.
public struct NetworkPerformanceMetrics: Codable, Sendable, Equatable {
    public let requestLatency: LatencyMetric
    /// Error rate as a fraction (0.0 - 1.0).
    public let errorRate: Double
    public let totalRequests: Int
    public let failedRequests: Int
    public let latencyTrend: [TimeSeriesPoint]

    public init(
        requestLatency: LatencyMetric,
        errorRate: Double,
        totalRequests: Int,
        failedRequests: Int,
        latencyTrend: [TimeSeriesPoint]
    ) {
        self.requestLatency = requestLatency
        self.errorRate = errorRate
        self.totalRequests = totalRequests
        self.failedRequests = failedRequests
        self.latencyTrend = latencyTrend
    }
}

// MARK: - === Interaction Signals ===

/// Aggregate interaction signal metrics for the dashboard.
public struct InteractionSignalMetrics: Codable, Sendable, Equatable {
    public let recentSignals: [SignalFeedItem]
    public let signalsByScreen: [ScreenSignalSummary]
    public let signalTrends: [SignalTrendData]
    public let topFrictionPoints: [FrictionPoint]
    public let detectorHealth: [DetectorHealthMetric]
    public let totalSignals: Int
    /// Signals emitted per hour during the selected time range.
    public let signalRate: Double

    public init(
        recentSignals: [SignalFeedItem],
        signalsByScreen: [ScreenSignalSummary],
        signalTrends: [SignalTrendData],
        topFrictionPoints: [FrictionPoint],
        detectorHealth: [DetectorHealthMetric],
        totalSignals: Int,
        signalRate: Double
    ) {
        self.recentSignals = recentSignals
        self.signalsByScreen = signalsByScreen
        self.signalTrends = signalTrends
        self.topFrictionPoints = topFrictionPoints
        self.detectorHealth = detectorHealth
        self.totalSignals = totalSignals
        self.signalRate = signalRate
    }
}

/// A single item in the live signal feed.
public struct SignalFeedItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let signalType: SignalType
    public let severity: Severity
    public let screen: String
    public let description: String
    public let timestamp: Date
    public let triggeringEventCount: Int

    public init(
        id: UUID = UUID(),
        signalType: SignalType,
        severity: Severity,
        screen: String,
        description: String,
        timestamp: Date = Date(),
        triggeringEventCount: Int
    ) {
        self.id = id
        self.signalType = signalType
        self.severity = severity
        self.screen = screen
        self.description = description
        self.timestamp = timestamp
        self.triggeringEventCount = triggeringEventCount
    }
}

/// Per-screen breakdown of signal types and severities.
///
/// Severity breakdown uses `String` keys (matching `Severity.rawValue`)
/// for Codable compatibility.
public struct ScreenSignalSummary: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let screenName: String
    public let rageTapCount: Int
    public let deadTapCount: Int
    public let abandonCount: Int
    public let latencySpikeCount: Int
    public let totalSignals: Int
    /// Keys are `Severity.rawValue` strings.
    public let severityBreakdown: [String: Int]

    public init(
        id: UUID = UUID(),
        screenName: String,
        rageTapCount: Int,
        deadTapCount: Int,
        abandonCount: Int,
        latencySpikeCount: Int,
        totalSignals: Int,
        severityBreakdown: [String: Int]
    ) {
        self.id = id
        self.screenName = screenName
        self.rageTapCount = rageTapCount
        self.deadTapCount = deadTapCount
        self.abandonCount = abandonCount
        self.latencySpikeCount = latencySpikeCount
        self.totalSignals = totalSignals
        self.severityBreakdown = severityBreakdown
    }
}

/// Time series of a specific signal type over the reporting period.
public struct SignalTrendData: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let signalType: SignalType
    public let dataPoints: [TimeSeriesPoint]

    public init(
        id: UUID = UUID(),
        signalType: SignalType,
        dataPoints: [TimeSeriesPoint]
    ) {
        self.id = id
        self.signalType = signalType
        self.dataPoints = dataPoints
    }
}

/// A user-facing friction point identified from aggregated signals.
public struct FrictionPoint: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let screen: String
    public let signalType: SignalType
    public let count: Int
    public let severity: Severity
    public let trend: TrendDirection
    public let description: String

    public init(
        id: UUID = UUID(),
        screen: String,
        signalType: SignalType,
        count: Int,
        severity: Severity,
        trend: TrendDirection,
        description: String
    ) {
        self.id = id
        self.screen = screen
        self.signalType = signalType
        self.count = count
        self.severity = severity
        self.trend = trend
        self.description = description
    }
}

/// The directional trend of a metric over time.
public enum TrendDirection: String, Codable, Sendable {
    case increasing
    case stable
    case decreasing

    public var displayName: String { rawValue.capitalized }

    /// SF Symbol name for visual indication.
    public var iconName: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .decreasing: return "arrow.down.right"
        }
    }
}

/// Health status of a single behavioral signal detector.
public struct DetectorHealthMetric: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let detectorName: String
    public let signalType: SignalType
    public let totalDetections: Int
    public let estimatedFalsePositiveRate: Double
    public let lastDetection: Date?
    public let isActive: Bool

    public init(
        id: UUID = UUID(),
        detectorName: String,
        signalType: SignalType,
        totalDetections: Int,
        estimatedFalsePositiveRate: Double,
        lastDetection: Date?,
        isActive: Bool
    ) {
        self.id = id
        self.detectorName = detectorName
        self.signalType = signalType
        self.totalDetections = totalDetections
        self.estimatedFalsePositiveRate = estimatedFalsePositiveRate
        self.lastDetection = lastDetection
        self.isActive = isActive
    }
}

// MARK: - === Agentic Work ===

/// Combined metrics for the autonomous experimentation pipeline.
public struct AgenticWorkMetrics: Codable, Sendable, Equatable {
    public let pipelineStatus: [PipelineItem]
    public let experiments: [ExperimentSummary]
    public let activeExperiments: [ActiveExperimentStatus]
    public let experimentStats: ExperimentOverallStats
    public let agentActivityLog: [AgentActivityEntry]
    public let orchestrationState: OrchestrationStatus

    public init(
        pipelineStatus: [PipelineItem],
        experiments: [ExperimentSummary],
        activeExperiments: [ActiveExperimentStatus],
        experimentStats: ExperimentOverallStats,
        agentActivityLog: [AgentActivityEntry],
        orchestrationState: OrchestrationStatus
    ) {
        self.pipelineStatus = pipelineStatus
        self.experiments = experiments
        self.activeExperiments = activeExperiments
        self.experimentStats = experimentStats
        self.agentActivityLog = agentActivityLog
        self.orchestrationState = orchestrationState
    }
}

/// A work item in the feature development pipeline.
public struct PipelineItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let featureName: String
    public let milestone: String
    public let status: PipelineItemStatus
    public let assignedAgent: String?
    public let startedAt: Date?
    public let completedAt: Date?

    public init(
        id: UUID = UUID(),
        featureName: String,
        milestone: String,
        status: PipelineItemStatus,
        assignedAgent: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.featureName = featureName
        self.milestone = milestone
        self.status = status
        self.assignedAgent = assignedAgent
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

/// Lifecycle status of a pipeline work item.
public enum PipelineItemStatus: String, Codable, Sendable, CaseIterable {
    case planned
    case inProgress
    case reviewing
    case testing
    case completed
    case failed

    public var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .reviewing: return "Reviewing"
        case .testing: return "Testing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}

/// Summary of an experiment in the registry.
public struct ExperimentSummary: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let hypothesis: String
    public let status: ExperimentItemStatus
    public let primaryMetric: String
    public let primaryMetricResult: Double?
    public let outcome: ExperimentOutcome?
    public let startDate: Date?
    public let endDate: Date?
    public let autoIntegrated: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        hypothesis: String,
        status: ExperimentItemStatus,
        primaryMetric: String,
        primaryMetricResult: Double? = nil,
        outcome: ExperimentOutcome? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        autoIntegrated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.hypothesis = hypothesis
        self.status = status
        self.primaryMetric = primaryMetric
        self.primaryMetricResult = primaryMetricResult
        self.outcome = outcome
        self.startDate = startDate
        self.endDate = endDate
        self.autoIntegrated = autoIntegrated
    }
}

/// Lifecycle status of an experiment.
public enum ExperimentItemStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case approved
    case running
    case evaluating
    case concluded
    case rolledBack

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .approved: return "Approved"
        case .running: return "Running"
        case .evaluating: return "Evaluating"
        case .concluded: return "Concluded"
        case .rolledBack: return "Rolled Back"
        }
    }
}

/// The measured outcome of a concluded experiment.
public enum ExperimentOutcome: String, Codable, Sendable {
    case positive
    case negative
    case inconclusive
}

/// Detailed status of an actively running experiment.
public struct ActiveExperimentStatus: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let experimentName: String
    public let hypothesis: String
    public let variantNames: [String]
    public let primaryMetric: String
    public let currentMetricValue: Double
    public let targetMetricValue: Double
    public let guardrailStatuses: [GuardrailStatus]
    /// Progress as a fraction (0.0 - 1.0) based on elapsed vs. planned duration.
    public let progress: Double
    public let startDate: Date
    public let estimatedEndDate: Date
    public let sampleSize: Int

    public init(
        id: UUID = UUID(),
        experimentName: String,
        hypothesis: String,
        variantNames: [String],
        primaryMetric: String,
        currentMetricValue: Double,
        targetMetricValue: Double,
        guardrailStatuses: [GuardrailStatus],
        progress: Double,
        startDate: Date,
        estimatedEndDate: Date,
        sampleSize: Int
    ) {
        self.id = id
        self.experimentName = experimentName
        self.hypothesis = hypothesis
        self.variantNames = variantNames
        self.primaryMetric = primaryMetric
        self.currentMetricValue = currentMetricValue
        self.targetMetricValue = targetMetricValue
        self.guardrailStatuses = guardrailStatuses
        self.progress = progress
        self.startDate = startDate
        self.estimatedEndDate = estimatedEndDate
        self.sampleSize = sampleSize
    }
}

/// Status of a single guardrail metric for a running experiment.
public struct GuardrailStatus: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let metric: String
    public let threshold: Double
    public let currentValue: Double
    public let isPassing: Bool
    public let tier: GuardrailTier

    public init(
        id: UUID = UUID(),
        name: String,
        metric: String,
        threshold: Double,
        currentValue: Double,
        isPassing: Bool,
        tier: GuardrailTier
    ) {
        self.id = id
        self.name = name
        self.metric = metric
        self.threshold = threshold
        self.currentValue = currentValue
        self.isPassing = isPassing
        self.tier = tier
    }
}

/// Classification of guardrail strictness.
public enum GuardrailTier: String, Codable, Sendable {
    case hard
    case soft
    case value
}

/// Overall experiment program statistics.
public struct ExperimentOverallStats: Codable, Sendable, Equatable {
    public let totalExperiments: Int
    /// Fraction of experiments with a positive outcome.
    public let winRate: Double
    /// Fraction of positive experiments that were auto-integrated.
    public let autoIntegrationRate: Double
    /// Average experiment duration in seconds.
    public let averageDuration: TimeInterval
    public let experimentsThisPeriod: Int

    public init(
        totalExperiments: Int,
        winRate: Double,
        autoIntegrationRate: Double,
        averageDuration: TimeInterval,
        experimentsThisPeriod: Int
    ) {
        self.totalExperiments = totalExperiments
        self.winRate = winRate
        self.autoIntegrationRate = autoIntegrationRate
        self.averageDuration = averageDuration
        self.experimentsThisPeriod = experimentsThisPeriod
    }
}

/// A single entry in the agent activity log.
public struct AgentActivityEntry: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let agentRole: String
    public let action: String
    public let description: String
    public let timestamp: Date
    public let relatedExperimentId: UUID?
    public let relatedFeature: String?
    public let status: AgentActionStatus

    public init(
        id: UUID = UUID(),
        agentRole: String,
        action: String,
        description: String,
        timestamp: Date = Date(),
        relatedExperimentId: UUID? = nil,
        relatedFeature: String? = nil,
        status: AgentActionStatus
    ) {
        self.id = id
        self.agentRole = agentRole
        self.action = action
        self.description = description
        self.timestamp = timestamp
        self.relatedExperimentId = relatedExperimentId
        self.relatedFeature = relatedFeature
        self.status = status
    }
}

/// Status of an individual agent action.
public enum AgentActionStatus: String, Codable, Sendable {
    case started
    case completed
    case failed
    case blocked
}

/// Current status of the orchestration engine.
public struct OrchestrationStatus: Codable, Sendable, Equatable {
    /// Current phase label (e.g., "IDLE", "PLANNING", "EXECUTING").
    public let currentPhase: String
    public let activeAgents: Int
    public let pendingTasks: Int
    public let lastActivity: Date?

    public init(
        currentPhase: String,
        activeAgents: Int,
        pendingTasks: Int,
        lastActivity: Date?
    ) {
        self.currentPhase = currentPhase
        self.activeAgents = activeAgents
        self.pendingTasks = pendingTasks
        self.lastActivity = lastActivity
    }
}

// MARK: - === Dashboard Access Control ===

/// Access level determining which dashboard panels a user may view.
public enum DashboardAccessLevel: String, Codable, Sendable {
    /// Sees all panels including agentic work and interaction signals.
    case admin
    /// Sees business metrics and app performance.
    case member
    /// Sees business metrics only.
    case viewer
}

// MARK: - === Alerts ===

/// A dashboard-level alert surfaced to the operator.
public struct DashboardAlert: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let type: DashboardAlertType
    public let title: String
    public let message: String
    public let severity: Severity
    public let timestamp: Date
    public var isAcknowledged: Bool
    public let relatedExperimentId: UUID?

    public init(
        id: UUID = UUID(),
        type: DashboardAlertType,
        title: String,
        message: String,
        severity: Severity,
        timestamp: Date = Date(),
        isAcknowledged: Bool = false,
        relatedExperimentId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
        self.isAcknowledged = isAcknowledged
        self.relatedExperimentId = relatedExperimentId
    }
}

/// Categories of dashboard alerts.
public enum DashboardAlertType: String, Codable, Sendable {
    case crashRateSpike
    case signalBurst
    case guardrailViolation
    case experimentConcluded
    case experimentAutoIntegrated
    case syncFailure
}
