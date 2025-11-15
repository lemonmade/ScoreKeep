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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if includeImage {
                Label(name, systemImage: sport.figureIcon)
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

