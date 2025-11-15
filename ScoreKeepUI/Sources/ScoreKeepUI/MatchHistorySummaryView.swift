//
//  MatchHistorySummaryView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-03.
//

import SwiftUI
import SwiftData
import ScoreKeepCore

public struct MatchHistorySummaryView: View {
    var match: Match
    
    public init(match: Match) {
        self.match = match
    }
    
    public var body: some View {
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

public struct MatchHistoryDetailDateView: View {
    public var match: Match
    
    public init(match: Match) {
        self.match = match
    }
    
    private let dateFormatter = Date.FormatStyle(
        date: .abbreviated,
        time: .none
    )
    
    public var body: some View {
        Text(
            (match.endedAt ?? match.startedAt).formatted(dateFormatter)
        )
    }
}

public struct MatchHistoryDetailDurationView: View {
    var match: Match
    
    public init(match: Match) {
        self.match = match
    }
    
    private var startedAt: Date { match.startedAt }
    private var endedAt: Date { match.endedAt ?? match.startedAt }
    
    public var body: some View {
        Text(startedAt...endedAt)
            .foregroundStyle(.secondary)
    }
}

public struct MatchHistoryDetailDetailView: View {
    var match: Match
    
    public init(match: Match) {
        self.match = match
    }
    
    public var body: some View {
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
