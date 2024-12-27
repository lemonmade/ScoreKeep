//
//  MatchControlsView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct MatchControlsView: View {
    @Environment(Match.self) private var match

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MatchControlsSummaryView()
                
                VStack(spacing: 8) {
                    HStack {
                        MatchControlsNextGameButtonView()

                        MatchControlsUpdateSettingsButtonView()
                    }
                    
                    HStack {
                        GameControlsPauseGameView()
                        
                        GameControlsEndGameView()
                    }
                }
            }
        }
    }
}

struct MatchControlsSummaryView: View {
    @Environment(Match.self) private var match

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 2) {
            MatchControlsSummaryTeamScoreRowView(team: .them)
            MatchControlsSummaryTeamScoreRowView(team: .us)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MatchControlsSummaryTeamScoreRowView: View {
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

struct MatchControlsNextGameButtonView: View {
    @Environment(NavigationManager.self) private var navigation
    @Environment(Match.self) private var match
    
    var isDisabled : Bool {
        return match.latestGame?.hasWinner == false || match.hasMoreGames
    }
    
    var body: some View {
        let isDisabled = isDisabled
        
        VStack {
            Button {
                match.startGame()
                                
                withAnimation {
                    navigation.navigate(to: NavigationLocation.ActiveMatch(match: match, tab: .main), replace: true)
                }
            } label: {
                Image(systemName: "play")
            }
            .tint(.green)
            .font(.title2)
            .disabled(isDisabled)

            Text("Next game")
                .foregroundStyle(isDisabled ? .gray : .primary)
        }
    }
}

struct MatchControlsUpdateSettingsButtonView: View {
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
            .disabled(isDisabled)
            
            Text("Settings")
                .foregroundStyle(isDisabled ? .gray : .primary)
        }
    }
}

struct GameControlsEndGameView: View {
    @Environment(NavigationManager.self) private var navigation
    
    var body: some View {
        VStack {
            Button {
                navigation.pop(count: navigation.path.count)
            } label: {
                Image(systemName: "xmark")
            }
            .tint(.red)
            .font(.title2)

            Text("End")
        }
    }
}

struct GameControlsPauseGameView: View {
    @State private var isRunning = true
    
    var body: some View {
        VStack {
            Button {
                // TODO
                isRunning.toggle()
            } label: {
                Image(systemName: isRunning ? "pause" : "play")
            }
            .tint(.yellow)
            .font(.title2)
            .disabled(true)

            Text(isRunning ? "Pause" : "Resume")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    MatchControlsView()
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
