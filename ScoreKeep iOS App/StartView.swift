//
//  ContentView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-03-23.
//

import SwiftUI
import SwiftData

struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Match.endedAt, order: .reverse) private
        var matches2: [Match]

    private let matches = [
        Match(
            .volleyball,
            environment: .indoor,
            scoring: MatchScoringRules(
                setsWinAt: 1,
                setScoring: MatchSetScoringRules(
                    gamesWinAt: 3,
                    gameScoring: MatchGameScoringRules(
                        winScore: 25
                    )
                )
            ),
            sets: [
                MatchSet(
                    number: 1,
                    games: [
                        MatchGame(
                            number: 1,
                            us: 25,
                            them: 22,
                            scores: [],
                            startedAt: .now.advanced(by: -100),
                            endedAt: .now
                        )
                    ],
                    startedAt: .now.advanced(by: -100),
                    endedAt: .now
                )
            ]
        )
    ]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(matches2) { match in
                    NavigationLink {
                        Text(match.scoreSummaryString)
                    } label: {
                        Text(match.scoreSummaryString)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func addItem() {
        let endedAt = Date.now
        let startedAt = endedAt.advanced(by: -3600)
        
        context.insert(
            Match(
                .volleyball,
                environment: .indoor,
                scoring: MatchScoringRules(
                    setsWinAt: 1,
                    setsMaximum: 1,
                    playItOut: true,
                    setScoring: MatchSetScoringRules(
                        gamesWinAt: 1,
                        gameScoring: MatchGameScoringRules(
                            winScore: 25,
                            maximumScore: 25,
                            winBy: 1
                        )
                    )
                ),
                sets: [
                    MatchSet(
                        number: 1,
                        games: [
                            MatchGame(
                                number: 1,
                                us: 25,
                                them: 23,
                                scores: [],
                                serve: .us,
                                startedAt: startedAt,
                                endedAt: endedAt
                            )
                        ],
                        startedAt: startedAt,
                        endedAt: endedAt
                    )
                ],
                startedAt: startedAt,
                endedAt: endedAt
            )
        )

        try? context.save()
    }
}

#Preview {
    StartView()
        .modelContainer(MatchModelContainer().testModelContainer())
}
