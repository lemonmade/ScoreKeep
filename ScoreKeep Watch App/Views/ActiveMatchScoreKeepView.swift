//
//  GameScoreKeepView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import ScoreKeepCore

struct ActiveMatchScoreKeepView: View {
    @Environment(ScoreKeepMatch.self) private var match

    var body: some View {
        if match.latestGame != nil {
            ActiveMatchScoreKeepGameView(match: match)
        } else {
            // TODO
            EmptyView()
        }
    }
}

struct ActiveMatchScoreKeepGameView: View {
    var match: ScoreKeepMatch

    private let spacing: CGFloat = 3
    private let outerPadding = EdgeInsets(
        top: 40, leading: 12, bottom: 21, trailing: 12)
    private let compactCenterHeight: CGFloat = 30
    private let expandedCenterHeight: CGFloat = 42
    private let pushAwayDistance: CGFloat = 7
    private let concaveAngle: CGFloat = 18

    @State private var showUndoSheet: Bool = false

    private var isExpanded: Bool {
        match.latestGame?.hasWinner == true || match.hasEnded
    }

    private var centerHeight: CGFloat {
        isExpanded ? expandedCenterHeight : compactCenterHeight
    }

    var body: some View {
        VStack(spacing: spacing) {
            GameScoreTeamButtonView(team: .them, match: match)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: isExpanded ? -pushAwayDistance : 0)
                .rotation3DEffect(
                    .degrees(isExpanded ? concaveAngle : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.6
                )

            ActiveMatchScoreKeepCenterControlsView(
                match: match,
                isExpanded: isExpanded,
                showUndoSheet: $showUndoSheet
            )
            .frame(height: centerHeight)
            .zIndex(1)

            GameScoreTeamButtonView(team: .us, match: match)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: isExpanded ? pushAwayDistance : 0)
                .rotation3DEffect(
                    .degrees(isExpanded ? -concaveAngle : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.6
                )
        }
        .padding(outerPadding)
        .edgesIgnoringSafeArea(.all)
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: isExpanded)
        .sheet(isPresented: $showUndoSheet) {
            ActiveMatchScoreKeepEditView(match: match)
        }
    }
}

struct ActiveMatchScoreKeepCenterControlsView: View {
    var match: ScoreKeepMatch
    var isExpanded: Bool
    @Binding var showUndoSheet: Bool

