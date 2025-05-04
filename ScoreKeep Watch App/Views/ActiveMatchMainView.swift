//
//  ActiveMatchMainView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct ActiveMatchMainView: View {
    @Environment(Match.self) var match: Match
    
    private var isShowingWarmup: Bool {
        match.warmup?.hasEnded == false
    }
    
    var body: some View {
        ZStack {
            if isShowingWarmup {
                ActiveMatchWarmupView()
            } else {
                ActiveMatchScoreKeepView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingWarmup)
    }
}

#Preview {
    ActiveMatchMainView()
        .environment(
            Match(
                .volleyball,
                scoring: MatchScoringRules(
                    setsWinAt: 5,
                    setScoring: MatchSetScoringRules(
                        gamesWinAt: 5,
                        gameScoring: MatchGameScoringRules(
                            winScore: 25
                        )
                    )
                )
            )
        )
}
