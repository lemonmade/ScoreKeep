//
//  GameScoreKeepView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct GameScoreKeepView: View {
    @Environment(GameScore.self) private var game
    
    var body: some View {
        VStack {
            Button("Team 0: \(game.latestSet!.score0)") {
                game.scoreTeam0()
            }
            .disabled(game.latestSet!.isFinished)
            
            Button("Team 1: \(game.latestSet!.score1)") {
                game.scoreTeam1()
            }
            .disabled(game.latestSet!.isFinished)
        }
    }
}

#Preview {
    GameScoreKeepView()
        .environment(
            GameScore(
                ruleset: GameScoreRuleset(winScore: 10),
                sets: [GameSetScore()]
            )
        )
}
