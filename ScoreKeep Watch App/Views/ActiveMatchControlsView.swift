//
//  ActiveMatchControlsView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftData
import SwiftUI
import ScoreKeepCore
import ScoreKeepUI

enum ActiveMatchNextAction {
    case nextGame(number: Int)
    case endMatch

    init?(match: ScoreKeepMatch) {
        guard match.hasEnded || match.latestGame?.hasWinner == true else { return nil }

        if match.hasMoreGames {
            self = .nextGame(number: (match.latestGame?.number ?? 0) + 1)
        } else {
            self = .endMatch
        }
    }
}

struct ActiveMatchControlsView: View {
    @Environment(ScoreKeepMatch.self) private var match
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(NavigationManager.self) private var navigation
    @Environment(\.modelContext) private var context

    @State private var showEndMatchConfirmation: Bool = false

    private var canStartNextGame: Bool {
        match.latestGame?.hasWinner == true && match.hasMoreGames
    }

    private var nextGameNumber: Int {
        (match.latestGame?.number ?? 0) + 1
    }

    /// True at the natural end of the match — either the model has already
    /// flagged it as ended, or the deciding game has a winner and no more games
    /// can be played. We treat both states identically: green End button, no
    /// confirmation prompt.
    private var isAtNaturalEnd: Bool {
        if match.hasEnded { return true }
        return match.latestGame?.hasWinner == true && !match.hasMoreGames
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ActiveMatchControlsScoreHeaderView(match: match)

                ActiveMatchControlsScoreTableView(match: match)
                    .padding(.top, 2)

                ActiveMatchControlsTimingView(match: match)
                    .padding(.top, 4)

                ActiveMatchControlsActionsRow(
                    canStartNextGame: canStartNextGame,
                    nextGameNumber: nextGameNumber,
                    isAtNaturalEnd: isAtNaturalEnd,
                    onStartNextGame: startNextGame,
                    onEndMatch: handleEndMatchTapped
                )
                .padding(.top, 12)

                if workoutManager.workout != nil {
                    ActiveMatchWorkoutSectionView()
                        .padding(.top, 16)
                }

                ActiveMatchControlsRulesView(match: match)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .confirmationDialog(
            "End match?",
            isPresented: $showEndMatchConfirmation,
            titleVisibility: .visible
        ) {
            Button("End match", role: .destructive) {
                endMatch()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This match isn't over yet. Ending now will save the current scores.")
        }
    }

    private func startNextGame() {
        withAnimation(.snappy) {
            match.startGame()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.snappy) {
                navigation.activeMatchTab = .main
            }
        }
    }

    private func handleEndMatchTapped() {
        if isAtNaturalEnd {
            endMatch()
        } else {
            showEndMatchConfirmation = true
        }
    }

    private func endMatch() {
        endActiveMatch(
            match: match,
            workoutManager: workoutManager,
            context: context,
            navigation: navigation
        )
    }
}

// MARK: - Score header

/// What the big numbers and team status icon should reflect.
/// - `currentGame` (default): the active match's latest game — points label,
///   winner check during the dead time between games, ball during live play.
/// - `matchOutcome`: history mode. Treat the match as over and pick the
///   "headline" score that the match was decided at (sets / games / points)
///   plus only a winner indicator.
enum ActiveMatchControlsScoreSummaryStyle {
    case currentGame
    case matchOutcome
}

