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

public enum MatchSport: String, Codable {
    case volleyball
    case ultimate
    case squash
    case tennis
    
    public var label: String {
        switch self {
        case .squash: return "Squash"
        case .ultimate: return "Ultimate frisbee"
        case .volleyball: return "Volleyball"
        case .tennis: return "Tennis"
        }
    }
    
    public var figureIcon: String {
        switch self {
        case .squash: return "figure.squash"
        case .ultimate: return "figure.disc.sports"
        case .volleyball: return "figure.volleyball"
        case .tennis: return "figure.tennis"
        }
    }
    
    public var ballIcon: String {
        switch self {
        case .squash: return "circle.fill"
        case .ultimate: return "circle.circle.fill"
        case .volleyball: return "volleyball.fill"
        case .tennis: return "tennisball.fill"
        }
    }
    
    public var gameServiceRotation: MatchServiceRotation {
        switch self {
        case .tennis: return .none
        default: return .lastWinner
        }
    }
    
    public var setServiceRotation: MatchServiceRotation {
        return .every(count: 1)
    }
    
    public func normalizedScoreFor(_ team: MatchTeam, game: MatchGame) -> Int {
        let score = game.scoreFor(team)
        
        switch self {
        case .tennis:
            switch score {
            case 0: return 0
            case 1: return 15
            case 2: return 30
            default: return 40
        }
        default: return score
        }
    }
    
    public func normalizedScoreLabelFor(_ team: MatchTeam, game: MatchGame) -> String {
        let normalizedScore = normalizedScoreFor(team, game: game)
        
        if (self != .tennis) {
            return "\(normalizedScore)"
        }
        
        guard let match = game.set?.match else {
            return "\(normalizedScore)"
        }
        
        let gameScoring = match.scoring.setScoring.gameScoring
        
        if (gameScoring.winBy != 2) {
            return "\(normalizedScore)"
        }
            
        let winAt = gameScoring.winAt
        
        if let winAt {
            let score = game.scoreFor(team)
            
            if (score < winAt || (game.scoreFor(team.opposingTeam) < (winAt - 1))) {
                return "\(normalizedScore)"
            }
        }
        
        return game.leading == team ? "Ad" : "\(normalizedScore)"
    }
}

public enum MatchServiceRotation: Codable, Equatable {
    case none
    case every(count: Int)
    case lastWinner
}

public enum MatchTeam: String, Codable {
    case us, them
    
    public var opposingTeam: MatchTeam {
        self == .us ? .them : .us
    }
}

public enum MatchEnvironment: String, Codable {
    case indoor, outdoor
}

public class MatchModelContainer {
    public let schema = Schema([
        Match.self,
        MatchSet.self,
        MatchGame.self,
        MatchWarmup.self,
        MatchTemplate.self,
    ])
    
    public init() {
        
    }
    
    public func sharedModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        return try! ModelContainer(for: schema, configurations: [configuration])
    }
    
    public func testModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}

@Model
public class Match {
    public var sport: MatchSport = MatchSport.volleyball
    public var environment: MatchEnvironment = MatchEnvironment.outdoor

    @Relationship(deleteRule: .cascade, inverse: \MatchSet.match)
    public var _sets: [MatchSet]?
    public var sets: [MatchSet] {
        guard let _sets else { return [] }
        
        // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
        return _sets.sorted { $0.number < $1.number }
    }

    public var startedAt: Date = Date.now
    public var endedAt: Date?
    
    public var _scoring: MatchScoringRules?
    public var scoring: MatchScoringRules {
        _scoring ?? defaultScoringRules()
    }
    
    @Relationship
    public var template: MatchTemplate?
    
    @Relationship
    public var warmup: MatchWarmup?
    public var hasWarmup: Bool { warmup != nil }

    public var hasEnded: Bool { endedAt != nil }

    public var duration: TimeInterval { endedAt?.timeIntervalSince(startedAt) ?? 0 }