    @Environment(NavigationManager.self) private var navigation
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.modelContext) private var context

    private var nextAction: ActiveMatchNextAction? {
        ActiveMatchNextAction(match: match)
    }

    var body: some View {
        HStack(spacing: 4) {
            ActiveMatchScoreKeepGameLabelView(match: match, isExpanded: isExpanded)
                .padding(.leading, isExpanded ? 0 : 6)

            Spacer(minLength: 0)

            ActiveMatchScoreKeepUndoButton(
                match: match,
                onLongPress: { showUndoSheet = true }
            )

            if isExpanded, let nextAction {
                ActiveMatchScoreKeepNextActionButton(
                    action: nextAction,
                    onTrigger: handleNextAction
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, isExpanded ? 0 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
                .opacity(isExpanded ? 0 : 0.4)
                .animation(.easeInOut(duration: 0.22), value: isExpanded)
        }
    }

    private func handleNextAction(_ action: ActiveMatchNextAction) {
        switch action {
        case .nextGame:
            match.startGame()
        case .endMatch:
            endActiveMatch(
                match: match,
                workoutManager: workoutManager,
                context: context,
                navigation: navigation
            )
        }
    }
}

struct ActiveMatchScoreKeepGameLabelView: View {
    var match: ScoreKeepMatch
    var isExpanded: Bool

    @State private var extrasVisible: Bool = true
    @State private var pulsingTeam: ScoreKeepTeam? = nil
    @State private var pulseTask: Task<Void, Never>? = nil

    private let extrasOutAnimation: Animation = .easeInOut(duration: 0.16)
    private let chipPromoteAnimation: Animation = .spring(response: 0.42, dampingFraction: 0.7).delay(0.16)
    private let collapseAnimation: Animation = .snappy(duration: 0.22)
    private let pulseInAnimation: Animation = .spring(response: 0.24, dampingFraction: 0.38)
    private let pulseOutAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.72)

    private var label: String {
        let gameNumber = match.latestGame?.number ?? 1
        return "Game \(gameNumber)"
    }

    private var shouldShowSetOverview: Bool {
        (match.latestSet?.games.count ?? 0) > 1
            || match.latestGame?.hasWinner == true
    }

    private var themColor: Color {
        match.participant(for: .them).resolvedColor.color
    }

    private var usColor: Color {
        match.participant(for: .us).resolvedColor.color
    }

    var body: some View {
        let timerStart = match.latestGame?.startedAt ?? match.startedAt

        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 6) {
                if extrasVisible {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .transition(.opacity)
                }

                if shouldShowSetOverview, let set = match.latestSet {
                    setOverviewChip(set: set)
                        .scaleEffect(isExpanded ? 1.35 : 1.0)
                        .animation(
                            isExpanded ? chipPromoteAnimation : collapseAnimation,
                            value: isExpanded
                        )
                }
            }

            if extrasVisible {
                TimelineView(.periodic(from: timerStart, by: 1)) { context in
                    let gameTime = Text(
                        context.date,
                        format: .stopwatch(
                            startingAt: timerStart,
                            maxPrecision: .seconds(1)
                        )
                    )

                    if match.isMultiSet, let set = match.latestSet {
                        gameTime
                            + Text(" (Set \(set.number): ")
                            + Text(
                                context.date,
                                format: .stopwatch(
                                    startingAt: set.startedAt,
                                    maxPrecision: .seconds(1)
                                )
                            )
                            + Text(")")
                    } else {
                        gameTime
                    }
                }
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minHeight: 11)
                .transition(.opacity)
            }
        }
        .onAppear {
            extrasVisible = !isExpanded
        }
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                withAnimation(extrasOutAnimation) {
                    extrasVisible = false
                }
                triggerPulse()
            } else {
                withAnimation(collapseAnimation) {
                    extrasVisible = true
                }
                cancelPulse()
            }
        }
    }

    private func triggerPulse() {
        guard let winner = match.latestGame?.winner else { return }
        pulseTask?.cancel()
        pulseTask = Task {
            try? await Task.sleep(for: .milliseconds(160))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(pulseInAnimation) {
                    pulsingTeam = winner
                }
            }
            try? await Task.sleep(for: .milliseconds(110))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(pulseOutAnimation) {
                    pulsingTeam = nil
                }
            }
        }
    }

    private func cancelPulse() {
        pulseTask?.cancel()
        if pulsingTeam != nil {
            withAnimation(.snappy(duration: 0.2)) {
                pulsingTeam = nil
            }
        }
    }

    @ViewBuilder
    private func setOverviewChip(set: ScoreKeepSet) -> some View {
        let themGames = set.gamesFor(.them)
        let usGames = set.gamesFor(.us)
        let themPulsing = pulsingTeam == .them
        let usPulsing = pulsingTeam == .us
        let winner = match.latestGame?.winner
        let highlighted = pulsingTeam != nil
        let highlightColor: Color = winner == .us ? usColor : themColor

        HStack(spacing: 0) {
            glowDot(color: usColor, pulsing: usPulsing)
            Text("\(usGames)")
                .contentTransition(.numericText(value: Double(usGames)))
                .padding(.leading, 2)
            Text("\(themGames)")
                .contentTransition(.numericText(value: Double(themGames)))
                .padding(.leading, 6)
            glowDot(color: themColor, pulsing: themPulsing)
                .padding(.leading, 2)
        }
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary.opacity(isExpanded ? 1.0 : 0.7))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.primary.opacity(0.12))
                .shadow(
                    color: highlightColor.opacity(highlighted ? 0.5 : 0),
                    radius: highlighted ? 8 : 0
                )
                .opacity(isExpanded ? 0 : 1)
                .animation(.easeInOut(duration: 0.22), value: isExpanded)
        )
    }

    @ViewBuilder
    private func glowDot(color: Color, pulsing: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 5, height: 5)
            .brightness(pulsing ? 0.35 : 0)
            .saturation(pulsing ? 1.4 : 1.0)
            .scaleEffect(pulsing ? 1.35 : 1.0)
            .shadow(color: color.opacity(pulsing ? 1.0 : 0), radius: pulsing ? 2 : 0)
            .shadow(color: color.opacity(pulsing ? 0.6 : 0), radius: pulsing ? 5 : 0)
            .shadow(color: color.opacity(pulsing ? 0.3 : 0), radius: pulsing ? 9 : 0)
    }
}

struct ActiveMatchScoreKeepUndoButton: View {
    var match: ScoreKeepMatch
    var onLongPress: () -> Void

    @State private var longPressTriggered = false

    var body: some View {
        Button {
            if longPressTriggered { return }
            withAnimation { match.undo() }
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.primary.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .disabled(!match.canUndo)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    longPressTriggered = true
                    onLongPress()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        longPressTriggered = false
                    }
                }
        )
        .sensoryFeedback(.selection, trigger: longPressTriggered)
    }
}

struct ActiveMatchScoreKeepNextActionButton: View {
    var action: ActiveMatchNextAction
    var onTrigger: (ActiveMatchNextAction) -> Void

    private var icon: String {
        switch action {
        case .nextGame: "play.fill"
        case .endMatch: "flag.checkered"
        }
    }

    private var label: String {
        switch action {
        case .nextGame: "Next"
        case .endMatch: "End"
        }
    }

    var body: some View {
        Button {
            onTrigger(action)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Capsule().fill(Color.green))
        }
        .buttonStyle(.plain)
    }
}

struct ActiveMatchScoreKeepEditView: View {
    @Environment(\.dismiss) var dismiss

    var match: ScoreKeepMatch

