//
//  ContentView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-03-23.
//

import ScoreKeepCore
import SwiftData
import SwiftUI

enum AppTab {
    case start
    case history
    case settings
}

@Observable
class AppNavigation {
    var tab: AppTab = .start
}

struct AppView: View {
    @Environment(\.modelContext) private var context
    @Bindable var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.tab) {
            StartView()
                .tag(AppTab.start)
                .tabItem {
                    Label("Start", systemImage: "play.square.stack.fill")
                }
            // MatchHistoryListView()
            //     .tag(AppTab.history)
            //     .tabItem {
            //         Label("History", systemImage: "calendar")
            //     }
            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environment(navigation)
    }
}

#Preview {
    AppView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
}