    public var latestSet: MatchSet? { sets.last }
    public var latestGame: MatchGame? { latestSet?.latestGame }
    
    public var startingServe: MatchTeam?

    public var hasMoreGames: Bool {
        if hasEnded { return false }
        guard let latestSet else { return true }

        return scoring.setScoring.canPlayAnotherGame(latestSet)
            || scoring.canPlayAnotherSet(self)
    }

    public var setsUs: Int { sets.count { $0.winner == .us } }
    public var setsThem: Int { sets.count { $0.winner == .them } }

    public var winner: MatchTeam? {
        if !hasEnded { return nil }

        let setsUs = setsUs
        let setsThem = setsThem
        return setsUs > setsThem ? .us : setsThem > setsUs ? .them : nil
    }

    public var hasWinner: Bool { winner != nil }

    public var isMultiSet: Bool { scoring.isMultiSet }
    
    public var scoreSummaryString: String? {
        if isMultiSet {
            return "\(sets.map { "\($0.gamesUs)-\($0.gamesThem)" }.joined(separator: ", "))"
        }
        
        switch sport {
        case .tennis: return nil
        default:
            guard let latestSet else { return nil }
            return "\((latestSet.games).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))"
        }
    }
    
    public var label: String {
        template?.name ?? sport.label
    }

    public init(from template: MatchTemplate, markAsUsed: Bool = true, sets: [MatchSet] = [MatchSet()], startedAt: Date = .now, endedAt: Date? = nil, startingServe: MatchTeam? = nil) {
        self.template = markAsUsed ? template : nil
        self.sport = template.sport
        self.environment = template.environment
        self._scoring = template.scoring
        self._sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.startingServe = startingServe
    }

    public init(
        _ sport: MatchSport = .volleyball,
        environment: MatchEnvironment = .indoor, scoring: MatchScoringRules,
        sets: [MatchSet] = [MatchSet()], startedAt: Date = .now,
        endedAt: Date? = nil,
        startingServe: MatchTeam? = nil
    ) {
        self.sport = sport
        self.environment = environment
        self._sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self._scoring = scoring
        self.startingServe = startingServe
    }

    public func setsFor(_ team: MatchTeam) -> Int {
        return team == .us ? setsUs : setsThem
    }

    private var debugScoreDescription: String {
        return sets.map { set in
            set.games.map { game in
                return "\(game.scoreUs)-\(game.scoreThem)"
            }.joined(separator: ", ")
        }.joined(separator: " | ")
    }

    public func scorePoint(_ team: MatchTeam) {
        guard let set = latestSet, !set.hasEnded, let game = set.latestGame,
            !game.hasEnded
        else { return }

        game.scorePoint(team)

        if scoring.setScoring.gameScoring.hasWinner(game) {
            game.endedAt = Date.now

            if !scoring.setScoring.canPlayAnotherGame(set) {
                set.endedAt = Date.now
            }
        }
    }
    
    public var canUndo: Bool {
        guard let game = latestGame else { return false }
        return game.canUndo
    }

    public func undo() {
        guard let game = latestGame else { return }
        game.undo()
    }
    
    public func startWarmup() {
        if warmup != nil { return }

        warmup = MatchWarmup(startedAt: Date.now)
    }

    public func startGame() {
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

    public func end() {
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
        let latestSet = latestSet
        let latestNumber = latestSet?.number ?? 0
        let latestStartingServe = latestSet?.startingServe
        
        let set = MatchSet(number: latestNumber + 1, startedAt: startedAt, startingServe: latestStartingServe?.opposingTeam)
        
        var sets = self.sets
        sets.append(set)
        _sets = sets
    }
}

@Model
public class MatchSet {
    public var match: Match?
    
    public var number: Int = 1
    
    @Relationship(deleteRule: .cascade, inverse: \MatchGame.set)
    public var _games: [MatchGame]?
    public var games: [MatchGame] {
        guard let _games else { return [] }

        // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
        return _games.sorted { $0.number < $1.number }
    }
    public var latestGame: MatchGame? { games.last }

