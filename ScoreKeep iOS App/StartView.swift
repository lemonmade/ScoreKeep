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
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            CreateMatchView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
        }
    }
}

#Preview {
    StartView()
        .modelContainer(MatchModelContainer().testModelContainer())
}
