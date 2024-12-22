//
//  GameScoreKeepView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct GameScoreKeepView: View {
    @Environment(Match.self) private var match
    
    var body: some View {
        if let game = match.latestGame {
            GameScoreView(match: match, game: game)
        } else {
            // TODO
            EmptyView()
        }
    }
}

struct GameScoreView: View {
    var match: Match
    var game: MatchGame
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                GameScoreTeamButtonView(team: .us, match: match, game: game)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height / 2
                    )

                Divider().padding(.horizontal)

                GameScoreTeamButtonView(team: .them, match: match, game: game)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height / 2
                    )
            }
        }
        .ignoresSafeArea(edges: .all)
    }
}

struct GameScoreTeamButtonView: View {
    var team: MatchTeam
    var match: Match
    var game: MatchGame
    
    var body: some View {
        Button(action: {
            match.score(team)
        }) {
            GameScoreTeamScoreView(score: game.scoreFor(team))
                .foregroundStyle(team == .us ? .blue : .red)
        }
            .buttonStyle(.plain)
            .disabled(game.hasEnded)
    }
}

struct GameScoreTeamScoreView: View {
    let score: Int

    var body: some View {
        HStack(spacing: 0) {
            if score < 10 {
                Text("0")
                    .font(.system(size: 80, weight: .bold))
                    .opacity(0.3)
            }
            Text("\(score)")
                .font(.system(size: 80, weight: .bold))
                .contentTransition(.numericText(value: Double(score)))
        }
        .monospacedDigit()
        // Fill the container
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Allows the whole button to be pressable
        .contentShape(.rect)
    }
}

#Preview {
    GameScoreKeepView()
        .environment(
            Match(
                .volleyball,
                scoring: MatchScoringRules(
                    setsWinAt: 5,
                    setScoring: MatchSetScoringRules(
                        gamesWinAt: 5,
                        gameScoring: MatchGameScoringRules(
                            winScore: 25
                        )
                    )
                )
            )
        )
}
