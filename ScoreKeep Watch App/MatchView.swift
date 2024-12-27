//
//  GameView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import WatchKit

struct MatchView: View {
    var template: MatchTemplate
    @State private var match: Match?
    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var gameNavigation

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
    @Environment(NavigationManager.self) private var gameNavigation
    
    var body: some View {
        @Bindable var gameNavigation = gameNavigation

        TabView(selection: $gameNavigation.tab) {
            Tab(value: .controls) {
                MatchControlsView()
            }

            Tab(value: .main) {
                MatchMainView()
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
    MatchView(
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
        .environment(NavigationManager())
}
