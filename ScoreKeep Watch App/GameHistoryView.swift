//
//  GameHistoryView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI
import SwiftData

struct GameHistoryView: View {
    @Query(sort: \GameScore.startedAt, order: .reverse) private var games: [GameScore]
    @Environment(\.modelContext) private var gamesContext
    
    var body: some View {
        List {
            Button {
                print("Adding game...")
                
                let newGame = GameScore(
                    ruleset: GameScoreRuleset(winScore: 25),
                    sets: [
                        GameSetScore(score0: Int.random(in: 0...24), score1: 25, startedAt: Date()),
                        GameSetScore(score0: Int.random(in: 0...24), score1: 25, startedAt: Date())
                    ],
                    startedAt: Date()
                )
                
                gamesContext.insert(newGame)
            } label: {
                Text("Add Game")
            }
            
            ForEach(games) { game in
                NavigationLink {
                    Text(game.id.storeIdentifier ?? "Unknown")
                } label: {
                    VStack(alignment: .leading) {
                        Text("\(game.sets.map { "\($0.score0)-\($0.score1)"}.joined(separator: ", "))")
                            .font(.headline)
                        Text(
                            (game.endedAt ?? game.startedAt).description
                        )
                            .font(.caption2)
                    }
                }
            }
        }
            .listStyle(.carousel)
    }
}

#Preview {
    GameHistoryView()
        .modelContainer(previewContainer)
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: GameScore.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
//        let game0 = GameScore(
//            ruleset: GameScoreRuleset(winScore: 25),
//            sets: [
//                GameSetScore(score0: 15, score1: 25, startedAt: Date()),
//                GameSetScore(score0: 10, score1: 25, startedAt: Date()),
//            ],
//            startedAt: Date()
//        )
//        
//        container.mainContext.insert(game0)
        
        return container
    } catch {
        fatalError("Could not load preview container: \(error)")
    }
}()
