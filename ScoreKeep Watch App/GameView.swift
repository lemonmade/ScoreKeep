//
//  GameView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import WatchKit

struct GameView: View {
    var template: MatchTemplate
    @State private var match: Match?
    @Environment(\.modelContext) private var context
    @Environment(GameNavigationManager.self) private var gameNavigation

    var body: some View {
        VStack {
            if let match = match {
                MatchTabView(match: match)
            } else {
                Text("Creating game...")
            }
        }
        .onAppear {
            if match != nil { return }
            
            let newMatch = template.createMatch()
            context.insert(newMatch)
            // TODO
            try? context.save()
            
            gameNavigation.start()
            match = newMatch
        }
    }
}

struct MatchTabView: View {
    @Bindable var match: Match
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
        .environment(match)
    }
}

#Preview {
    GameView(
        template: MatchTemplate(
            .volleyball,
            name: "Indoor volleyball",
            environment: .indoor,
            scoring: MatchScoringRules(
                setsWinAt: 3,
                setScoring: MatchSetScoringRules(
                    gamesWinAt: 6,
                    gameScoring: MatchGameScoringRules(
                        winScore: 25
                    )
                )
            )
        )
    )
        .environment(GameNavigationManager())
}
