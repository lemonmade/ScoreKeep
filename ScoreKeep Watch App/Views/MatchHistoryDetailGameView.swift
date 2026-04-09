//
//  MatchHistoryDetailGameView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-03.
//

import SwiftUI
import ScoreKeepCore
import ScoreKeepUI

struct MatchHistoryDetailGameView: View {
    var game: ScoreKeepGame

    private var backgroundColor: Color? {
        guard let winner = game.winner else { return nil }

        return winner == .us ? .blue.opacity(0.5) : .red.opacity(0.5)
    }

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

            ScoreKeepGameChartView(game: game)
        }
        .containerBackground(
            backgroundColor?.gradient ?? Color.clear.gradient,
            for: .tabView
        )
        .scenePadding()
    }
}

#Preview {
    TabView {
        MatchHistoryDetailGameView(
            game: ScoreKeepGame(
                number: 1,
                scores: [
                    ScoreKeepGameScore(.us),
                    ScoreKeepGameScore(.us),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.us),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.us),
                    ScoreKeepGameScore(.us),
                    ScoreKeepGameScore(.them),
                    ScoreKeepGameScore(.them),
                ],
                startedAt: Date.now.addingTimeInterval(-20 * 60),
                endedAt: Date.now
            )
        )
    }
}
