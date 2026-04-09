//
//  ActiveMatchMainView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import ScoreKeepCore

struct ActiveMatchMainView: View {
    @Environment(ScoreKeepMatch.self) var match: ScoreKeepMatch

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
            ScoreKeepMatch(
                .volleyball,
                rules: ScoreKeepMatchRules(
                    winAt: 5,
                    setRules: ScoreKeepSetRules(
                        winAt: 6,
                        gameRules: ScoreKeepGameRules(
                            winAt: 25
                        )
                    )
                )
            )
        )
}
