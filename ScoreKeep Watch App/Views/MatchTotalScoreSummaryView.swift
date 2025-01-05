//
//  MatchTotalScoreSummaryView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-05.
//


import SwiftUI
import SwiftData

struct MatchTotalScoreSummaryView: View {
    var us: Int
    var them: Int
    var winner: MatchTeam? = nil
    
    init(us: Int, them: Int, winner: MatchTeam? = nil) {
        self.us = us
        self.them = them
        self.winner = winner
    }
    
    init(match: Match) {
        self.us = match.isMultiSet ? match.setsUs : (match.sets.last?.gamesUs ?? 0)
        self.them = match.isMultiSet ? match.setsThem : (match.sets.last?.gamesThem ?? 0)
        self.winner = match.winner
    }
    
    init(game: MatchGame) {
        self.us = game.scoreUs
        self.them = game.scoreThem
        self.winner = game.winner
    }
    
    private let cornerRadiusOutside: CGFloat = 8
    private let cornerRadiusInside: CGFloat = 4
    private let innerPadding: CGFloat = 4
    private let outerPadding: CGFloat = 16
    private let backgroundOpacity = 0.25
    
    var body: some View {
        Grid(verticalSpacing: 0) {
            GridRow {
                Text("\(us)")
                    .fontWeight(winner == .us ? .bold : .regular)
                    .foregroundColor(.blue)
                    .padding(
                        EdgeInsets(
                            top: innerPadding,
                            leading: outerPadding,
                            bottom: innerPadding,
                            trailing: outerPadding
                        )
                    )
            }
            .background {
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: cornerRadiusOutside,
                        bottomLeading: winner == .us ? cornerRadiusInside : 0,
                        bottomTrailing: winner == .us ? cornerRadiusInside : 0,
                        topTrailing: cornerRadiusOutside
                    )
                )
                .fill(.blue.opacity(backgroundOpacity))
                .stroke(
                    .blue,
                    style: StrokeStyle(lineWidth: winner == .us ? 2 : 0)
                )
            }
            
            
            GridRow {
                Text("\(them)")
                    .fontWeight(winner == .them ? .bold : .regular)
                    .foregroundColor(.red)
                    .padding(
                        EdgeInsets(
                            top: innerPadding,
                            leading: outerPadding,
                            bottom: innerPadding,
                            trailing: outerPadding
                        )
                    )
            }
            
            .background {
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: winner == .them ? cornerRadiusInside : 0,
                        bottomLeading: cornerRadiusOutside,
                        bottomTrailing: cornerRadiusOutside,
                        topTrailing: winner == .them ? cornerRadiusInside : 0
                    )
                )
                .fill(.red.opacity(backgroundOpacity))
                .stroke(
                    .red,
                    style: StrokeStyle(lineWidth: winner == .them ? 2 : 0)
                )
            }
        }
        .monospacedDigit()
    }
}
