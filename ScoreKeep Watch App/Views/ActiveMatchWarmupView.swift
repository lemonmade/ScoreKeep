//
//  ActiveMatchWarmupView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2025-05-04.
//

import SwiftUI

struct ActiveMatchWarmupView: View {
    @Environment(Match.self) private var match

    var body: some View {
        if let warmup = match.warmup {
            ActiveMatchWarmupInternalView(match: match, warmup: warmup)
        } else {
            // TODO
            EmptyView()
        }
    }
}

struct ActiveMatchWarmupInternalView: View {
    var match: Match
    var warmup: MatchWarmup

    private let spacing: CGFloat = 8
    private let outerPadding = EdgeInsets(
        top: 40, leading: 12, bottom: 21, trailing: 12)

    var body: some View {
        VStack(spacing: 12) {
            Text("Warmup")
            Button {
                warmup.end()
            } label: {
                Text("Start match")
            }
        }
    }
}

#Preview {
    let match = Match(
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
    
    match.startWarmup()
    
    return ActiveMatchWarmupView()
        .environment(
            match
        )
}
