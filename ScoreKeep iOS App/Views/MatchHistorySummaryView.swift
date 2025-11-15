//
//  MatchHistorySummaryView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-03.
//

import SwiftUI
import SwiftData

struct MatchHistorySummaryView: View {
    var match: Match
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            MatchTotalScoreSummaryView(match: match)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: match.sport.figureIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    
                    Text(match.label).font(.headline)
                }
                .foregroundStyle(.primary)
                    
                MatchHistoryDetailDateView(match: match)
                
                MatchHistoryDetailDurationView(match: match)
            }
        }
    }
}

struct MatchHistoryDetailDateView: View {
    var match: Match
    
    private let dateFormatter = Date.FormatStyle(
        date: .abbreviated,
        time: .none
    )
    
    var body: some View {
        Text(
            (match.endedAt ?? match.startedAt).formatted(dateFormatter)
        )
    }
}

struct MatchHistoryDetailDurationView: View {
    var match: Match
    
    private var startedAt: Date { match.startedAt }
    private var endedAt: Date { match.endedAt ?? match.startedAt }
    
    var body: some View {
        Text(startedAt...endedAt)
            .foregroundStyle(.secondary)
    }
}

struct MatchHistoryDetailDetailView: View {
    var match: Match
    
    var body: some View {
        if match.isMultiSet || (match.latestSet?.isMultiGame ?? true) {
            if let scoreSummaryString = match.scoreSummaryString {
                Text(scoreSummaryString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    MatchHistorySummaryView(
        match: Match(
            .volleyball,
            scoring: MatchScoringRules(
                winAt: 5,
                setScoring: MatchSetScoringRules(
                    winAt: 6,
                    gameScoring: MatchGameScoringRules(
                        winAt: 25,
                        winBy: 2
                    )
                )
            ),
            sets: [
                MatchSet(number: 1, games: [
                    MatchGame(number: 1, us: 25, them: 20)
                ])
            ]
        )
    )
}
