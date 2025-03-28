//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftData
import SwiftUI

enum MatchSport: String, Codable {
    case volleyball
}

enum MatchTeam: String, Codable {
    case us, them
}

enum MatchEnvironment: String, Codable {
    case indoor, outdoor
}

@Model
class Match {
    var sport: MatchSport
    var environment: MatchEnvironment

    var sets: [MatchSet]
    // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
    var orderedSets: [MatchSet] { sets.sorted { $0.number < $1.number } }

    var startedAt: Date
    var endedAt: Date?
    var scoring: MatchScoringRules
    var template: MatchTemplate?

    var hasEnded: Bool { endedAt != nil }

    var duration: TimeInterval { endedAt?.timeIntervalSince(startedAt) ?? 0 }

    var latestSet: MatchSet? { orderedSets.last }
    var latestGame: MatchGame? { latestSet?.latestGame }

    var hasMoreGames: Bool {
        if hasEnded { return false }
        guard let latestSet else { return true }

        return scoring.setScoring.canPlayAnotherGame(latestSet)
            || scoring.canPlayAnotherSet(self)
    }

    var setsUs: Int { sets.count { $0.winner == .us } }
    var setsThem: Int { sets.count { $0.winner == .them } }

    var winner: MatchTeam? {
        if !hasEnded { return nil }

        let setsUs = setsUs
        let setsThem = setsThem
        return setsUs > setsThem ? .us : setsThem > setsUs ? .them : nil
    }

    var hasWinner: Bool { winner != nil }

    var isMultiSet: Bool { scoring.isMultiSet }
    
    var scoreSummaryString: String {
        if isMultiSet {
            return "\((orderedSets).map { "\($0.gamesUs)-\($0.gamesThem)" }.joined(separator: ", "))"
        }
        
        return "\((latestSet?.orderedGames ?? []).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))"
    }

    init(from template: MatchTemplate, markAsUsed: Bool = true) {
        self.template = markAsUsed ? template : nil
        self.sport = template.sport
        self.environment = template.environment
        self.scoring = template.scoring
        self.sets = [MatchSet()]
        self.startedAt = Date()
    }

    init(
        _ sport: MatchSport = .volleyball,
        environment: MatchEnvironment = .indoor, scoring: MatchScoringRules,
        sets: [MatchSet] = [MatchSet()], startedAt: Date = Date(),
        endedAt: Date? = nil
    ) {
        self.sport = sport
        self.environment = environment
        self.sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.scoring = scoring
    }

    func setsFor(_ team: MatchTeam) -> Int {
        return team == .us ? setsUs : setsThem
    }

    private var debugScoreDescription: String {
        return orderedSets.map { set in
            set.orderedGames.map { game in
                return "\(game.scoreUs)-\(game.scoreThem)"
            }.joined(separator: ", ")
        }.joined(separator: " | ")
    }

    func score(_ team: MatchTeam) {
        guard let set = latestSet, !set.hasEnded, let game = set.latestGame,
            !game.hasEnded
        else { return }

        game.score(team)

        if scoring.setScoring.gameScoring.hasWinner(game) {
            game.endedAt = Date()

            if !scoring.setScoring.canPlayAnotherGame(set) {
                set.endedAt = Date()
            }
        }
    }

    func startGame() {
        let now = Date()

        if latestSet == nil {
            sets.append(MatchSet(games: []))
        }

        guard let latestSet else { return }

        guard let latestGame = latestSet.latestGame else {
            let newGame = MatchGame(startedAt: now)
            latestSet.games.append(newGame)
            return
        }

        latestGame.endedAt = now

        if scoring.setScoring.canPlayAnotherGame(latestSet) {
            let newGame = MatchGame(
                number: latestGame.number + 1, startedAt: now)
            latestSet.games.append(newGame)
            return
        }

        latestSet.endedAt = now

        if scoring.hasWinner(self) && !scoring.playItOut {
            return
        }

        let newSet = MatchSet(
            number: latestSet.number + 1, games: [MatchGame(startedAt: now)],
            startedAt: now)
        sets.append(newSet)
    }

    func end() {
        if hasEnded { return }

        let now = Date()

        if let latestGame, !latestGame.hasEnded {
            latestGame.endedAt = now
        }

        if let latestSet, !latestSet.hasEnded {
            latestSet.endedAt = now
        }

        endedAt = now
    }
}

