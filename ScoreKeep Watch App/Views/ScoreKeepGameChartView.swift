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

    private var gameData: ScoreKeepHistoryGameData {
        ScoreKeepHistoryGameData(game: game)
    }

    var body: some View {
        let data = gameData
        let gameScores = data.scores
        let scoreSize: CGFloat = (gameScores.count / 2) > 10 ? 4 : 8
        let totalPoints = data.totalPoints
        let axisMarks = data.axisMarks(count: 3)

        Chart(gameScores) { score in
            LineMark(
                x: .value("Point", score.index),
                y: .value("Score", score.score)
            )
            .foregroundStyle(by: .value("Team", score.teamName))

            if score.hasChange {
                PointMark(
                    x: .value("Point", score.index),
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
            AxisMarks(values: axisMarks.map(\.index)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let index = value.as(Int.self),
                       let mark = axisMarks.first(where: { $0.index == index }) {
                        Text(
                            mark.timestamp,
                            format: .dateTime.hour(.conversationalDefaultDigits(amPM: .omitted))
                                .minute())
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXScale(domain: [0, totalPoints])
        .chartYScale(domain: [0, [game.scoreUs, game.scoreThem].max()!])
        .chartForegroundStyleScale(["Us": .blue, "Them": .red])
    }
}

// Chart data

private struct ScoreKeepHistoryAxisMark {
    var index: Int
    var timestamp: Date
}

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

    var totalPoints: Int {
        game.scores.count
    }

    /// Returns axis marks at evenly-spaced index positions with interpolated timestamps.
    func axisMarks(count: Int) -> [ScoreKeepHistoryAxisMark] {
        let gameScores = game.scores
        guard !gameScores.isEmpty else { return [] }

        let startedAt = game.startedAt
        let total = gameScores.count

        // Build index-to-timestamp mapping (index 0 = startedAt)
        var timestamps: [Date] = [startedAt]
        for score in gameScores {
            timestamps.append(score.timestamp)
        }

        var marks: [ScoreKeepHistoryAxisMark] = []

        for i in 0..<count {
            let fraction = Double(i) / Double(count)
            let position = fraction * Double(total)
            let index = Int(position.rounded())
            let clampedIndex = min(index, total)

            marks.append(ScoreKeepHistoryAxisMark(
                index: clampedIndex,
                timestamp: timestamps[clampedIndex]
            ))
        }

        return marks
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
