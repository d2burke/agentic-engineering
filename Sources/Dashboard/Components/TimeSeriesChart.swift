import SwiftUI
import Charts
import DesignSystem

// MARK: - TimeSeriesChart

/// A reusable chart wrapper using Swift Charts for displaying time series data.
///
/// Renders a line chart with optional area fill, proper date-based X axis,
/// value-based Y axis, and grid lines. Supports customizable color and title.
///
/// ## Usage
/// ```swift
/// TimeSeriesChart(
///     data: viewModel.metrics.crashRateTrend,
///     title: "Crash Rate Over Time",
///     color: .red,
///     showArea: true
/// )
/// ```
public struct TimeSeriesChart: View {
    private let data: [TimeSeriesPoint]
    private let title: String
    private let color: Color
    private let showArea: Bool

    /// Creates a time series chart.
    ///
    /// - Parameters:
    ///   - data: The array of time series data points.
    ///   - title: The chart title displayed above the chart.
    ///   - color: The line and area fill color.
    ///   - showArea: Whether to show a gradient area fill below the line. Default is `false`.
    public init(
        data: [TimeSeriesPoint],
        title: String,
        color: Color = ColorTokens.primary,
        showArea: Bool = false
    ) {
        self.data = data
        self.title = title
        self.color = color
        self.showArea = showArea
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            if data.isEmpty {
                emptyState
            } else {
                chartContent
                    .frame(height: 200)
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            if showArea {
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            PointMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(color)
            .symbolSize(16)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(ColorTokens.divider)
                AxisValueLabel()
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(ColorTokens.divider)
                AxisValueLabel()
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)

            Text("No data available")
                .font(Typography.caption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Multi-Line Time Series Chart

/// A chart that overlays multiple time series lines, each with a
/// different color and label. Used for comparing metrics over time.
public struct MultiLineTimeSeriesChart: View {
    private let title: String
    private let seriesData: [(label: String, data: [TimeSeriesPoint], color: Color)]

    /// Creates a multi-line time series chart.
    ///
    /// - Parameters:
    ///   - title: The chart title.
    ///   - seriesData: An array of tuples containing label, data points, and line color.
    public init(title: String, seriesData: [(label: String, data: [TimeSeriesPoint], color: Color)]) {
        self.title = title
        self.seriesData = seriesData
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            // Legend
            HStack(spacing: Spacing.md) {
                ForEach(seriesData.indices, id: \.self) { index in
                    HStack(spacing: Spacing.xxs) {
                        Circle()
                            .fill(seriesData[index].color)
                            .frame(width: 8, height: 8)

                        Text(seriesData[index].label)
                            .font(Typography.caption2)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
            }

            Chart {
                ForEach(seriesData.indices, id: \.self) { seriesIndex in
                    let series = seriesData[seriesIndex]
                    ForEach(series.data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value),
                            series: .value("Series", series.label)
                        )
                        .foregroundStyle(series.color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(ColorTokens.divider)
                    AxisValueLabel()
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(ColorTokens.divider)
                    AxisValueLabel()
                        .font(Typography.caption2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Time Series Charts") {
    let sampleData: [TimeSeriesPoint] = (0..<14).map { day in
        TimeSeriesPoint(
            date: Calendar.current.date(byAdding: .day, value: -13 + day, to: Date())!,
            value: Double.random(in: 50...150)
        )
    }

    ScrollView {
        VStack(spacing: 16) {
            TimeSeriesChart(
                data: sampleData,
                title: "User Growth",
                color: ColorTokens.primary,
                showArea: true
            )

            TimeSeriesChart(
                data: sampleData,
                title: "Crash Rate Trend",
                color: ColorTokens.error,
                showArea: false
            )

            MultiLineTimeSeriesChart(
                title: "Network Latency",
                seriesData: [
                    ("P50", sampleData, ColorTokens.info),
                    ("P95", sampleData.map {
                        TimeSeriesPoint(id: UUID(), date: $0.date, value: $0.value * 1.5)
                    }, ColorTokens.warning),
                ]
            )
        }
        .padding()
    }
    .background(ColorTokens.backgroundSecondary)
}
#endif
