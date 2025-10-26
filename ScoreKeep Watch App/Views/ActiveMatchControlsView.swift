//
//  ActiveMatchControlsView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct ActiveMatchControlsView: View {
    @Environment(Match.self) private var match
    @Environment(WorkoutManager.self) private var workoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ActiveMatchControlsSummaryView()
                
                if match.hasEnded || match.latestGame?.hasWinner == true {
                    if match.hasMoreGames {
                        StartNextGameForActiveMatchButtonView()
                    } else {
                        EndActiveMatchButtonView()
                    }
                }
                
                if workoutManager.workout != nil {
                    ActiveMatchWorkoutSectionView()
                }
                
                ActiveMatchRulesSummaryButtonView()
                
                if match.hasMoreGames || match.latestGame?.hasWinner != true {
                    EndActiveMatchButtonView()
                }
            }
        }
    }
}

struct ActiveMatchRulesSummaryButtonView: View {
    @Environment(Match.self) private var match
    
    private var systemImage: String {
        switch match.sport {
        case .squash: return "figure.squash"
        case .ultimate: return "figure.disc.sports"
        case .volleyball: return "figure.volleyball"
        case .tennis: return "figure.tennis"
        }
    }
    
    private var fallbackName: String {
        switch match.sport {
        case .squash: return "Squash"
        case .ultimate: return "Ultimate frisbee"
        case .volleyball: return "Volleyball"
        case .tennis: return "Tennis"
        }
    }

    var body: some View {
        Button {
            print("TODO: edit settings")
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // TODO: would be nice to have an interface shared between `Match` and `MatchTemplate` that simplified this element...
                MatchRulesDetailView(
                    name: match.template?.name ?? fallbackName,
                    sport: match.sport,
                    scoring: match.scoring,
                    includeImage: true
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background {
                if let template = match.template {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(template.color.color.opacity(0.2))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                }
            }
            .tint(match.template?.color.color ?? .secondary)
        }
        .buttonStyle(.plain)
    }
}

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

struct ActiveMatchControlsSummaryView: View {
    @Environment(Match.self) private var match
    @Environment(WorkoutManager.self) private var workoutManager

    var body: some View {
        VStack(alignment: .leading) {
            MatchSummaryScoreTableView(match: match, layout: .selfPointsInward)
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                TimelineView(.periodic(from: match.startedAt, by: 0.1)) { context in
                    Text(
                        context.date,
                        format: .stopwatch(startingAt: match.startedAt, maxPrecision: .seconds(1)))
                }
            }
            .padding(.horizontal)
            .font(
                .system(.caption2, design: .rounded).monospacedDigit()
                    .lowercaseSmallCaps())
            .foregroundStyle(.secondary)
        }
    }
}

struct ActiveMatchControlsSummaryTeamScoreRowView: View {
    var team: MatchTeam

    @Environment(Match.self) private var match

    private let cornerRadius: CGFloat = 16
    private let innerPadding: CGFloat = 4
    private let outerPadding: CGFloat = 8

    private var backgroundColor: Color {
        team == .us ? .blue : .red
    }

    private var backgroundColorBodyColumn: Color {
        backgroundColor.opacity(0.15)
    }

    private var backgroundColorMainColumn: Color {
        backgroundColor
    }

    private var scoreMinWidth: CGFloat {
        let maximum = match.scoring.setScoring.gameScoring.maximum ?? 10
        return maximum >= 10 ? 38 : 0
    }

    var body: some View {
        GridRow {
            Text(team == .us ? "Us" : "Them")
                .textCase(.uppercase)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(innerPadding)
                .padding([.leading], outerPadding)
                .background(backgroundColorMainColumn)
                .clipShape(.rect(topLeadingRadius: cornerRadius, bottomLeadingRadius: cornerRadius))

            if match.isMultiSet {
                Text(paddedScore(match.setsFor(team)))
                    .foregroundColor(backgroundColor)
                    .monospacedDigit()
                    .padding(innerPadding)
                    .padding([.leading], outerPadding)
                    .background(backgroundColorBodyColumn)
            }

            Text(paddedScore(match.latestSet?.gamesFor(team)))
                .foregroundColor(backgroundColor)
                .monospacedDigit()
                .padding(innerPadding)
                .padding([.leading], match.isMultiSet ? innerPadding : outerPadding)
                .background(backgroundColorBodyColumn)

            Text(paddedScore(match.latestGame?.scoreFor(team)))
                .foregroundColor(backgroundColor)
                .monospacedDigit()
                .padding(innerPadding)
                .padding([.trailing], outerPadding)
                .frame(minWidth: scoreMinWidth, alignment: .center)
                .background(backgroundColorBodyColumn)
                .clipShape(
                    .rect(bottomTrailingRadius: cornerRadius, topTrailingRadius: cornerRadius))
        }
        .font(.title3)
    }

    private func paddedScore(_ score: Int?) -> String {
        guard let score else { return "0" }

        return "\(score)"
    }
}

struct StartNextGameForActiveMatchButtonView: View {
    @Environment(NavigationManager.self) private var navigation
    @Environment(Match.self) private var match

    private var isDisabled: Bool {
        return match.latestGame?.hasWinner == false || !match.hasMoreGames
    }

    private var systemName: String {
        return "\(nextGameNumber).circle"
    }
    
    private var nextGameNumber: Int {
        return (match.latestGame?.number ?? 0) + 1
    }

    var body: some View {
        Button {
            withAnimation(.snappy) {
                match.startGame()
            }
            
            // Without this delay, the second animation causes an instant switch to the new view...
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.snappy) {
                    navigation.activeMatchTab = .main
                }
            }
        } label: {
            Text("Start game \(nextGameNumber)")
        }
        .tint(.green)
        .fontWeight(.medium)
        .disabled(isDisabled)
    }
}

struct EndActiveMatchButtonView: View {
    @Environment(NavigationManager.self) private var navigation
    @Environment(Match.self) private var match
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.modelContext) private var context

    var body: some View {
        Button {
            endMatch()
        } label: {
            Text("End match")
        }
        .tint(match.hasEnded ? .green : .red)
    }
    
    private func endMatch() {
        workoutManager.end()
        match.end()
        // TODO
        try? context.save()
        navigation.pop(count: navigation.path.count)
    }
}

#Preview {
    ActiveMatchControlsView()
        .environment(NavigationManager())
        .environment(WorkoutManager())
        .environment(
            Match(
                from: MatchTemplate(
                    .volleyball,
                    name: "Indoor volleyball",
                    scoring: MatchScoringRules(
                        winAt: 5,
                        setScoring: MatchSetScoringRules(
                            winAt: 6,
                            gameScoring: MatchGameScoringRules(
                                winAt: 10
                            )
                        )
                    )
                ),
                sets: [
                    MatchSet(
                        games: [
                            MatchGame(us: 9, them: 2)
                        ]
                    )
                ]
            )
        )
}
