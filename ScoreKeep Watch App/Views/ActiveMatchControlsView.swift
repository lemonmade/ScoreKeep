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
                MatchScoreboardHeaderView(match: match, size: .compact)

                MatchScoreboardTableView(match: match, size: .compact)
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
