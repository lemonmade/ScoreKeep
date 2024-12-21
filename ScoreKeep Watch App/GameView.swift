//
//  GameView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import WatchKit

struct GameView: View {
    @State private var game: GameScore?
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack {
            if let game = game {
                GameTabView(game: game)
            } else {
                Text("Creating game...")
            }
        }
        .onAppear {
            createAndSaveGame()
        }
    }
    
    private func createAndSaveGame() {
        if game == nil {
            let newGame = GameScore(
                ruleset: GameScoreRuleset(winScore: 25),
                sets: [GameSetScore()],
                startedAt: Date()
            )
            
            game = newGame

            context.insert(newGame)
        }
    }
}

struct GameTabView: View {
    @Bindable var game: GameScore
    @Environment(GameNavigationManager.self) private var gameNavigation
    
    var body: some View {
        @Bindable var gameNavigation = gameNavigation

        TabView(selection: $gameNavigation.tab) {
            Tab(value: .controls) {
                GameControlsView()
            }

            Tab(value: .main) {
                GameMainView()
            }

            Tab(value: .nowPlaying) {
                NowPlayingView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(gameNavigation.tab == .nowPlaying)
        .environment(game)
    }
}

#Preview {
    GameView()
        .environment(GameNavigationManager())
}
