//
//  ScoreKeepApp.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI
import SwiftData

@main
struct ScoreKeep_Watch_AppApp: App {
    @StateObject var workoutManager = WorkoutManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameScore.self,
            GameScoreRuleset.self,
            GameSetScore.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: false)

        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView) {
                SummaryView()
            }
            .environmentObject(workoutManager)
            .modelContainer(sharedModelContainer)
        }
    }
}
