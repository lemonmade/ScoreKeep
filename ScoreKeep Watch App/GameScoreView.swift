//
//  GameScoreView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-11.
//

import SwiftUI

struct GameScoreView: View {
    @EnvironmentObject var scoreKeeper: GameScoreKeeper

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                GameScoreTeamScoreButtonView(team: 1)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height / 2
                    )

                Divider().padding(.horizontal)

                GameScoreTeamScoreButtonView(team: 0)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height / 2
                    )
            }
            .environmentObject(scoreKeeper.latestSet)
        }
        .ignoresSafeArea(edges: .all)
    }
}

struct GameScoreTeamScoreButtonView: View {
    @EnvironmentObject var scoreKeeper: GameScoreKeeper
    @EnvironmentObject var set: GameSet
    var team: Int
    
    var body: some View {
        Button(action: {
            if team == 0 {
                scoreKeeper.addPointToTeam0()
            } else {
                scoreKeeper.addPointToTeam1()
            }
        }) {
            GameScoreTeamScoreView(score: team == 0 ? set.team0Score : set.team1Score)
                .foregroundStyle(team == 0 ? .blue : .red)
        }
            .buttonStyle(.plain)
            .disabled(set.isFinished)
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
        }
        .monospacedDigit()
        // Fill the container
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Allows the whole button to be pressable
        .contentShape(.rect)

    }
}

#Preview {
    GameScoreView()
        .environmentObject(GameScoreKeeper())
}
