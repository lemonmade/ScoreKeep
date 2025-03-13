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
    
    private let dateRangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        return formatter
    }()
    
    private var endDate: Date {
        match.endedAt ?? match.startedAt
    }
    
    private var dateRange: ClosedRange<Date> {
        match.startedAt...endDate
    }
    
    private var summary: String {
        let dateRange = self.dateRange
        return "\(dateFormatter.format(endDate))\n\(dateRangeFormatter.string(from: dateRange.lowerBound, to: dateRange.upperBound))\n\(match.scoreSummaryString)"
    }
    
    var body: some View {
        ScrollView {
            VStack {
                MatchSummaryScoreTableView(match: match)
                    .padding()

                Text(endDate, format: dateFormatter)
                    .font(.headline)
                
                Text(dateRange)
                    .foregroundStyle(.secondary)
                
                ShareLink(item: summary) {
                    Label("Summary", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}