struct ActiveMatchControlsScoreHeaderView: View {
    var match: ScoreKeepMatch
    var summaryStyle: ActiveMatchControlsScoreSummaryStyle = .currentGame

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                teamPill(.us)
                scoreText(.us)
                teamStatusIcon(.us)
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                teamStatusIcon(.them)
                scoreText(.them)
                teamPill(.them)
            }
        }
    }

    @ViewBuilder
    private func teamPill(_ team: ScoreKeepTeam) -> some View {
        let participant = match.participant(for: team)
        let color = participant.resolvedColor.color

        Text(participant.resolvedShortLabel)
            .font(.system(size: 9, weight: .heavy))
            .textCase(.uppercase)
            .foregroundStyle(.black)
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
            .fixedSize()
    }

    @ViewBuilder
    private func teamStatusIcon(_ team: ScoreKeepTeam) -> some View {
        let color = match.participant(for: team).resolvedColor.color

        switch summaryStyle {
        case .currentGame:
            let game = match.latestGame
            if let game, game.winner == team {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale.combined(with: .opacity))
            } else if let game, !game.hasEnded, game.servingTeam == team {
                Image(systemName: match.sport.ballIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale.combined(with: .opacity))
            }
        case .matchOutcome:
            if match.winner == team {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
            }
        }
    }

    private func headlineScore(
        for team: ScoreKeepTeam
    ) -> (label: String, transitionValue: Double) {
        switch summaryStyle {
        case .currentGame:
            let game = match.latestGame
            let normalizedScore = game.map { match.sport.normalizedScoreFor(team, game: $0) } ?? 0
            let label = game.map { match.sport.normalizedScoreLabelFor(team, game: $0) } ?? "0"
            let transition = label == "Ad" ? Double(normalizedScore) + 5 : Double(normalizedScore)
            return (label, transition)
        case .matchOutcome:
            if match.isMultiSet {
                let count = match.setsFor(team)
                return (String(count), Double(count))
            }
            if let latestSet = match.latestSet, latestSet.isMultiGame {
                let count = latestSet.gamesFor(team)
                return (String(count), Double(count))
            }
            if let latestGame = match.latestGame {
                let normalizedScore = match.sport.normalizedScoreFor(team, game: latestGame)
                let label = match.sport.normalizedScoreLabelFor(team, game: latestGame)
                let transition = label == "Ad" ? Double(normalizedScore) + 5 : Double(normalizedScore)
                return (label, transition)
            }
            return ("0", 0)
        }
    }

    @ViewBuilder
    private func scoreText(_ team: ScoreKeepTeam) -> some View {
        let (label, transitionValue) = headlineScore(for: team)
        let color = match.participant(for: team).resolvedColor.color

        Text(label)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: transitionValue))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Subdued score table

struct ActiveMatchControlsScoreTableView: View {
    var match: ScoreKeepMatch

    private let cellWidth: CGFloat = 22
    private let trailingPadding: CGFloat = 8

    /// In a single-set match with a small number of possible games (e.g. squash
    /// best-of-3 or best-of-5), show each game's score as its own column instead
    /// of a single "games won" summary. Tennis sets, volleyball "first to N"
    /// single-game sets, and other long-format matches keep the summary cell.
    private var perGameSingleSetMax: Int { 5 }

    private enum TableMode {
        case multiSetPerSet
        case singleSetPerGame
        case singleSetSummary
    }

    private var mode: TableMode {
        if match.isMultiSet { return .multiSetPerSet }
        if let max = match.rules.setRules.maximumGameCount,
           max >= 2, max <= perGameSingleSetMax {
            return .singleSetPerGame
        }
        return .singleSetSummary
    }

    private var columns: [TableColumn] {
        switch mode {
        case .multiSetPerSet:
            return match.sets.map { set in
                let isCurrent = set.isLatestInMatch && !set.hasEnded
                // Hide tiebreak superscript on the current set — its score is
                // already in the big header above and would just duplicate.
                return TableColumn(
                    id: set.number,
                    isCurrent: isCurrent,
                    us: set.gamesUs,
                    them: set.gamesThem,
                    tiebreakUs: isCurrent ? nil : set.tiebreakGame?.scoreUs,
                    tiebreakThem: isCurrent ? nil : set.tiebreakGame?.scoreThem
                )
            }
        case .singleSetPerGame:
            // Show only finished games — the current game's score is already in
            // the big header above, so repeating it here would be noise.
            let games = match.latestSet?.games.filter { $0.hasEnded } ?? []
            return games.map { game in
                TableColumn(
                    id: game.number,
                    isCurrent: false,
                    us: game.scoreUs,
                    them: game.scoreThem,
                    tiebreakUs: nil,
                    tiebreakThem: nil
                )
            }
        case .singleSetSummary:
            return []
        }
    }

