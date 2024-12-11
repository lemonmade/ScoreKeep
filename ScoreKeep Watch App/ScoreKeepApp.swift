//
//  ScoreKeepApp.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI

@main
struct ScoreKeep_Watch_AppApp: App {
    @StateObject var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView) {
                SummaryView()
            }
            .environmentObject(workoutManager)
        }
    }
}