@Model
class MatchSet {
    var number: Int

    var games: [MatchGame]
    var orderedGames: [MatchGame] { games.sorted { $0.number < $1.number } }

    var latestGame: MatchGame? { orderedGames.last }

    var createdAt: Date
    var startedAt: Date
    var endedAt: Date?

    var hasEnded: Bool { endedAt != nil }

    var gamesUs: Int { games.count { $0.winner == .us } }
    var gamesThem: Int { games.count { $0.winner == .them } }

    var winner: MatchTeam? {
        if !hasEnded { return nil }

        let gamesUs = gamesUs
        let gamesThem = gamesThem
        return gamesUs > gamesThem ? .us : gamesThem > gamesUs ? .them : nil
    }

    var hasWinner: Bool { winner != nil }

    var isTied: Bool {
        gamesUs == gamesThem
    }

    init(
        number: Int = 1, games: [MatchGame] = [MatchGame()],
        startedAt: Date = Date(), endedAt: Date? = nil
    ) {
        self.number = number
        self.games = games
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
    }

    func gamesFor(_ team: MatchTeam) -> Int {
        return team == .us ? gamesUs : gamesThem
    }
}

@Model
class MatchGame {
    var number: Int

    var scoreUs: Int
    var scoreThem: Int

    var createdAt: Date
    var startedAt: Date
    var endedAt: Date?

    var scores: [MatchGameScore]
    var orderedScores: [MatchGameScore] { scores.sorted { $0.timestamp < $1.timestamp } }

    var hasEnded: Bool { endedAt != nil }

    var winner: MatchTeam? {
        if !hasEnded { return nil }

        let scoreUs = scoreUs
        let scoreThem = scoreThem
        return scoreUs > scoreThem ? .us : scoreThem > scoreUs ? .them : nil
    }

    var hasWinner: Bool { winner != nil }

    var isTied: Bool {
        scoreUs == scoreThem
    }

    private var initialServe: MatchTeam?

    var nextServe: MatchTeam? {
        if hasEnded { return nil }

        if let lastScore = orderedScores.last {
            return lastScore.team
        }

        return initialServe
    }

    init(
        number: Int = 1, us scoreUs: Int = 0, them scoreThem: Int = 0,
        scores: [MatchGameScore] = [], serve: MatchTeam? = nil,
        startedAt: Date = Date(), endedAt: Date? = nil
    ) {
        self.number = number
        self.scoreUs = scoreUs
        self.scoreThem = scoreThem
        self.scores = scores
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
        self.initialServe = serve
    }

    func score(_ team: MatchTeam, to: Int? = nil, at timestamp: Date = Date()) {
        let currentScore = scoreFor(team)
        let finalTo = to ?? currentScore + 1

        if team == .us {
            self.scoreUs = finalTo
        } else {
            self.scoreThem = finalTo
        }

        scores.append(
            MatchGameScore(
                team: team, change: finalTo - currentScore, total: finalTo,
                timestamp: timestamp)
        )
    }

    func scoreFor(_ team: MatchTeam) -> Int {
        team == .us ? scoreUs : scoreThem
    }
    
    func scoreStreakFor(_ team: MatchTeam) -> Int {
        var streak = 0
        
        for score in scores.sorted(by: { $0.timestamp > $1.timestamp }) {
            if score.team != team { break }
            streak += score.change
        }
        
        return streak
    }
}

struct MatchGameScore: Codable, Equatable {
    var team: MatchTeam
    var change: Int
    var total: Int
    var timestamp: Date
}

enum MatchTemplateColor: String, Codable {
    case green, yellow, indigo, purple, teal, blue, orange, pink

    var color: Color {
        switch self {
        case .green: return Color.green
        case .yellow: return Color.yellow
        case .indigo: return Color.indigo
        case .purple: return Color.purple
        case .teal: return Color.teal
        case .blue: return Color.blue
        case .orange: return Color.orange
        case .pink: return Color.pink
        }
    }

    static var allCases: [MatchTemplateColor] {
        [.green, .yellow, .indigo, .purple, .teal, .blue, .orange, .pink]
    }
}

@Model
class MatchTemplate {
    var sport: MatchSport
    var name: String
    var color: MatchTemplateColor
    var environment: MatchEnvironment
    var scoring: MatchScoringRules
    var createdAt: Date
    var lastUsedAt: Date?
    var startWorkout: Bool

