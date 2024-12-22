//
//  GameHistoryView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI
import SwiftData

struct GameHistoryView: View {
    @Query(sort: \Game.startedAt, order: .reverse) private var games: [Game]
    @Environment(\.modelContext) private var gamesContext
    
    var body: some View {
        List {
            Button {
                let newGame = Game(
                    rules: GameRules(winScore: 25),
                    sets: [
                        GameSet(us: Int.random(in: 0...24), them: 25),
                        GameSet(us: Int.random(in: 0...24), them: 25)
                    ]
                )
                
                gamesContext.insert(newGame)
                try? gamesContext.save()
            } label: {
                Text("Add Game")
            }
            
            ForEach(games) { game in
                NavigationLink {
                    Text(game.id.storeIdentifier ?? "Unknown")
                } label: {
                    VStack(alignment: .leading) {
                        Text("\(game.sets.map { "\($0.scoreUs)-\($0.scoreThem)"}.joined(separator: ", "))")
                            .font(.headline)
                        Text(
                            (game.endedAt ?? game.startedAt).description
                        )
                            .font(.caption2)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        gamesContext.delete(game)
                    } label: {
                        Label("Delete", systemImage: "trash")
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
            for: Game.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
//        let game0 = Game(
//            ruleset: GameRules(winScore: 25),
//            sets: [
//                GameSet(score0: 15, score1: 25, startedAt: Date()),
//                GameSet(score0: 10, score1: 25, startedAt: Date()),
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
