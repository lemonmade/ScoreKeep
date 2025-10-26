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

    private var systemImage: String {
        switch sport {
        case .squash: return "figure.squash"
        case .ultimate: return "figure.disc.sports"
        case .volleyball: return "figure.volleyball"
        case .tennis: return "figure.tennis"
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
            
            let primaryLabel = scoring.primaryLabel
            if !primaryLabel.isEmpty {
                Text(primaryLabel)
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }
            
            let secondaryLabel = scoring.secondaryLabel
            if sport != .tennis && !secondaryLabel.isEmpty {
                Text(secondaryLabel)
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }
        }
    }
}

