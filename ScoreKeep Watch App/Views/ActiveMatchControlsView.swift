//
//  ActiveMatchControlsView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct ActiveMatchControlsView: View {
    @Environment(Match.self) private var match

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ActiveMatchControlsSummaryView()
                
                VStack(spacing: 8) {
                    HStack {
                        StartNextGameForActiveMatchButtonView()

                        PauseActiveMatchButtonView()
                    }
                    
                    HStack {
                        UpdateSettingsForActiveMatchButtonView()
                        
                        EndActiveMatchButtonView()
                    }
                }
            }
        }
    }
}

struct ActiveMatchControlsSummaryView: View {
    @Environment(Match.self) private var match

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 2) {
            ActiveMatchControlsSummaryTeamScoreRowView(team: .them)
            ActiveMatchControlsSummaryTeamScoreRowView(team: .us)
        }
        .frame(maxWidth: .infinity)
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
        match.scoring.setScoring.gameScoring.maximumScore >= 10 ? 38 : 0
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
                .clipShape(.rect(bottomTrailingRadius: cornerRadius, topTrailingRadius: cornerRadius))
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
    
    var isDisabled : Bool {
        return match.latestGame?.hasWinner == false || !match.hasMoreGames
    }
    
    var body: some View {
        let isDisabled = isDisabled
        
        VStack {
            Button {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    match.startGame()
                }
                
                withAnimation(.snappy) {
                    navigation.activeMatchTab = .main
                }
                
            } label: {
                Image(systemName: "\([(match.latestGame?.number ?? 0) + 1, match.scoring.setScoring.gamesMaximum].min()!).circle")
                    .foregroundStyle(isDisabled ? .tertiary : .primary)
            }
            .tint(.green)
            .font(.title2)
            .fontWeight(.medium)
            .disabled(isDisabled)

            Text("Next game")
                .foregroundStyle(isDisabled ? .tertiary : .primary)
        }
    }
}

struct UpdateSettingsForActiveMatchButtonView: View {
    @Environment(NavigationManager.self) private var navigation
    @Environment(Match.self) private var match
    
    var body: some View {
        let isDisabled = match.hasEnded
        
        VStack {
            Button {
                print("TODO update settings")
            } label: {
                Image(systemName: "gearshape")
            }
            .font(.title2)
            .fontWeight(.medium)
            .disabled(isDisabled)
            
            Text("Settings")
                .foregroundStyle(isDisabled ? .gray : .primary)
        }
    }
}

struct EndActiveMatchButtonView: View {
    @Environment(NavigationManager.self) private var navigation
    @Environment(Match.self) private var match
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack {
            Button {
                match.end()
                // TODO
                try? context.save()
                navigation.pop(count: navigation.path.count)
                workoutManager.end()
            } label: {
                Image(systemName: "xmark")
            }
            .tint(.red)
            .font(.title2)
            .fontWeight(.medium)

            Text("End")
        }
    }
}

struct PauseActiveMatchButtonView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    
    private var isRunning: Bool {
        workoutManager.running
    }
    
    private var hasActiveWorkout: Bool {
        workoutManager.session != nil
    }
    
    var body: some View {
        VStack {
            Button {
                // TODO
                withAnimation(.none) {
                    if isRunning {
                        workoutManager.pause()
                    } else {
                        workoutManager.resume()
                    }
                }
            } label: {
                Image(systemName: isRunning || !hasActiveWorkout ? "pause" : "arrow.clockwise")
                    .foregroundStyle(hasActiveWorkout ? .primary : .tertiary)
            }
            .tint(.yellow)
            .font(.title2)
            .fontWeight(.medium)
            .disabled(!hasActiveWorkout)

            Text(isRunning ? "Pause" : "Resume")
                .foregroundStyle(hasActiveWorkout ? .primary : .tertiary)
        }
    }
}

#Preview {
    ActiveMatchControlsView()
        .environment(NavigationManager())
        .environment(
            Match(
                .volleyball,
                scoring: MatchScoringRules(
                    setsWinAt: 5,
                    setScoring: MatchSetScoringRules(
                        gamesWinAt: 5,
                        gameScoring: MatchGameScoringRules(
                            winScore: 10
                        )
                    )
                ),
                sets: [
                    MatchSet(
                        games: [
                            MatchGame(us: 10, them: 2)
                        ]
                    )
                ]
            )
        )
}
