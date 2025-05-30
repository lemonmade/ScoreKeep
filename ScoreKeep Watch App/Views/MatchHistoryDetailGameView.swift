//
//  MatchHistoryDetailGameView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-03.
//

import SwiftUI
import Charts

struct MatchHistoryDetailGameView: View {
    var game: MatchGame

    private var backgroundColor: Color? {
        guard let winner = game.winner else { return nil }
        
        return winner == .us ? .blue.opacity(0.5) : .red.opacity(0.5)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                MatchTotalScoreSummaryView(game: game)
                
                VStack(alignment: .leading) {
                    Text("Game \(game.number)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let endedAt = game.endedAt {
                        Text(game.startedAt...endedAt)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GameScoreChartView(game: game)
        }
        .containerBackground(
            backgroundColor?.gradient ?? Color.clear.gradient,
            for: .tabView
        )
        .scenePadding()
    }
}

struct GameScoreChartView: View {
    var game: MatchGame
    
    private struct MatchHistoryGameScoreData: Identifiable {
        var id = UUID()
        
        var score: Int
        var team: String
        var index: Int
        var timestamp: Date
    }

    private var gameScores: [MatchHistoryGameScoreData] {
        var scoreUs = 0
        var scoreThem = 0
        var index = 0
        
        var data: [MatchHistoryGameScoreData] = [
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
            
            data.append(
                MatchHistoryGameScoreData(
                    score: scoreUs,
                    team: "Us",
                    index: index,
                    timestamp: score.timestamp
                )
            )
            data.append(
                MatchHistoryGameScoreData(
                    score: scoreThem,
                    team: "Them",
                    index: index,
                    timestamp: score.timestamp
                )
            )
        }
        
        if scoreUs != game.scoreUs || scoreThem != game.scoreThem {
            index += 1
            let lastScore = data.last!
            
            data.append(
                MatchHistoryGameScoreData(
                    score: game.scoreUs,
                    team: "Us",
                    index: index,
                    timestamp: game.endedAt ?? lastScore.timestamp
                )
            )
            data.append(
                MatchHistoryGameScoreData(
                    score: game.scoreThem,
                    team: "Them",
                    index: index,
                    timestamp: game.endedAt ?? lastScore.timestamp
                )
            )
        }
        
        return data
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

#Preview {
    TabView {
        MatchHistoryDetailGameView(
            game: MatchGame(
                number: 1,
                scores: [
                    MatchGameScore(.us),
                    MatchGameScore(.us),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                    MatchGameScore(.us),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                    MatchGameScore(.us),
                    MatchGameScore(.us),
                    MatchGameScore(.them),
                    MatchGameScore(.them),
                ],
                startedAt: Date.now.addingTimeInterval(-20 * 60),
                endedAt: Date.now
            )
        )
    }
}