    init(
        _ sport: MatchSport, name: String, color: MatchTemplateColor = .green,
        environment: MatchEnvironment = .indoor, scoring: MatchScoringRules,
        startWorkout: Bool = true
    ) {
        self.sport = sport
        self.name = name
        self.color = color
        self.environment = environment
        self.scoring = scoring
        self.createdAt = Date()
        self.startWorkout = startWorkout
    }

    func createMatch(markAsUsed: Bool = true) -> Match {
        if markAsUsed {
            lastUsedAt = Date()
        }

        return Match(from: self, markAsUsed: markAsUsed)
    }
}

struct MatchScoringRules: Codable, Equatable {
    var setsWinAt: Int
    var setsMaximum: Int
    var playItOut: Bool
    var setScoring: MatchSetScoringRules
    var setTimebreakerScoring: MatchSetScoringRules

    var isMultiSet: Bool {
        return setsWinAt > 1
    }

    init(
        setsWinAt: Int, setsMaximum: Int? = nil, playItOut: Bool = false,
        setScoring: MatchSetScoringRules,
        setTiebreakerScoring: MatchSetScoringRules? = nil
    ) {
        self.setsWinAt = setsWinAt
        self.setsMaximum = setsMaximum ?? ((setsWinAt * 2) - 1)
        self.playItOut = playItOut
        self.setScoring = setScoring
        self.setTimebreakerScoring = setTiebreakerScoring ?? setScoring
    }

    func checkForWinner(_ match: Match) -> MatchTeam? {
        if let winner = match.winner { return winner }

        let setsUs = match.setsUs
        let setsThem = match.setsThem

        if setsUs >= setsWinAt {
            return .us
        }

        if setsThem >= setsWinAt {
            return .them
        }

        return nil
    }

    func hasWinner(_ match: Match) -> Bool {
        checkForWinner(match) != nil
    }

    func canPlayAnotherSet(_ match: Match) -> Bool {
        return playItOut
            ? (match.sets.count + 1) <= setsMaximum : !hasWinner(match)
    }
}

struct MatchSetScoringRules: Codable, Equatable {
    var gamesWinAt: Int
    var gamesMaximum: Int
    var playItOut: Bool
    var gameScoring: MatchGameScoringRules
    var gameTimebreakerScoring: MatchGameScoringRules

    var isMultiGame: Bool {
        return gamesWinAt > 1
    }

    init(
        gamesWinAt: Int, gamesMaximum: Int? = nil, playItOut: Bool = false,
        gameScoring: MatchGameScoringRules,
        gameTimebreakerScoring: MatchGameScoringRules? = nil
    ) {
        self.gamesWinAt = gamesWinAt
        self.gamesMaximum = gamesMaximum ?? ((gamesWinAt * 2) - 1)
        self.playItOut = playItOut
        self.gameScoring = gameScoring
        self.gameTimebreakerScoring = gameTimebreakerScoring ?? gameScoring
    }

    func checkForWinner(_ set: MatchSet) -> MatchTeam? {
        if let winner = set.winner { return winner }

        let gamesUs = set.gamesUs
        let gamesThem = set.gamesThem

        if gamesUs >= gamesWinAt {
            return .us
        }

        if gamesThem >= gamesWinAt {
            return .them
        }

        return nil
    }

    func hasWinner(_ game: MatchSet) -> Bool {
        checkForWinner(game) != nil
    }

    func canPlayAnotherGame(_ set: MatchSet) -> Bool {
        return playItOut
            ? (set.games.count + 1) <= gamesMaximum : !hasWinner(set)
    }
}

struct MatchGameScoringRules: Codable, Equatable {
    var winScore: Int
    var maximumScore: Int
    var winBy: Int

    init(winScore: Int, maximumScore: Int? = nil, winBy: Int = 1) {
        self.winScore = winScore
        self.maximumScore = maximumScore ?? winScore
        self.winBy = winBy
    }

    func checkForWinner(_ game: MatchGame) -> MatchTeam? {
        let scoreUs = game.scoreUs
        let scoreThem = game.scoreThem

        if scoreUs >= winScore {
            if scoreUs - scoreThem >= winBy {
                return .us
            }
        } else if scoreThem >= winScore {
            if scoreThem - scoreUs >= winBy {
                return .them
            }
        }

        return nil
    }

    func hasWinner(_ game: MatchGame) -> Bool {
        checkForWinner(game) != nil
    }
}
