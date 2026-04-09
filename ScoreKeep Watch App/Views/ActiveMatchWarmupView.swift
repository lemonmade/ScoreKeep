//
//  ActiveMatchWarmupView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2025-05-04.
//

import SwiftUI
import ScoreKeepCore

struct ActiveMatchWarmupView: View {
    @Environment(ScoreKeepMatch.self) private var match

    var body: some View {
        if let warmup = match.warmup {
            ActiveMatchWarmupInternalView(match: match, warmup: warmup)
        } else {
            // TODO
            EmptyView()
        }
    }
}

enum StartingServe {
    case us, them, random
}

struct ActiveMatchWarmupInternalView: View {
    var match: ScoreKeepMatch
    var warmup: ScoreKeepWarmup

    private let spacing: CGFloat = 8
    private let outerPadding = EdgeInsets(
        top: 40, leading: 12, bottom: 21, trailing: 12)

    @State private var startingServe: StartingServe = .random

    var body: some View {
        VStack(spacing: 12) {
            Text("Warmup")

            Button {
                let startingServe: ScoreKeepTeam = switch startingServe {
                case .us: .us
                case .them: .them
                case .random: [ScoreKeepTeam.us, ScoreKeepTeam.them].randomElement()!
                }

                match.startingServe = startingServe

                warmup.end()
                match.startGame()
            } label: {
                Text("Start match")
            }
            .buttonStyle(.glassProminent)
            .tint(.green)

            Form {
                Section(header: Text("Match settings")) {
                    Picker("Starting serve", selection: $startingServe) {
                        Text("Us").tag(StartingServe.us)
                        Text("Them").tag(StartingServe.them)
                        Text("Random").tag(StartingServe.random)
                    }
                }
            }
        }
    }
}

#Preview {
    let match = ScoreKeepMatch(
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

    match.startWarmup()

    return ActiveMatchWarmupView()
        .environment(
            match
        )
}
