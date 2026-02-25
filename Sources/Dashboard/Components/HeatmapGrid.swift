import SwiftUI
import DesignSystem
import Analytics

// MARK: - HeatmapGrid

/// A grid visualization for signal distribution across screens and signal types.
///
/// Displays a matrix where rows represent screens and columns represent signal
/// types. Cell color intensity is based on the count of signals detected,
/// ranging from white (no signals) through yellow and orange to red (high count).
/// Tapping a cell shows a detail tooltip.
public struct HeatmapGrid: View {
    private let data: [ScreenSignalSummary]
    private let signalTypes: [SignalType]

    /// The currently selected cell for tooltip display.
    @State private var selectedCell: CellIdentifier?

    /// Creates a heatmap grid.
    ///
    /// - Parameters:
    ///   - data: The screen signal summaries containing counts per signal type.
    ///   - signalTypes: The signal types to display as columns.
    public init(data: [ScreenSignalSummary], signalTypes: [SignalType]) {
        self.data = data
        self.signalTypes = signalTypes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Signal Heatmap")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)

            if data.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 1) {
                        // Column headers
                        headerRow

                        // Data rows
                        ForEach(data) { summary in
                            dataRow(for: summary)
                        }
                    }
                }

                // Legend
                legendView
            }

            // Tooltip overlay
            if let cell = selectedCell {
                tooltipView(for: cell)
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 1) {
            // Empty corner cell for row labels
            Text("Screen")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(width: 80, alignment: .leading)
                .padding(.horizontal, Spacing.xs)

            // Signal type column headers
            ForEach(signalTypes, id: \.rawValue) { type in
                Text(shortName(for: type))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .frame(width: 44, height: 32)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Data Row

    private func dataRow(for summary: ScreenSignalSummary) -> some View {
        HStack(spacing: 1) {
            // Row label (screen name)
            Text(summary.screenName)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(ColorTokens.textPrimary)
                .frame(width: 80, alignment: .leading)
                .padding(.horizontal, Spacing.xs)
                .lineLimit(1)

            // Signal count cells
            ForEach(signalTypes, id: \.rawValue) { type in
                let count = signalCount(for: type, in: summary)
                let cellId = CellIdentifier(
                    screenName: summary.screenName,
                    signalType: type,
                    count: count
                )

                heatmapCell(count: count)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCell == cellId {
                                selectedCell = nil
                            } else {
                                selectedCell = cellId
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Heatmap Cell

    private func heatmapCell(count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor(for: count))

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(count >= 15 ? .white : ColorTokens.textPrimary)
            }
        }
        .frame(width: 44, height: 28)
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: Spacing.sm) {
            Text("Intensity:")
                .font(Typography.caption2)
                .foregroundStyle(ColorTokens.textTertiary)

            HStack(spacing: 2) {
                ForEach([0, 3, 8, 15, 25], id: \.self) { value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cellColor(for: value))
                        .frame(width: 16, height: 10)
                }
            }

            HStack(spacing: Spacing.xs) {
                Text("Low")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)

                Text("High")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: - Tooltip

    private func tooltipView(for cell: CellIdentifier) -> some View {
        HStack(spacing: Spacing.sm) {
            SignalBadge(signalType: cell.signalType)

            VStack(alignment: .leading, spacing: 0) {
                Text(cell.screenName)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text("\(cell.count) signals detected")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer()

            Button(action: { selectedCell = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.sm)
        .background(ColorTokens.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        .transition(.opacity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)

            Text("No signal data available")
                .font(Typography.caption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Private Helpers

    /// Extracts the signal count for a given signal type from a screen summary.
    /// Uses the named count properties on ScreenSignalSummary.
    private func signalCount(for type: SignalType, in summary: ScreenSignalSummary) -> Int {
        switch type {
        case .rageTap:
            return summary.rageTapCount
        case .deadTap:
            return summary.deadTapCount
        case .abandon:
            return summary.abandonCount
        case .latencySpike:
            return summary.latencySpikeCount
        case .errorBurst, .longPressFrustration, .excessiveScroll:
            // These are not broken out individually in ScreenSignalSummary;
            // return 0 as they are not tracked at per-screen granularity.
            return 0
        }
    }

    /// Maps a signal count to a heatmap color on a white -> yellow -> orange -> red gradient.
    private func cellColor(for count: Int) -> Color {
        if count == 0 {
            return ColorTokens.backgroundTertiary
        }

        // Normalize count to 0...1 range (capped at 30 for full red).
        let normalized = min(Double(count) / 30.0, 1.0)

        if normalized < 0.33 {
            // White to Yellow
            let t = normalized / 0.33
            return Color(
                red: 1.0,
                green: 1.0,
                blue: 1.0 - t
            )
        } else if normalized < 0.66 {
            // Yellow to Orange
            let t = (normalized - 0.33) / 0.33
            return Color(
                red: 1.0,
                green: 1.0 - (t * 0.35),
                blue: 0.0
            )
        } else {
            // Orange to Red
            let t = (normalized - 0.66) / 0.34
            return Color(
                red: 1.0,
                green: 0.65 - (t * 0.65),
                blue: 0.0
            )
        }
    }

    /// Returns a short display name for a signal type.
    private func shortName(for type: SignalType) -> String {
        switch type {
        case .rageTap: return "Rage"
        case .deadTap: return "Dead"
        case .abandon: return "Aband."
        case .errorBurst: return "Error"
        case .longPressFrustration: return "Long\nPress"
        case .excessiveScroll: return "Scroll"
        case .latencySpike: return "Latency"
        }
    }
}

// MARK: - Cell Identifier

/// Identifies a specific cell in the heatmap grid for tooltip display.
private struct CellIdentifier: Equatable {
    let screenName: String
    let signalType: SignalType
    let count: Int
}

// MARK: - Preview

#if DEBUG
#Preview("Heatmap Grid") {
    let sampleData: [ScreenSignalSummary] = [
        ScreenSignalSummary(
            screenName: "TaskList",
            rageTapCount: 12, deadTapCount: 25, abandonCount: 3,
            latencySpikeCount: 8, totalSignals: 48,
            severityBreakdown: ["high": 10, "medium": 20, "low": 18]
        ),
        ScreenSignalSummary(
            screenName: "TaskDetail",
            rageTapCount: 5, deadTapCount: 2, abandonCount: 18,
            latencySpikeCount: 1, totalSignals: 26,
            severityBreakdown: ["high": 5, "medium": 12, "low": 9]
        ),
        ScreenSignalSummary(
            screenName: "Projects",
            rageTapCount: 0, deadTapCount: 7, abandonCount: 0,
            latencySpikeCount: 15, totalSignals: 22,
            severityBreakdown: ["high": 3, "medium": 10, "low": 9]
        ),
    ]

    ScrollView {
        HeatmapGrid(
            data: sampleData,
            signalTypes: [.rageTap, .deadTap, .abandon, .latencySpike]
        )
        .padding()
    }
    .background(ColorTokens.backgroundSecondary)
}
#endif
