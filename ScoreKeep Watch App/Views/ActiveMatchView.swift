//
//  ActiveMatchView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import WatchKit
import ScoreKeepCore

struct ActiveMatchView: View {
    var template: ScoreKeepMatchTemplate
    var markAsUsed: Bool = true

    @State private var match: ScoreKeepMatch? = nil

    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var navigation
    @Environment(WorkoutManager.self) private var workoutManager

    var body: some View {
        ActiveMatchInternalView(match: match)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(navigation.activeMatchTab == .nowPlaying)
            .environment(match)
            .onAppear {
                navigation.activeMatchTab = .main

                let match = template.createMatch(markAsUsed: markAsUsed)
                self.match = match

                if (template.warmup != .none) {
                    match.startWarmup()
                } else {
                    match.startGame()
                }

                if template.startWorkout {
                    Task {
                        await workoutManager.startWorkout(match: match)
                    }
                }

                context.insert(match)

                // TODO
                try? context.save()
            }
    }
}

struct ActiveMatchInternalView: View {
    var match: ScoreKeepMatch?

    var body: some View {
        if let match {
            ActiveMatchTabView(match: match)
        } else {
            EmptyView()
        }
    }
}

struct ActiveMatchTabView: View {
    @Bindable var match: ScoreKeepMatch
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
        template: ScoreKeepMatchTemplate(
            .volleyball,
            name: "Indoor volleyball",
            environment: .indoor,
            rules: ScoreKeepMatchRules(
                winAt: 3,
                setRules: ScoreKeepSetRules(
                    winAt: 6,
                    gameRules: ScoreKeepGameRules(
                        winAt: 25
                    )
                )
            )
        )
    )
        .environment(NavigationManager())
        .environment(WorkoutManager())
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
}
