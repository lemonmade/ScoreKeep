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
                Section(header: Text("Set \(set.number)")) {
                    ForEach(set.games) { game in
                        HistoryMatchDetailGameView(match: match, game: game)
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
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                MatchTotalScoreSummaryView(game: game)
                
                VStack(alignment: .leading) {
                    Text("Game \(game.number)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let endedAt = game.endedAt {
                        Text(game.startedAt...endedAt)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            MatchGameChartView(game: game)
        }
    }
}
