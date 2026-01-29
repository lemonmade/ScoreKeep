//
//  ScoreKeep_iOS_AppApp.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-03-23.
//

import SwiftUI
import SwiftData
import ScoreKeepCore

@main
struct ScoreKeepiOSApp: App {
    private let modelContainer = ScoreKeepModelContainer().sharedModelContainer()

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(modelContainer)
    }
}
