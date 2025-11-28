//
//  StartView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-16.
//


import SwiftUI
import SwiftData
import ScoreKeepCore
import ScoreKeepUI

struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Match.endedAt, order: .reverse) private var matches: [Match]
    
    private let maxRecentMatches: Int = 5
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: RecentMatchHeaderView(moreLinkVisibility: matches.count > maxRecentMatches ? .visible : .hidden)) {
                    ForEach(matches[0..<maxRecentMatches]) { match in
                        NavigationLink {
                            MatchHistoryDetailView(match: match)
                        } label: {
                            MatchHistorySummaryView(match: match)
                        }
                    }
                }
            }
            .navigationTitle("Start")
        }
    }
}

struct RecentMatchHeaderView: View {
    @Environment(AppNavigation.self) private var navigation
    
    var moreLinkVisibility: Visibility = .visible
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Recent matches")
                .foregroundStyle(.primary)
            
            if moreLinkVisibility != .hidden {
                Button {
                    navigation.tab = .history
                } label: {
                    HStack(spacing: 4) {
                        Text("More")
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
    }
}

#Preview {
    StartView()
        .modelContainer(MatchModelContainer().testModelContainer())
        .environment(AppNavigation())
}
