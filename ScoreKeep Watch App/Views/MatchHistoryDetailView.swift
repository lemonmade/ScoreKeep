//
//  MatchHistoryDetailView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-31.
//

import Foundation
import SwiftUI

struct MatchHistoryDetailView: View {
    var match: Match

    var body: some View {
        TabView {
            Text("\((match.endedAt ?? match.startedAt).formatted(.dateTime))")
            
            ForEach(match.sets) { set in
                ForEach(set.games) { game in
                    MatchHistoryDetailGameView(game: game)
                }
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

struct MatchHistoryDetailGameView: View {
    var game: MatchGame
    
    private var backgroundColor: Color? {
        guard let winner = game.winner else { return nil }
        
        return winner == .us ? .blue : .red
    }
    
    var body: some View {
        Text("\(game.scoreUs)–\(game.scoreThem)")
            .containerBackground(backgroundColor?.gradient ?? Color.clear.gradient, for: .tabView)
    }
}
