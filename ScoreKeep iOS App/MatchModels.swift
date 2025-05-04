//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftData
import SwiftUI
import CloudKit

enum MatchSport: String, Codable {
    case volleyball
}

enum MatchTeam: String, Codable {
    case us, them
}

enum MatchEnvironment: String, Codable {
    case indoor, outdoor
}

class MatchModelContainer {
    let schema = Schema([
        Match.self,
        MatchSet.self,
        MatchGame.self,
        MatchWarmup.self,
        MatchTemplate.self,
    ])
    
    func sharedModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        return try! ModelContainer(for: schema, configurations: [configuration])
    }
    
    func testModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}

@Model
class Match {
    var sport: MatchSport = MatchSport.volleyball
    var environment: MatchEnvironment = MatchEnvironment.outdoor

    @Relationship(inverse: \MatchSet.match)
    var _sets: [MatchSet]?
    var sets: [MatchSet] {
        guard let _sets else { return [] }
        
        // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
        return _sets.sorted { $0.number < $1.number }
    }

    var startedAt: Date = Date.now
    var endedAt: Date?
    
    var _scoring: MatchScoringRules?
    var scoring: MatchScoringRules {
        _scoring ?? defaultScoringRules()
    }
    
    @Relationship
    var template: MatchTemplate?
    
    @Relationship
    var warmup: MatchWarmup?
    var hasWarmup: Bool { warmup != nil }

    var hasEnded: Bool { endedAt != nil }

    var duration: TimeInterval { endedAt?.timeIntervalSince(startedAt) ?? 0 }

    var latestSet: MatchSet? { sets.last }
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
            return "\(sets.map { "\($0.gamesUs)-\($0.gamesThem)" }.joined(separator: ", "))"
        }
        
        return "\((latestSet?.games ?? []).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))"
    }

    init(from template: MatchTemplate, markAsUsed: Bool = true) {
        self.template = markAsUsed ? template : nil
        self.sport = template.sport
        self.environment = template.environment
        self._scoring = template.scoring
        self._sets = [MatchSet()]
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
        self._sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self._scoring = scoring
    }

    func setsFor(_ team: MatchTeam) -> Int {
        return team == .us ? setsUs : setsThem
    }

    private var debugScoreDescription: String {
        return sets.map { set in
            set.games.map { game in
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
            game.endedAt = Date.now

            if !scoring.setScoring.canPlayAnotherGame(set) {
                set.endedAt = Date.now
            }
        }
    }
    
    func startWarmup() {
        if warmup != nil { return }

        warmup = MatchWarmup(startedAt: Date.now)
    }

    func startGame() {
        let now = Date.now
        
        if let warmup {
            warmup.end()
        }

        if latestSet == nil {
            addSet(startedAt: now)
        }

        guard let latestSet else { return }

        guard let latestGame = latestSet.latestGame else {
            latestSet.startGame(startedAt: now)
            return
        }

        latestGame.endedAt = now

        if scoring.setScoring.canPlayAnotherGame(latestSet) {
            latestSet.startGame(startedAt: now)
            return
        }

        latestSet.endedAt = now

        if scoring.hasWinner(self) && !scoring.playItOut {
            return
        }

        addSet(startedAt: now)
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
    
    private func addSet(startedAt: Date = .now) {
        let latestNumber = latestSet?.number ?? 0
        
        let set = MatchSet(number: latestNumber + 1, startedAt: startedAt)
        set.match = self
        
        var sets = _sets ?? []
        sets.append(set)
        _sets = sets
    }
}

@Model
class MatchSet {
    @Relationship
    var match: Match?
    
    var number: Int = 1
    
    @Relationship(inverse: \MatchGame.set)
    var _games: [MatchGame]?
    var games: [MatchGame] {
        guard let _games else { return [] }

        // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
        return _games.sorted { $0.number < $1.number }
    }
    var latestGame: MatchGame? { games.last }

    var createdAt: Date = Date.now
    var startedAt: Date = Date.now
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
        number: Int = 1, games: [MatchGame]? = nil,
        startedAt: Date = Date(), endedAt: Date? = nil
    ) {
        self.number = number
        self._games = games ?? [MatchGame(startedAt: startedAt)]
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
    }

    func gamesFor(_ team: MatchTeam) -> Int {
        return team == .us ? gamesUs : gamesThem
    }
    
    func startGame(startedAt: Date = .now) {
        let latestNumber = latestGame?.number ?? 0
        
        let game = MatchGame(number: latestNumber + 1, startedAt: startedAt)
        game.set = self
        
        var games = _games ?? []
        games.append(game)
        _games = games
    }
}

@Model
class MatchGame {
    @Relationship
    var set: MatchSet?
    
    var number: Int = 1

    var scoreUs: Int = 0
    var scoreThem: Int = 0

    var createdAt: Date = Date.now
    var startedAt: Date = Date.now
    var endedAt: Date?

    var _scores: [MatchGameScore]?
    var scores: [MatchGameScore] {
        guard let scores = _scores else { return [] }
        
        return scores.sorted { $0.timestamp < $1.timestamp }
    }

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

        if let lastScore = scores.last {
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
        self._scores = scores
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
        
        var scores = self._scores ?? []
        scores.append(
            MatchGameScore(
                team: team, change: finalTo - currentScore, total: finalTo,
                timestamp: timestamp)
        )
        _scores = scores
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

@Model
class MatchWarmup {
    @Relationship(inverse: \Match.warmup)
    var match: Match?
    
    var createdAt: Date = Date.now
    var startedAt: Date = Date.now
    var endedAt: Date?
    
    var hasEnded: Bool { endedAt != nil }
    
    init(
        startedAt: Date = Date.now,
        endedAt: Date? = nil
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date.now
    }
    
    func end() {
        if hasEnded { return }
        endedAt = Date.now
    }
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
    @Relationship(inverse: \Match.template)
    var _matches: [Match]?
    
    var sport: MatchSport = MatchSport.volleyball
    var name: String = "Volleyball"
    var color: MatchTemplateColor = MatchTemplateColor.green
    var environment: MatchEnvironment = MatchEnvironment.indoor
    var _scoring: MatchScoringRules?
    var scoring: MatchScoringRules {
        get { _scoring ?? defaultScoringRules() }
        set { _scoring = newValue }
    }
    
    var createdAt: Date = Date.now
    var lastUsedAt: Date?
    var warmup: MatchWarmupRules = MatchWarmupRules.none
    var startWorkout: Bool = true

    init(
        _ sport: MatchSport, name: String, color: MatchTemplateColor = .green,
        environment: MatchEnvironment = .indoor, scoring: MatchScoringRules,
        warmup: MatchWarmupRules = .none,
        startWorkout: Bool = true
    ) {
        self.sport = sport
        self.name = name
        self.color = color
        self.environment = environment
        self._scoring = scoring
        self.createdAt = Date()
        self.warmup = warmup
        self.startWorkout = startWorkout
    }

    func createMatch(markAsUsed: Bool = true) -> Match {
        if markAsUsed {
            lastUsedAt = Date()
        }

        return Match(from: self, markAsUsed: markAsUsed)
    }
}

enum MatchWarmupRules: Codable, Equatable {
    case none
    case open
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
        return playItOut ? (match.sets.count + 1) <= setsMaximum : !hasWinner(match)
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

private func defaultScoringRules() -> MatchScoringRules {
    MatchScoringRules(
        setsWinAt: 2,
        setScoring: MatchSetScoringRules(
            gamesWinAt: 3,
            gameScoring: MatchGameScoringRules(winScore: 25)
        )
    )
}
