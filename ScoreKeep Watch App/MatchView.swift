//
//  GameView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import WatchKit

struct MatchView: View {
    var match: Match
    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var gameNavigation

    var body: some View {
        MatchTabView(match: match)
            .onAppear {
                context.insert(match)

                // TODO
                try? context.save()
            }
            .environment(match)
    }
}

struct MatchTabView: View {
    @Bindable var match: Match
    @Environment(NavigationManager.self) private var navigation
    
    var body: some View {
        @Bindable var navigation = navigation

        TabView(selection: $navigation.activeMatchTab) {
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
        .navigationBarHidden(navigation.activeMatchTab == .nowPlaying)
        .environment(match)
    }
}

#Preview {
    MatchView(
        match: MatchTemplate(
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
        ).createMatch()
    )
        .environment(NavigationManager())
}
