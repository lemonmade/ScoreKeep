//
//  GameScoreKeepView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct GameScoreKeepView: View {
    @Environment(Game.self) private var game
    
    var body: some View {
//        VStack {
//            Button("Team 0: \(game.latestSet!.score0)") {
//                game.scoreTeam0()
//            }
//            .disabled(game.latestSet!.isFinished)
//            
//            Button("Team 1: \(game.latestSet!.score1)") {
//                game.scoreTeam1()
//            }
//            .disabled(game.latestSet!.isFinished)
//        }
        GameScoreView(game: game)
    }
}

struct GameScoreView: View {
    var game: Game
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                GameScoreTeamButtonView(team: .us, game: game)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height / 2
                    )

                Divider().padding(.horizontal)

                GameScoreTeamButtonView(team: .them, game: game)
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
    var team: GameTeam
    var game: Game
    
    var body: some View {
        Button(action: {
            game.score(team)
        }) {
            GameScoreTeamScoreView(score: game.latestSet?.scoreFor(team) ?? 0)
                .foregroundStyle(team == .us ? .blue : .red)
        }
            .buttonStyle(.plain)
            .disabled(game.latestSet?.hasEnded ?? false)
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
            Game(
                rules: GameRules(winScore: 10),
                sets: [GameSet()]
            )
        )
}
