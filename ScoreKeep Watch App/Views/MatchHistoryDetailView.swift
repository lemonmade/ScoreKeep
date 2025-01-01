//
//  MatchHistoryDetailView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-31.
//

import Foundation
import SwiftUI
import Charts

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

struct MatchHistoryGameScoreData: Identifiable {
    var id = UUID()
    
    var score: Int
    var team: String
    var index: Int
    var timestamp: Date
}

struct MatchHistoryDetailGameView: View {
    var game: MatchGame
    
    private var gameScores: [MatchHistoryGameScoreData] {
        var scoreUs = 0
        var scoreThem = 0
        var index = 0
        
        var data: [MatchHistoryGameScoreData] = [
            MatchHistoryGameScoreData(score: 0, team: "Us", index: index, timestamp: game.startedAt),
            MatchHistoryGameScoreData(score: 0, team: "Them", index: index, timestamp: game.startedAt)
        ]
        
        for score in game.scores {
            index += 1

            if score.team == .us { scoreUs = score.total }
            else { scoreThem = score.total }
            
            data.append(
                MatchHistoryGameScoreData(score: scoreUs, team: "Us", index: index, timestamp: score.timestamp)
            )
            data.append(
                MatchHistoryGameScoreData(score: scoreThem, team: "Them", index: index, timestamp: score.timestamp)
            )
        }
        
        if scoreUs != game.scoreUs || scoreThem != game.scoreThem {
            index += 1
            let lastScore = data.last!
            
            data.append(
                MatchHistoryGameScoreData(score: game.scoreUs, team: "Us", index: index, timestamp: game.endedAt ?? lastScore.timestamp)
            )
            data.append(
                MatchHistoryGameScoreData(score: game.scoreThem, team: "Them", index: index, timestamp: game.endedAt ?? lastScore.timestamp)
            )
        }
        
        print(data)
        
        return data
    }
    
    private var backgroundColor: Color? {
        guard let winner = game.winner else { return nil }
        
        return winner == .us ? .blue : .red
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("\(game.scoreUs)–\(game.scoreThem)")
            Chart(gameScores) { score in
                LineMark(
                    x: .value("Index", score.index),
                    y: .value("Score", score.score)
                )
                .foregroundStyle(by: .value("Team", score.team))
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisTick()
                }

            }
            .chartLegend(.hidden)
            .chartXScale(domain: [0, gameScores.last!.index])
            .chartForegroundStyleScale(["Us": .blue, "Them": .red])
        }
            .containerBackground(backgroundColor?.gradient ?? Color.clear.gradient, for: .tabView)
            .scenePadding()
    }
}
