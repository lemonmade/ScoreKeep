//
//  HistoryMatchDetailView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-03.
//

import SwiftUI

struct HistoryMatchDetailView: View {
    var match: Match
    
    var body: some View {
        List {
            Section {
                MatchSummaryScoreTableView(match: match)
                    .listStyle(.plain)
                    .listRowInsets(.none)
                    .listRowBackground(Color.clear)
                    .padding(0)
            }
            
            ForEach(match.sets) { set in
                Section {
                    ForEach(set.games) { game in
                        HistoryMatchDetailGameView(match: match, game: game)
                    }
                } header: {
                    if match.isMultiSet {
                        Text("Set \(set.number)")
                    }
                }
            }
        }
        .listSectionSpacing(.compact)
    }
}

struct HistoryMatchDetailGameView: View {
    var match: Match
    var game: MatchGame
    
    var body: some View {
        DisclosureGroup {
            VStack {
                MatchGameChartView(game: game)
                    .padding(16)
                    .background(.secondary.opacity(0.05))
                    .cornerRadius(8)
            }
        } label: {
            HStack(spacing: 12) {
                MatchTotalScoreSummaryView(game: game)
                
                VStack(alignment: .leading) {
                    Text("Game \(game.number)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let endedAt = game.endedAt {
                        Text(game.startedAt...endedAt)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                MatchGameChartSparklineView(game: game)
            }
        }
    }
}