    public var createdAt: Date = Date.now
    public var startedAt: Date = Date.now
    public var endedAt: Date?

    public var hasEnded: Bool { endedAt != nil }

    public var gamesUs: Int { games.count { $0.winner == .us } }
    public var gamesThem: Int { games.count { $0.winner == .them } }

    public var winner: MatchTeam? {
        if !hasEnded { return nil }

        let gamesUs = gamesUs
        let gamesThem = gamesThem
        return gamesUs > gamesThem ? .us : gamesThem > gamesUs ? .them : nil
    }

    public var hasWinner: Bool { winner != nil }

    public var isTied: Bool {
        gamesUs == gamesThem
    }
    
    public var isMultiGame: Bool { match?.scoring.setScoring.isMultiGame ?? true }
    
    public var startingServe: MatchTeam? { games.first?.startingServe }
    
    public var isLatestInMatch: Bool {
        guard let latestSet = match?.latestSet else { return false }
        return latestSet.number == number
    }

    public init(
        number: Int = 1, games: [MatchGame]? = nil,
        startedAt: Date = Date(), endedAt: Date? = nil, startingServe: MatchTeam? = nil
    ) {
        let games = games ?? [MatchGame(startedAt: startedAt, startingServe: startingServe)]
        for game in games {
            game.set = self
        }
        
        self.number = number
        self._games = games
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
    }

    public func gamesFor(_ team: MatchTeam) -> Int {
        return team == .us ? gamesUs : gamesThem
    }
    
    public func startGame(startedAt: Date = .now, startingServe: MatchTeam? = nil) {
        let latestGame = latestGame
        let latestNumber = latestGame?.number ?? 0
        let latestStartingServe = latestGame?.startingServe
        
        let game = MatchGame(number: latestNumber + 1, startedAt: startedAt, startingServe: startingServe ?? latestStartingServe?.opposingTeam)

        var games = self.games
        games.append(game)
        self._games = games
    }
}

@Model
public class MatchGame {
    public var set: MatchSet?
    public var match: Match? { self.set?.match }
    
    public var number: Int = 1

    public var createdAt: Date = Date.now
    public var startedAt: Date = Date.now
    public var endedAt: Date?

    public var _scores: [MatchGameScore]?
    public var scores: [MatchGameScore] {
        guard let scores = _scores else { return [] }
        
        return scores.sorted { $0.timestamp < $1.timestamp }
    }
    
    public var scoreUs: Int { _scores?.reduce(0) { $0 + $1.us } ?? 0 }
    public var scoreThem: Int { _scores?.reduce(0) { $0 + $1.them } ?? 0 }

    public var hasEnded: Bool { endedAt != nil }
    
    public var leading: MatchTeam? {
        let scoreUs = scoreUs, scoreThem = scoreThem
        
        if scoreUs > scoreThem { return .us }
        if scoreThem > scoreUs { return .them }
        return nil
    }

    public var winner: MatchTeam? {
        if !hasEnded { return nil }

        let scoreUs = scoreUs
        let scoreThem = scoreThem
        return scoreUs > scoreThem ? .us : scoreThem > scoreUs ? .them : nil
    }

    public var hasWinner: Bool { winner != nil }

    public var isTied: Bool {
        scoreUs == scoreThem
    }

    public var startingServe: MatchTeam?

    public var servingTeam: MatchTeam? {
        if hasEnded { return nil }
        
        let sport = set?.match?.sport
        let serviceRotation = sport?.gameServiceRotation ?? .lastWinner

        if (serviceRotation == .lastWinner) {
            if let lastScore = scores.last(where: { $0.source == .point }) {
                return lastScore.us > lastScore.them ? .us : .them
            }
        }

        return startingServe
    }
    
    public var isLatestInSet: Bool {
        guard let latestGame = set?.latestGame else { return false }
        return latestGame.number == number
    }

