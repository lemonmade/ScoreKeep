//
//  ScoreKeepApp.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftData
import SwiftUI
import ScoreKeepCore

@main
struct ScoreKeepWatchApp: App {
    private let sharedModelContainer = ScoreKeepModelContainer().sharedModelContainer()
    private let workoutManager = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            StartView()
                .modelContainer(sharedModelContainer)
                .environment(workoutManager)
        }
    }
}
