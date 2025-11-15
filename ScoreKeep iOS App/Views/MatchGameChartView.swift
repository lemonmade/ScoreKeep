//
//  MatchGameChartView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-03.
//

import SwiftUI
import Charts
import ScoreKeepCore

struct MatchGameChartView: View {
    var game: MatchGame

    private var gameScores: [MatchHistoryGameScoreData] {
        MatchHistoryGameData(game: game).scores
    }
    
    var body: some View {
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
        .chartYScale(domain: [0, [game.scoreUs, game.scoreThem].max()!])
        .chartForegroundStyleScale(["Us": .blue, "Them": .red])
    }
}

struct MatchGameChartSparklineView : View {
    var game: MatchGame

    private var gameScores: [MatchHistoryGameScoreData] {
        MatchHistoryGameData(game: game).scores
    }
    
    var body: some View {
        Chart(gameScores) { score in
            LineMark(
                x: .value("Index", score.index),
                y: .value("Score", score.score)
            )
            .foregroundStyle(by: .value("Team", score.team))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: [0, gameScores.last!.index])
        .chartYScale(domain: [0, [game.scoreUs, game.scoreThem].max()!])
        .chartForegroundStyleScale(["Us": .blue, "Them": .red])
        .frame(width: 64, height: 32)
    }
}

// Chart data

private struct MatchHistoryGameScoreData: Identifiable {
    var id = UUID()
    
    var score: Int
    var team: String
    var index: Int
    var timestamp: Date
}

private struct MatchHistoryGameData {
    var game: MatchGame
    
    var scores: [MatchHistoryGameScoreData] {
        var scoreUs = 0
        var scoreThem = 0
        var index = 0
        
        var scores: [MatchHistoryGameScoreData] = [
            MatchHistoryGameScoreData(
                score: 0,
                team: "Us",
                index: index,
                timestamp: game.startedAt
            ),
            MatchHistoryGameScoreData(
                score: 0,
                team: "Them",
                index: index,
                timestamp: game.startedAt
            )
        ]
        
        for score in game.scores {
            index += 1
            scoreUs += score.us
            scoreThem += score.them
            
            scores.append(
                MatchHistoryGameScoreData(
                    score: scoreUs,
                    team: "Us",
                    index: index,
                    timestamp: score.timestamp
                )
            )
            scores.append(
                MatchHistoryGameScoreData(
                    score: scoreThem,
                    team: "Them",
                    index: index,
                    timestamp: score.timestamp
                )
            )
        }
        
        return scores
    }
}
