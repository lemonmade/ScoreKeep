//
//  SettingsView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-16.
//

import SwiftUI
import SwiftData
import ScoreKeepCore

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("TODO")
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(MatchModelContainer().testModelContainer())
}