    var body: some View {
        VStack(spacing: 12) {
            Text("Actions")
                .font(.headline)

            Button {
                withAnimation { match.undo() }
                dismiss()
            } label: {
                Label("Undo last point", systemImage: "arrow.uturn.backward")
            }
            .disabled(!match.canUndo)

            Button {
                withAnimation { match.redo() }
                dismiss()
            } label: {
                Label("Redo last point", systemImage: "arrow.uturn.forward")
            }
            .disabled(!match.canRedo)
        }
        .padding()
    }
}

struct GameScoreTeamButtonView: View {
    var team: ScoreKeepTeam
    var match: ScoreKeepMatch

    var keyColor: Color {
        match.participant(for: team).resolvedColor.color
    }

    var game: ScoreKeepGame {
        match.latestGame!
    }

    var body: some View {
        Button(action: {
            withAnimation { match.scorePoint(team) }
        }) {
            GameScoreTeamScoreView(match: match, team: team, game: game)
                .foregroundStyle(keyColor)
        }
        .buttonStyle(CustomButtonStyle(keyColor: keyColor))
        .disabled(game.hasEnded)
        .sensoryFeedback(.impact(weight: .medium), trigger: game.scoreFor(team)) { old, new in
            return old != new
        }
    }
}

struct CustomButtonStyle: ButtonStyle {
    var keyColor: Color

    func makeBody(configuration: Configuration) -> some View {
        CustomButtonStyleView(configuration: configuration, keyColor: keyColor)
    }

    struct CustomButtonStyleView: View {
        let configuration: ButtonStyle.Configuration
        let keyColor: Color

        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .background(keyColor.opacity(0.2)) // Background with color opacity
                .cornerRadius(20) // Rounded corners
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: -2)
                        .strokeBorder(.red.opacity(0.0), lineWidth: 2) // Border with transparency
                )
                .opacity(isEnabled ? 1 : 0.6)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Subtle press effect
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

struct GameScoreTeamScoreView: View {
    var match: ScoreKeepMatch
    var team: ScoreKeepTeam
    var game: ScoreKeepGame

    var score: Int {
        game.scoreFor(team)
    }

    var normalizedScore: Int {
        match.sport.normalizedScoreFor(team, game: game)
    }

    var normalizedScoreLabel: String {
        match.sport.normalizedScoreLabelFor(team, game: game)
    }

    /// Value driving `.contentTransition(.numericText)`. We bump the leading
    /// team's value when it shows "Ad" so the transition between Ad and 40
    /// (deuce) animates in both directions — without this, the underlying
    /// normalized score stays 40 across that transition and the digits don't move.
    var transitionValue: Double {
        if normalizedScoreLabel == "Ad" {
            return Double(normalizedScore) + 5
        }
        return Double(normalizedScore)
    }

    var keyColor: Color {
        match.participant(for: team).resolvedColor.color
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                if game.winner == team {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    GameScoreTeamServeIndicatorView(team: team, match: match, game: game)
                }

                Text(match.participant(for: team).resolvedShortLabel)
                    .textCase(.uppercase)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding([.leading, .trailing], 4)
                    .background(keyColor)
                    .cornerRadius(8)
            }

            Spacer()

            HStack(spacing: 0) {
                if score < 10 && match.sport != .tennis {
                    Text("0")
                        .font(.system(size: 60, weight: .bold))
                        .opacity(0.5)
                }
                Text(normalizedScoreLabel)
                    .font(.system(size: 60, weight: .bold))
                    .contentTransition(.numericText(value: transitionValue))
            }
            .fontDesign(.rounded)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .monospacedDigit()
        // Allows the whole button to be pressable
        .contentShape(.rect)
        // Fill the container
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}

struct GameScoreTeamServeIndicatorView: View {
    var team: ScoreKeepTeam
    var match: ScoreKeepMatch
    var game: ScoreKeepGame

    var body: some View {
        if team == game.servingTeam {
            HStack(alignment: .bottom, spacing: 2) {
                Image(systemName: match.sport.ballIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                // If we aren't rotating on every point, "service streaks" are a little odd.
                // I should probably just make this an explicit option
                // instead, though.
                if match.sport.gameServiceRotation == .lastWinner {
                    let streak = game.serveStreakFor(team)
                    if streak > 0 {
                        Text("\(streak)")
                            .font(.system(size: 12,  weight: .semibold, design: .rounded))
                            .frame(height: 12)
                    }
                }
            }
        } else {
            Spacer().frame(height: 20)
        }
    }
}

#Preview {
    ActiveMatchScoreKeepView()
        .environment(NavigationManager())
        .environment(WorkoutManager())
        .environment(
            ScoreKeepMatch(
                .volleyball,
                rules: ScoreKeepMatchRules(
                    winAt: 5,
                    setRules: ScoreKeepSetRules(
                        winAt: 5,
                        gameRules: ScoreKeepGameRules(
                            winAt: 25
                        )
                    )
                )
            )
        )
}