    var body: some View {
        let columns = self.columns

        VStack(spacing: 2) {
            if !columns.isEmpty {
                headerRow(columns: columns)
            }

            VStack(spacing: 0) {
                row(team: .us, columns: columns)
                rowDivider
                row(team: .them, columns: columns)
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    private func headerRow(columns: [TableColumn]) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    Text("\(column.id)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(width: cellWidth)
                }
            }
            .padding(.trailing, trailingPadding)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 0.5)
    }

    @ViewBuilder
    private func row(team: ScoreKeepTeam, columns: [TableColumn]) -> some View {
        let isUs = team == .us
        let participant = match.participant(for: team)

        HStack(spacing: 0) {
            teamLabel(participant: participant)
                .frame(maxWidth: .infinity, alignment: .leading)

            scoresArea(team: team, isUs: isUs, columns: columns)
                .padding(.trailing, trailingPadding)
        }
    }

    @ViewBuilder
    private func scoresArea(
        team: ScoreKeepTeam,
        isUs: Bool,
        columns: [TableColumn]
    ) -> some View {
        if columns.isEmpty {
            let games = match.latestSet?.gamesFor(team) ?? 0
            cell(value: games, tiebreak: nil, isCurrent: false)
        } else {
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    cell(
                        value: isUs ? column.us : column.them,
                        tiebreak: isUs ? column.tiebreakUs : column.tiebreakThem,
                        isCurrent: column.isCurrent
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func teamLabel(participant: ScoreKeepMatchParticipant) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(participant.resolvedColor.color)
                .frame(width: 7, height: 7)
            Text(participant.resolvedName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, 8)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func cell(value: Int, tiebreak: Int?, isCurrent: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.system(size: 14, weight: isCurrent ? .semibold : .regular, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
            if let tiebreak {
                Text("\(tiebreak)")
                    .font(.system(size: 8, weight: .regular, design: .rounded))
                    .baselineOffset(4)
                    .monospacedDigit()
            }
        }
        .frame(width: cellWidth)
    }
}

private struct TableColumn: Identifiable {
    let id: Int
    let isCurrent: Bool
    let us: Int
    let them: Int
    let tiebreakUs: Int?
    let tiebreakThem: Int?
}

// MARK: - Timing row

struct ActiveMatchControlsTimingView: View {
    var match: ScoreKeepMatch

    var body: some View {
        // Read latestGame inside body so observation tracking re-fires when a new
        // game is started (otherwise the parent re-renders but the subview's
        // computed-property reads may not re-track the new latestGame).
        let game = match.latestGame
        let gameNumber = game?.number ?? 1
        let gameStart = game?.startedAt ?? match.startedAt

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            HStack(spacing: 3) {
                Text("Game \(gameNumber)")
                TimelineView(.periodic(from: gameStart, by: 1)) { context in
                    Text(
                        context.date,
                        format: .stopwatch(startingAt: gameStart, maxPrecision: .seconds(1))
                    )
                }
            }
            .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                Text("Match")
                TimelineView(.periodic(from: match.startedAt, by: 1)) { context in
                    Text(
                        context.date,
                        format: .stopwatch(startingAt: match.startedAt, maxPrecision: .seconds(1))
                    )
                }
            }
            .lineLimit(1)
        }
        .font(.system(size: 10, weight: .regular, design: .rounded).monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }
}

// MARK: - Actions row (2-up)

struct ActiveMatchControlsActionsRow: View {
    var canStartNextGame: Bool
    var nextGameNumber: Int
    var isAtNaturalEnd: Bool
    var onStartNextGame: () -> Void
    var onEndMatch: () -> Void

    private var endColor: Color { isAtNaturalEnd ? .green : .red }

    var body: some View {
        HStack(spacing: 8) {
            actionButton(
                icon: "play.fill",
                label: "Game \(nextGameNumber)",
                color: .green,
                isEnabled: canStartNextGame,
                action: onStartNextGame
            )

            actionButton(
                icon: "flag.checkered",
                label: "End",
                color: endColor,
                isEnabled: true,
                action: onEndMatch
            )
        }
    }

    @ViewBuilder
    private func actionButton(
        icon: String,
        label: String,
        color: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let backgroundColor: Color = isEnabled ? color : Color(white: 0.32)
        let textColor: Color = isEnabled ? .black : Color.white.opacity(0.75)

        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Capsule().fill(backgroundColor))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Workout section

struct ActiveMatchWorkoutSectionView: View {
    @Environment(WorkoutManager.self) private var workoutManager

    private var isRunning: Bool {
        workoutManager.running
    }

    private var hasActiveWorkout: Bool {
        workoutManager.session != nil
    }

    private var buttonIcon: String {
        return !hasActiveWorkout || isRunning ? "pause" : "arrow.clockwise"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)

                HStack(spacing: 2) {
                    if let heartRate = workoutManager.workout?.heartRate {
                        Text(heartRate, format: .number.precision(.fractionLength(0)))
                    } else {
                        Text("–")
                    }

                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Button {
                withAnimation(.none) {
                    if isRunning {
                        workoutManager.pause()
                    } else {
                        workoutManager.resume()
                    }
                }
            } label: {
                Image(systemName: buttonIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .fontWeight(.bold)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.primary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!hasActiveWorkout)
            .fixedSize()
        }
        .padding(12)
        .background(.quaternary)
        .cornerRadius(12)
    }
}

// MARK: - Subdued rules

struct ActiveMatchControlsRulesView: View {
    var match: ScoreKeepMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rules")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Label(match.label, systemImage: match.sport.figureIcon)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)

                let primary = match.rules.primaryLabel
                let secondary = match.rules.secondaryLabel

                if !primary.isEmpty {
                    Text(primary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if match.sport != .tennis && !secondary.isEmpty {
                    Text(secondary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// MARK: - Shared end-match helper

func endActiveMatch(
    match: ScoreKeepMatch,
    workoutManager: WorkoutManager,
    context: ModelContext,
    navigation: NavigationManager
) {
    workoutManager.end()
    match.end()
    // TODO
    try? context.save()
    navigation.pop(count: navigation.path.count)
}

#Preview("In progress, multi-set") {
    ActiveMatchControlsView()
        .environment(NavigationManager())
        .environment(WorkoutManager())
        .environment(
            ScoreKeepMatch(
                from: ScoreKeepMatchTemplate(
                    .tennis,
                    name: "Tennis",
                    rules: ScoreKeepMatchRules(
                        winAt: 2,
                        setRules: ScoreKeepSetRules(
                            winAt: 6,
                            winBy: 2,
                            maximum: 7,
                            gameRules: ScoreKeepGameRules(winAt: 4, winBy: 2)
                        )
                    )
                ),
                sets: [
                    ScoreKeepSet(
                        number: 1,
                        games: [
                            ScoreKeepGame(us: 4, them: 2, endedAt: .now.advanced(by: -200)),
                            ScoreKeepGame(us: 4, them: 1, endedAt: .now.advanced(by: -150))
                        ],
                        endedAt: .now.advanced(by: -150)
                    ),
                    ScoreKeepSet(
                        number: 2,
                        games: [
                            ScoreKeepGame(us: 1, them: 4, endedAt: .now.advanced(by: -80)),
                            ScoreKeepGame(us: 2, them: 1)
                        ]
                    )
                ]
            )
        )
}

#Preview("Game over, single-set") {
    ActiveMatchControlsView()
        .environment(NavigationManager())
        .environment(WorkoutManager())
        .environment(
            ScoreKeepMatch(
                from: ScoreKeepMatchTemplate(
                    .volleyball,
                    name: "Indoor volleyball",
                    rules: ScoreKeepMatchRules(
                        winAt: 5,
                        setRules: ScoreKeepSetRules(
                            winAt: 6,
                            gameRules: ScoreKeepGameRules(winAt: 10)
                        )
                    )
                ),
                sets: [
                    ScoreKeepSet(
                        games: [
                            ScoreKeepGame(us: 10, them: 7, endedAt: .now.advanced(by: -30))
                        ]
                    )
                ]
            )
        )
}