    public init(
        number: Int = 1,
        scores: [MatchGameScore] = [],
        startedAt: Date = .now,
        endedAt: Date? = nil,
        startingServe: MatchTeam? = nil
    ) {
        self.number = number
        self._scores = scores
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = .now
        self.startingServe = startingServe
    }
    
    public init(
        number: Int = 1,
        us: Int,
        them: Int,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        startingServe: MatchTeam? = nil
    ) {
        // Append an amount of `MatchTeam`s to an array, according to the `us` and `them` values
        let usScores: [MatchGameScore] = Array(repeating: MatchGameScore(.us, at: startedAt), count: us)
        let themScores: [MatchGameScore] = Array(repeating: MatchGameScore(.them, at: startedAt), count: them)
        
        self._scores = (usScores + themScores).shuffled()
     
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = .now
        self.startingServe = startingServe
    }

    public func scorePoint(_ team: MatchTeam, at timestamp: Date = .now) {
        var scores = self._scores ?? []
        
        let score = MatchGameScore(team, serve: servingTeam, at: timestamp);
        
        scores.append(score)
        _scores = scores
    }

    public var canUndo: Bool {
        // There must be at least one score whose source was a real point
        guard let scores = _scores else { return false }
        return scores.contains { $0.source == .point }
    }

    public func undo() {
        var scores = self.scores
        if scores.isEmpty { return }

        guard let idx = scores.lastIndex(where: { $0.source == .point }) else { return }

        scores.remove(at: idx)
        self._scores = scores

        self.endedAt = nil
        // TODO: what to do if this is in the middle of a set?
        if let set = set, set.endedAt != nil { set.endedAt = nil }
        if let match = match, match.endedAt != nil { match.endedAt = nil }
    }

    public func scoreFor(_ team: MatchTeam) -> Int {
        team == .us ? scoreUs : scoreThem
    }
    
    public func serveStreakFor(_ team: MatchTeam) -> Int {
        var streak = 0
        
        for score in scores.sorted(by: { $0.timestamp > $1.timestamp }) {
            if score.source != .point || score.adjustment(team) < 1 || score.serve != team { break }
            streak += 1
        }
        
        return streak
    }
}

public enum MatchGameScoreSource: String, Codable {
    case point, edit
}

public struct MatchGameScore: Codable, Equatable {
    public var us: Int
    public var them: Int
    public var timestamp: Date
    public var source: MatchGameScoreSource
    public var serve: MatchTeam?
    
    public init(us: Int = 0, them: Int = 0, serve: MatchTeam? = nil, at timestamp: Date = .now, source: MatchGameScoreSource = .point) {
        self.us = us
        self.them = them
        self.timestamp = timestamp
        self.serve = serve
        self.source = source
    }
    
    public init(_ team: MatchTeam, serve: MatchTeam? = nil, at timestamp: Date = .now) {
        self.us = team == .us ? 1 : 0
        self.them = team == .them ? 1 : 0
        self.timestamp = timestamp
        self.serve = serve
        self.source = .point
    }
    
    public func adjustment(_ team: MatchTeam) -> Int {
        switch team {
        case .us:
            return us
        case .them:
            return them
        }
    }
}

@Model
public class MatchWarmup {
    @Relationship(inverse: \Match.warmup)
    public var match: Match?
    
    public var createdAt: Date = Date.now
    public var startedAt: Date = Date.now
    public var endedAt: Date?
    
    public var hasEnded: Bool { endedAt != nil }
    
    public init(
        startedAt: Date = Date.now,
        endedAt: Date? = nil
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date.now
    }
    
    public func end() {
        if hasEnded { return }
        endedAt = Date.now
    }
}

public enum MatchTemplateColor: String, Codable {
    case green, yellow, indigo, purple, teal, blue, orange, pink

    public var color: Color {
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

    public static var allCases: [MatchTemplateColor] {
        [.green, .yellow, .indigo, .purple, .teal, .blue, .orange, .pink]
    }
}

@Model
public class MatchTemplate {
    @Relationship(inverse: \Match.template)
    public var _matches: [Match]?
    
