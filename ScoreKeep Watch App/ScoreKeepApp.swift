//
//  ScoreKeepApp.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftData
import SwiftUI

@main
struct ScoreKeep_Watch_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Match.self,
            MatchSet.self,
            MatchGame.self,
            MatchTemplate.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            StartView()
                .modelContainer(sharedModelContainer)
        }
    }
}
