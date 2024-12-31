//
//  ActiveMatchView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import WatchKit

struct ActiveMatchView: View {
    var template: MatchTemplate
    var markAsUsed: Bool = true
    
    @State private var match: Match? = nil

    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var navigation

    var body: some View {
        ActiveMatchInternalView(match: match)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(navigation.activeMatchTab == .nowPlaying)
            .environment(match)
            .onAppear {
                navigation.activeMatchTab = .main
                
                let match = template.createMatch(markAsUsed: markAsUsed)
                self.match = match

                context.insert(match)

                // TODO
                try? context.save()
            }
    }
}

struct ActiveMatchInternalView: View {
    var match: Match?
    
    var body: some View {
        if let match {
            ActiveMatchTabView(match: match)
        } else {
            EmptyView()
        }
    }
}

struct ActiveMatchTabView: View {
    @Bindable var match: Match
    @Environment(NavigationManager.self) private var navigation
    
    var body: some View {
        @Bindable var navigation = navigation

        TabView(selection: $navigation.activeMatchTab) {
            Tab(value: .controls) {
                ActiveMatchControlsView()
            }

            Tab(value: .main) {
                ActiveMatchMainView()
            }

            Tab(value: .nowPlaying) {
                NowPlayingView()
            }
        }
        .environment(match)
    }
}

#Preview {
    ActiveMatchView(
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