    public var sport: MatchSport = MatchSport.volleyball
    public var name: String = "Volleyball"
    public var color: MatchTemplateColor = MatchTemplateColor.green
    public var environment: MatchEnvironment = MatchEnvironment.indoor
    public var _scoring: MatchScoringRules?
    public var scoring: MatchScoringRules {
        get { _scoring ?? defaultScoringRules() }
        set { _scoring = newValue }
    }
    
    public var createdAt: Date = Date.now
    public var lastUsedAt: Date?
    public var warmup: MatchWarmupRules = MatchWarmupRules.none
    public var startWorkout: Bool = true

    public init(
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

    public func createMatch(markAsUsed: Bool = true) -> Match {
        if markAsUsed {
            lastUsedAt = Date()
        }

        return Match(from: self, markAsUsed: markAsUsed)
    }
}

public enum MatchWarmupRules: Codable, Equatable {
    case none
    case open
}

public struct MatchScoringRules: Codable, Equatable {
    public var winAt: Int? = nil
    public var winBy: Int? = nil
    public var maximum: Int? = nil
    public var playItOut: Bool = false
    public var setScoring: MatchSetScoringRules
    public var lastSetScoring: MatchSetScoringRules? = nil
    
    public init(winAt: Int? = nil, winBy: Int? = nil, maximum: Int? = nil, playItOut: Bool = false, setScoring: MatchSetScoringRules, lastSetScoring: MatchSetScoringRules? = nil) {
        self.winAt = winAt
        self.winBy = winBy
        self.maximum = maximum
        self.playItOut = playItOut
        self.setScoring = setScoring
        self.lastSetScoring = lastSetScoring
    }

    public var isMultiSet: Bool {
        guard let winAt else { return false }
        return winAt > 1
    }
    
    public var primaryLabel: String {
        guard let winAt, let maximumSetCount else { return "Open match" }
        
        if winAt == 1 {
            return setScoring.primaryLabel
        }
        
        if playItOut {
            return "Best of \(maximumSetCount) sets"
        }

        return "First to \(winAt) sets"
    }

    public var secondaryLabel: String {
        if winAt == nil { return "" }
        
        return setScoring.secondaryLabel
    }

    public func checkForWinner(_ match: Match) -> MatchTeam? {
        if let winner = match.winner { return winner }
        
        guard let winAt else { return nil }
        
        let winBy = self.winBy ?? 1
        
        let setsUs = match.setsUs, setsThem = match.setsThem

        if setsUs >= winAt {
            if (setsUs - setsThem >= winBy) || (maximum != nil && (setsUs >= maximum!)) {
                return .us
            }
        }
        
        if setsThem >= winAt {
            if (setsThem - setsUs >= winBy) || (maximum != nil && (setsThem >= maximum!)) {
                return .them
            }
        }

        return nil
    }

    public func hasWinner(_ match: Match) -> Bool {
        checkForWinner(match) != nil
    }

    public func canPlayAnotherSet(_ match: Match) -> Bool {
        if winAt == nil { return true }
        
        if hasWinner(match) && !playItOut { return false }
        
        guard let maximumSetCount else { return true }
        
        return match.sets.count < maximumSetCount
    }
    
    public var maximumSetCount: Int? {
        if let maximum { return (maximum * 2) - 1 }
        if let winAt { return (winAt * 2) - 1 }
        return nil
    }
}

public struct MatchSetScoringRules: Codable, Equatable {
    public var winAt: Int? = nil
    public var winBy: Int? = nil
    public var maximum: Int? = nil
    public var playItOut: Bool = false
    public var gameScoring: MatchGameScoringRules
    public var lastGameScoring: MatchGameScoringRules? = nil
    
