//
//  ScoreDisplayStyle.swift
//  ScoreKeep Watch App
//

import SwiftUI

enum ScoreDisplayStyle: String, CaseIterable, Identifiable {
    case rounded
    case standard
    case scoreboard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .standard: "Standard"
        case .scoreboard: "Scoreboard"
        }
    }

    static let storageKey = "scoreDisplayStyle"
    static let `default`: ScoreDisplayStyle = .standard
}

/// Brand-level color tokens used across the watch app.
enum ScoreKeepBrand {
    /// Purple matching the app icon background. Used by Settings previews and
    /// other neutral surfaces where we want the app's identity color rather
    /// than a team-specific color.
    static let iconPurple = Color(red: 0.30, green: 0.21, blue: 0.92)
}

/// Renders a score number in the user's selected display style. Used wherever
/// the score is shown inline alongside other content (e.g. Settings preview).
/// The active match button bypasses this wrapper for the scoreboard style and
/// uses `LEDScoreNumberView` directly with `.fillContainer` layout so it can
/// span the full button area.
struct GameScoreNumberView: View {
    let label: String
    let transitionValue: Double
    let color: Color
    var styleOverride: ScoreDisplayStyle? = nil

    @AppStorage(ScoreDisplayStyle.storageKey)
    private var rawStyle: String = ScoreDisplayStyle.default.rawValue

    private var style: ScoreDisplayStyle {
        if let styleOverride { return styleOverride }
        return ScoreDisplayStyle(rawValue: rawStyle) ?? .default
    }

    var body: some View {
        switch style {
        case .rounded:
            numericView(design: .rounded)
        case .standard:
            numericView(design: .default)
        case .scoreboard:
            LEDScoreNumberView(label: label, color: color, layout: .compact)
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
