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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self,
            GameRules.self,
            GameSet.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
