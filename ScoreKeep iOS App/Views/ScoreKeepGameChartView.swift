//
//  ScoreKeepGameChartView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-07.
//

import Charts
import ScoreKeepCore
import SwiftUI

struct ScoreKeepGameChartView: View {
    var game: ScoreKeepGame

    private var gameScores: [ScoreKeepHistoryGameScoreData] {
        ScoreKeepHistoryGameData(game: game).scores
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
            AxisMarks(
                values: [
                    startedAt,
                    startedAt.addingTimeInterval(xAxisInterval),
                    startedAt.addingTimeInterval(xAxisInterval * 2),
                ]
            ) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(
                            date,
                            format: .dateTime.hour(.conversationalDefaultDigits(amPM: .omitted))
                                .minute())
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

struct ScoreKeepGameChartSparklineView: View {
    var game: ScoreKeepGame

    private var gameScores: [ScoreKeepHistoryGameScoreData] {
        ScoreKeepHistoryGameData(game: game, order: .winnerOnTop).scores
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

private struct ScoreKeepHistoryGameScoreData: Identifiable {
    // swiftlint:disable:next identifier_name
    var id = UUID()

    var score: Int
    var team: ScoreKeepTeam
    var teamName: String {
        team == .us ? "Us" : "Them"
    }
    var index: Int
    var timestamp: Date
    var hasChange: Bool = false
}

private struct ScoreKeepHistoryGameData {
    var game: ScoreKeepGame
    var order: Order = .scoreOnTop

    enum Order {
        case scoreOnTop, winnerOnTop
    }

    var scores: [ScoreKeepHistoryGameScoreData] {
        var scoreUs = 0
        var scoreThem = 0
        var index = 0

        let showTop: ScoreKeepTeam = game.scoreUs >= game.scoreThem ? .us : .them
        let initialUsScore = ScoreKeepHistoryGameScoreData(
            score: 0,
            team: .us,
            index: index,
            timestamp: game.startedAt
        )
        let initialThemScore = ScoreKeepHistoryGameScoreData(
            score: 0,
            team: .them,
            index: index,
            timestamp: game.startedAt
        )

        var scores: [ScoreKeepHistoryGameScoreData] = []

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

            let usScore = ScoreKeepHistoryGameScoreData(
                score: scoreUs,
                team: .us,
                index: index,
                timestamp: score.timestamp,
                hasChange: score.team == .us
            )

            let themScore = ScoreKeepHistoryGameScoreData(
                score: scoreThem,
                team: .them,
                index: index,
                timestamp: score.timestamp,
                hasChange: score.team == .them
            )

            let showUsFirst = order == .scoreOnTop ? score.team == .us : showTop == .us

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
