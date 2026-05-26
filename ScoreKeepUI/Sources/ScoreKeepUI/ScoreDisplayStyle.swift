//
//  ScoreDisplayStyle.swift
//  ScoreKeepUI
//

import SwiftUI

public enum ScoreDisplayStyle: String, CaseIterable, Identifiable, Sendable {
    case rounded
    case standard
    case scoreboard
    case sevenSegment
    case fourteenSegment
    case flipboard
    case nixie
    case odometer
    case pixel

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .standard: "Standard"
        case .scoreboard: "Scoreboard"
        case .sevenSegment: "7-Segment"
        case .fourteenSegment: "14-Segment"
        case .flipboard: "Flipboard"
        case .nixie: "Nixie Tube"
        case .odometer: "Odometer"
        case .pixel: "Pixel"
        }
    }

    /// Whether this style takes over the entire score-button area (LED panel,
    /// segment displays) versus being rendered inline next to the team chip.
    public var isPanel: Bool {
        switch self {
        case .rounded, .standard: return false
        case .scoreboard, .sevenSegment, .fourteenSegment, .flipboard, .nixie, .odometer, .pixel: return true
        }
    }

    public static let storageKey = "scoreDisplayStyle"
    public static let `default`: ScoreDisplayStyle = .standard
}

/// Brand-level color tokens used across the apps.
public enum ScoreKeepBrand {
    /// Purple matching the app icon background. Used by Settings previews and
    /// other neutral surfaces where we want the app's identity color rather
    /// than a team-specific color.
    public static let iconPurple = Color(red: 0.30, green: 0.21, blue: 0.92)
}

/// Renders a score number in the user's selected display style. Used wherever
/// the score is shown inline alongside other content (e.g. Settings preview).
/// The active match button bypasses this wrapper for the scoreboard style and
/// uses `LEDScoreNumberView` directly with `.fillContainer` layout so it can
/// span the full button area.
public struct GameScoreNumberView: View {
    let label: String
    let transitionValue: Double
    let color: Color
    var styleOverride: ScoreDisplayStyle? = nil

    @AppStorage(ScoreDisplayStyle.storageKey)
    private var rawStyle: String = ScoreDisplayStyle.default.rawValue

    public init(
        label: String,
        transitionValue: Double,
        color: Color,
        styleOverride: ScoreDisplayStyle? = nil
    ) {
        self.label = label
        self.transitionValue = transitionValue
        self.color = color
        self.styleOverride = styleOverride
    }

    private var style: ScoreDisplayStyle {
        if let styleOverride { return styleOverride }
        return ScoreDisplayStyle(rawValue: rawStyle) ?? .default
    }

    public var body: some View {
        switch style {
        case .rounded:
            numericView(design: .rounded)
        case .standard:
            numericView(design: .default)
        case .scoreboard:
            LEDScoreNumberView(label: label, color: color, layout: .compact)
        case .sevenSegment:
            SegmentScoreNumberView(label: label, color: color, variant: .seven, layout: .compact)
        case .fourteenSegment:
            SegmentScoreNumberView(label: label, color: color, variant: .fourteen, layout: .compact)
        case .flipboard:
            FlipboardScoreNumberView(label: label, color: color, layout: .compact)
        case .nixie:
            NixieScoreNumberView(label: label, color: color, layout: .compact)
        case .odometer:
            OdometerScoreNumberView(label: label, color: color, layout: .compact)
        case .pixel:
            PixelArcadeScoreNumberView(label: label, color: color, layout: .compact)
        }
    }

    @ViewBuilder
    private func numericView(design: Font.Design) -> some View {
        Text(label)
            .font(.system(size: 60, weight: .bold))
            .contentTransition(.numericText(value: transitionValue))
            .fontDesign(design)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .monospacedDigit()
    }
}

// MARK: - Previews

private struct ProgressiveScorePreview: View {
    let style: ScoreDisplayStyle
    let color: Color
    var maxValue: Int = 23
    var stepInterval: Duration = .milliseconds(1100)

    @State private var value: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            Text(style.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Spacer(minLength: 0)
                GameScoreNumberView(
                    label: "\(value)",
                    transitionValue: Double(value),
                    color: color,
                    styleOverride: style
                )
                .foregroundStyle(color)
                Spacer(minLength: 0)
            }
            .frame(height: 90)
            .background(color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: stepInterval)
                if Task.isCancelled { return }
                withAnimation { value = (value + 1) % (maxValue + 1) }
            }
        }
    }
}

#Preview("Rounded — counting up") {
    ProgressiveScorePreview(style: .rounded, color: ScoreKeepBrand.iconPurple)
        .padding(8)
}

#Preview("Standard — counting up") {
    ProgressiveScorePreview(style: .standard, color: ScoreKeepBrand.iconPurple)
        .padding(8)
}

#Preview("Scoreboard — counting up") {
    ProgressiveScorePreview(style: .scoreboard, color: ScoreKeepBrand.iconPurple)
        .padding(8)
}

#Preview("All styles — counting up") {
    ScrollView {
        VStack(spacing: 12) {
            ProgressiveScorePreview(style: .rounded, color: ScoreKeepBrand.iconPurple)
            ProgressiveScorePreview(style: .standard, color: ScoreKeepBrand.iconPurple)
            ProgressiveScorePreview(style: .scoreboard, color: ScoreKeepBrand.iconPurple)
        }
        .padding(8)
    }
}
