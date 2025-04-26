//
//  ScoreKeep_iOS_AppApp.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-03-23.
//

import SwiftUI
import SwiftData

@main
struct ScoreKeepiOSApp: App {
    private let sharedModelContainer = MatchModelContainer().sharedModelContainer()

    var body: some Scene {
        WindowGroup {
            StartView()
        }
        .modelContainer(sharedModelContainer)
    }
}