    public init(winAt: Int? = nil, winBy: Int? = nil, maximum: Int? = nil, playItOut: Bool = false, gameScoring: MatchGameScoringRules, lastGameScoring: MatchGameScoringRules? = nil) {
        self.winAt = winAt
        self.winBy = winBy
        self.maximum = maximum
        self.playItOut = playItOut
        self.gameScoring = gameScoring
        self.lastGameScoring = lastGameScoring
    }

    public var isMultiGame: Bool {
        guard let winAt else { return false }
        return winAt > 1
    }
    
    public var primaryLabel: String {
        guard let winAt, let maximumGameCount else { return "Open set" }
        
        if winAt == 1 {
            return gameScoring.primaryLabel
        }
        
        if playItOut {
            return "Best of \(maximumGameCount) games"
        }
        
        return "First to \(winAt) games"
    }

    public var secondaryLabel: String {
        guard let winAt, winAt > 1 else { return "" }
        
        guard let gamesWinAt = gameScoring.winAt else { return "Open games" }
        
        return "Games to \(gamesWinAt) points"
    }

    public func checkForWinner(_ set: MatchSet) -> MatchTeam? {
        if let winner = set.winner { return winner }
        
        guard let winAt else { return nil }
        
        let winBy = self.winBy ?? 1
        
        let gamesUs = set.gamesUs, gamesThem = set.gamesThem

        if gamesUs >= winAt {
            if (gamesUs - gamesThem >= winBy) || (maximum != nil && (gamesUs >= maximum!)) {
                return .us
            }
        }
        
        if gamesThem >= winAt {
            if (gamesThem - gamesUs >= winBy) || (maximum != nil && (gamesThem >= maximum!)) {
                return .them
            }
        }

        return nil
    }

    public func hasWinner(_ set: MatchSet) -> Bool {
        checkForWinner(set) != nil
    }

    public func canPlayAnotherGame(_ set: MatchSet) -> Bool {
        if winAt == nil { return true }
        
        print("MatchSetScoringRules.canPlayAnotherGame()")
        print("match: \(set.match?.scoreSummaryString ?? "<no match>")")
        print("winAt: \(winAt ?? -1), hasWinner: \(hasWinner(set)), playItOut: \(playItOut), impliedMaximumGameNumber: \(maximumGameCount ?? -1)")
        
        if hasWinner(set) && !playItOut { return false }
        
        guard let maximumGameCount else { return true }
        
        return set.games.count < maximumGameCount
    }
    
    public var maximumGameCount: Int? {
        if let maximum { return (maximum * 2) - 1 }
        if let winAt { return (winAt * 2) - 1 }
        return nil
    }
}

public struct MatchGameScoringRules: Codable, Equatable {
    public var winAt: Int? = nil
    public var winBy: Int? = nil
    public var maximum: Int? = nil
    
    public init(winAt: Int? = nil, winBy: Int? = nil, maximum: Int? = nil) {
        self.winAt = winAt
        self.winBy = winBy
        self.maximum = maximum
    }

    public var primaryLabel: String {
        guard let winAt else { return "Open game" }
        
        return "First to \(winAt) points"
    }

    public func checkForWinner(_ game: MatchGame) -> MatchTeam? {
        if let winner = game.winner { return winner }
        
        guard let winAt else { return nil }
        
        let winBy = self.winBy ?? 1
        
        let scoreUs = game.scoreUs, scoreThem = game.scoreThem

        if scoreUs >= winAt {
            if (scoreUs - scoreThem >= winBy) || (maximum != nil && (scoreUs >= maximum!)) {
                return .us
            }
        }
        
        if scoreThem >= winAt {
            if (scoreThem - scoreUs >= winBy) || (maximum != nil && (scoreThem >= maximum!)) {
                return .them
            }
        }

        return nil
    }

    public func hasWinner(_ game: MatchGame) -> Bool {
        checkForWinner(game) != nil
    }
}

public func defaultScoringRules() -> MatchScoringRules {
    MatchScoringRules(
        winAt: 2,
        setScoring: MatchSetScoringRules(
            winAt: 3,
            gameScoring: MatchGameScoringRules(winAt: 25)
        )
    )
}
