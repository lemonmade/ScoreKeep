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
        let gameScores = gameScores
        let scoreSize: CGFloat = (gameScores.count / 2) > 10 ? 4 : 8
        let startedAt = game.startedAt
        let endedAt = gameScores.last!.timestamp
        let xAxisInterval = endedAt.timeIntervalSince(startedAt) / 3

        Chart(gameScores) { score in
            LineMark(
                x: .value("Time", score.timestamp),
                y: .value("Score", score.score)
            )
            .foregroundStyle(by: .value("Team", score.teamName))
            
            if score.hasChange {
                PointMark(
                    x: .value("Time", score.timestamp),
                    y: .value("Score", score.score)
                )
                .symbol {
                    Circle()
                        .frame(width: scoreSize, height: scoreSize)
                        .foregroundStyle(score.team == .us ? .blue : .red)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [startedAt, startedAt.addingTimeInterval(xAxisInterval), startedAt.addingTimeInterval(xAxisInterval * 2)]) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.hour(.conversationalDefaultDigits(amPM: .omitted)).minute())
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXScale(domain: [startedAt, endedAt])
        .chartYScale(domain: [0, [game.scoreUs, game.scoreThem].max()!])
        .chartForegroundStyleScale(["Us": .blue, "Them": .red])
    }
}

struct MatchGameChartSparklineView : View {
    var game: MatchGame

    private var gameScores: [MatchHistoryGameScoreData] {
        MatchHistoryGameData(game: game, order: .winnerOnTop).scores
    }
    
    var body: some View {
        let gameScores = gameScores

        Chart(gameScores) { score in
            LineMark(
                x: .value("Time", score.timestamp),
                y: .value("Score", score.score)
            )
            .foregroundStyle(by: .value("Team", score.teamName))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: [game.startedAt, gameScores.last!.timestamp])
        .chartYScale(domain: [0, [game.scoreUs, game.scoreThem].max()!])
        .chartForegroundStyleScale(["Us": .blue, "Them": .red])
        .frame(width: 48, height: 20)
    }
}

// Chart data

private struct MatchHistoryGameScoreData: Identifiable {
    var id = UUID()
    
    var score: Int
    var team: MatchTeam
    var teamName: String {
        team == .us ? "Us" : "Them"
    }
    var index: Int
    var timestamp: Date
    var hasChange: Bool = false
}

private struct MatchHistoryGameData {
    var game: MatchGame
    var order: Order = .scoreOnTop
    
    enum Order {
        case scoreOnTop, winnerOnTop
    }
    
    var scores: [MatchHistoryGameScoreData] {
        var scoreUs = 0
        var scoreThem = 0
        var index = 0
        
        let showTop: MatchTeam = game.scoreUs >= game.scoreThem ? .us : .them
        let initialUsScore = MatchHistoryGameScoreData(
            score: 0,
            team: .us,
            index: index,
            timestamp: game.startedAt
        )
        let initialThemScore = MatchHistoryGameScoreData(
            score: 0,
            team: .them,
            index: index,
            timestamp: game.startedAt
        )
        
        var scores: [MatchHistoryGameScoreData] = []
        
        if showTop == .us {
            scores.append(initialThemScore)
            scores.append(initialUsScore)
        } else {
            scores.append(initialUsScore)
            scores.append(initialThemScore)
        }
        
        for score in game.scores {
            index += 1
            scoreUs += score.us
            scoreThem += score.them
            
            let usScore = MatchHistoryGameScoreData(
                score: scoreUs,
                team: .us,
                index: index,
                timestamp: score.timestamp,
                hasChange: score.teamWithLegacy == .us
            )
            
            let themScore = MatchHistoryGameScoreData(
                score: scoreThem,
                team: .them,
                index: index,
                timestamp: score.timestamp,
                hasChange: score.teamWithLegacy == .them
            )
            
            let showUsFirst = order == .scoreOnTop ? score.teamWithLegacy == .us : showTop == .us
            
            if showUsFirst {
                scores.append(themScore)
                scores.append(usScore)
            } else {
                scores.append(usScore)
                scores.append(themScore)
            }
        }
        
        return scores
    }
}
