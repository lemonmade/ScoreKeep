//
//  MatchRulesDetailView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-05-05.
//

import SwiftUI

struct MatchRulesDetailView: View {
    var name: String
    var sport: MatchSport
    var scoring: MatchScoringRules
    var includeImage: Bool = false
    
    private var detailText: String {
        var ofText: String = ""
        
        if scoring.isMultiSet {
            ofText =
                scoring.playItOut
                ? "Best of \(scoring.setsMaximum) sets"
                : "First to \(scoring.setsWinAt) sets"
        } else {
            if scoring.setScoring.isMultiGame {
                ofText = "Best of \(scoring.setScoring.gamesMaximum) games"
            }
        }

        return "\(ofText)"
    }

    private var detailSecondaryText: String {
        if scoring.setScoring.isMultiGame {
            return "Games to \(scoring.setScoring.gameScoring.winScore) points"
        }

        return "First to \(scoring.setScoring.gameScoring.winScore) points"
    }

    private var systemImage: String {
        switch sport {
        case .squash: return "figure.squash"
        case .ultimate: return "figure.disc.sports"
        case .volleyball: return "figure.volleyball"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if includeImage {
                Label(name, systemImage: systemImage)
                    .font(.headline)
            } else {
                Text(name)
                    .font(.headline)
            }
            
            if !detailText.isEmpty {
                Text(detailText)
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }

            Text(detailSecondaryText)
                .font(.caption2)
                .foregroundStyle(.tint)
        }
    }
}

