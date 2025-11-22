//
//  ContentView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-03-23.
//

import SwiftUI
import SwiftData
import ScoreKeepCore

struct StartView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            MatchHistoryListView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    StartView()
        .modelContainer(MatchModelContainer().testModelContainer())
}
