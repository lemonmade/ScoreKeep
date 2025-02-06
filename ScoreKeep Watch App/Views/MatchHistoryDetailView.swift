//
//  MatchHistoryDetailView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-31.
//

import Foundation
import SwiftUI
import Charts

struct MatchHistoryDetailView: View {
    var match: Match

    var body: some View {
        TabView {
            MatchHistoryDetailMatchView(match: match)
            
            ForEach(match.orderedSets) { set in
                ForEach(set.orderedGames) { game in
                    MatchHistoryDetailGameView(game: game)
                }
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

struct MatchHistoryDetailMatchView: View {
    var match: Match
    
    private let dateFormatter = Date.FormatStyle(
        date: .abbreviated,
        time: .none
    )
    
    var body: some View {
        VStack {
            Text(match.endedAt ?? match.startedAt, format: dateFormatter)
                .font(.headline)
            
            Text(match.startedAt...(match.endedAt ?? match.startedAt))
                .foregroundStyle(.secondary)
            
            MatchTotalScoreSummaryView(match: match)
        }
    }
}
