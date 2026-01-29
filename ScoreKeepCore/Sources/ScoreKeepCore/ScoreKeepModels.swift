//
// ScoreKeepModels.swift
// ScoreKeepCore
//
//  Created by Chris Sauve on 2025-11-21.
//

import CloudKit
import Foundation
import SwiftData
import SwiftUI

public enum ScoreKeepSport: String, Codable {
    case volleyball
    case ultimate
    case squash
    case tennis
    case pickleball

    public var label: String {
        switch self {
        case .squash: return "Squash"
        case .ultimate: return "Ultimate frisbee"
        case .volleyball: return "Volleyball"
        case .tennis: return "Tennis"
        case .pickleball: return "Pickleball"
        }
    }

    public var figureIcon: String {
        switch self {
        case .squash: return "figure.squash"
        case .ultimate: return "figure.disc.sports"
        case .volleyball: return "figure.volleyball"
        case .tennis: return "figure.tennis"
        case .pickleball: return "figure.pickleball"
        }
    }

    public var ballIcon: String {
        switch self {
        case .squash: return "circle.fill"
        case .ultimate: return "circle.circle.fill"
        case .volleyball: return "volleyball.fill"
        case .tennis: return "tennisball.fill"
        case .pickleball: return "circle.fill"
        }
    }

    public var gameServiceRotation: ScoreKeepServiceRotationRule {
        switch self {
        case .tennis: return .none
        default: return .lastWinner
        }
    }

    public var setServiceRotation: ScoreKeepServiceRotationRule {
        return .every(count: 1)
    }

    public var gameServiceScoring: ScoreKeepServiceScoringRule {
        switch self {
        case .pickleball: return .sideOut
        default: return .rally
        }
    }

    public func normalizedScoreFor(_ team: ScoreKeepTeam, game: ScoreKeepGame) -> Int {
        let score = game.scoreFor(team)

        switch self {
        case .tennis:
            if let winAt = game.rules?.winAt, winAt != 4 {
                return score
            }

            switch score {
            case 0: return 0
            case 1: return 15
            case 2: return 30
            default: return 40
            }
        default: return score
        }
    }

    public func normalizedScoreLabelFor(_ team: ScoreKeepTeam, game: ScoreKeepGame) -> String {
        let normalizedScore = normalizedScoreFor(team, game: game)

        if self != .tennis {
            return "\(normalizedScore)"
        }

        guard let match = game.set?.match else {
            return "\(normalizedScore)"
        }

        let gameScoring = match.rules.setRules.gameRules

        if gameScoring.winBy != 2 {
            return "\(normalizedScore)"
        }

        let winAt = gameScoring.winAt

        if let winAt {
            let score = game.scoreFor(team)

            if score < winAt || (game.scoreFor(team.opposingTeam) < (winAt - 1)) {
                return "\(normalizedScore)"
            }
        }

        return game.leading == team ? "Ad" : "\(normalizedScore)"
    }

    public func defaultRules(environment: ScoreKeepActivityEnvironment = .outdoor) -> ScoreKeepMatchRules {
        switch self {
        case .volleyball:
            return ScoreKeepMatchRules(
                winAt: 1,
                setRules: ScoreKeepSetRules(
                    winAt: 2,
                    gameRules: ScoreKeepGameRules(
                        winAt: 25,
                        winBy: 2,
                        maximum: 27
                    )
                )
            )
        case .tennis:
            return ScoreKeepMatchRules(
                winAt: 1,
                setRules: ScoreKeepSetRules(
                    winAt: 6,
                    winBy: 2,
                    maximum: 7,
                    gameRules: ScoreKeepGameRules(
                        winAt: 4,
                        winBy: 2
                    ),
                    lastGameRules: ScoreKeepGameRules(
                        winAt: 7,
                        winBy: 2
                    )
                )
            )
        case .pickleball:
            return ScoreKeepMatchRules(
                winAt: 1,
                setRules: ScoreKeepSetRules(
                    winAt: 2,
                    gameRules: ScoreKeepGameRules(
                        winAt: 11,
                        winBy: 2
                    )
                )
            )
        case .squash:
            return ScoreKeepMatchRules(
                winAt: 1,
                setRules: ScoreKeepSetRules(
                    winAt: 3,
                    gameRules: ScoreKeepGameRules(
                        winAt: 11,
                        winBy: 2
                    )
                )
            )
        case .ultimate:
            return ScoreKeepMatchRules(
                winAt: 1,
                setRules: ScoreKeepSetRules(
                    winAt: 1,
                    gameRules: ScoreKeepGameRules(
                        winAt: 15
                    )
                )
            )
        }
    }
}

public enum ScoreKeepServiceRotationRule: Codable, Equatable {
    case none
    case every(count: Int)
    case lastWinner
}

public enum ScoreKeepServiceScoringRule: Codable, Equatable {
    case rally
    case sideOut
}

public enum ScoreKeepTeam: String, Codable {
    case us, them

    public var opposingTeam: ScoreKeepTeam {
        self == .us ? .them : .us
    }

    public var defaultColor: ScoreKeepTeamColor {
        self == .us ? .blue : .red
    }

    public func defaultLabel(size: Int? = 1) -> String {
        switch self {
        case .us: return size == 1 ? "You" : "Us"
        case .them: return "Opponent"
        }
    }

    public func defaultShortLabel(size: Int? = 1) -> String {
        switch self {
        case .us: return defaultLabel(size: size)
        case .them: return "Opp"
        }
    }

}

public enum ScoreKeepActivityEnvironment: String, Codable {
    case indoor, outdoor
}

@Model
public class ScoreKeepMatch {
    public var sport: ScoreKeepSport = ScoreKeepSport.volleyball
    public var environment: ScoreKeepActivityEnvironment = ScoreKeepActivityEnvironment.outdoor

    @Relationship(deleteRule: .cascade, inverse: \ScoreKeepSet.match)
    public var _sets: [ScoreKeepSet]?
    public var sets: [ScoreKeepSet] {
        guard let _sets else { return [] }

        // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
        return _sets.sorted { $0.number < $1.number }
    }

    public var startedAt: Date = Date.now
    public var endedAt: Date?

    public var _rules: ScoreKeepMatchRules?
    public var rules: ScoreKeepMatchRules {
        _rules ?? ScoreKeepMatchRules()
    }

    @Relationship(deleteRule: .noAction, inverse: \ScoreKeepMatchTemplate._matches)
    public var template: ScoreKeepMatchTemplate?

    @Relationship(deleteRule: .cascade, inverse: \ScoreKeepWarmup.match)
    public var warmup: ScoreKeepWarmup?
    public var hasWarmup: Bool { warmup != nil }

    public var hasEnded: Bool { endedAt != nil }

    public var duration: TimeInterval { endedAt?.timeIntervalSince(startedAt) ?? 0 }

    public var latestSet: ScoreKeepSet? { sets.last }
    public var latestGame: ScoreKeepGame? { latestSet?.latestGame }

    public var startingServe: ScoreKeepTeam?

    public var hasMoreGames: Bool {
        if hasEnded { return false }
        guard let latestSet else { return true }

        return rules.setRules.canPlayAnotherGame(latestSet)
            || rules.canPlayAnotherSet(self)
    }

    public var setsUs: Int { sets.count { $0.winner == .us } }
    public var setsThem: Int { sets.count { $0.winner == .them } }

    public var winner: ScoreKeepTeam? {
        if !hasEnded { return nil }

        let setsUs = setsUs
        let setsThem = setsThem
        return setsUs > setsThem ? .us : setsThem > setsUs ? .them : nil
    }

    public var hasWinner: Bool { winner != nil }

    public var isMultiSet: Bool { rules.isMultiSet }

    public var scoreSummaryString: String? {
        if isMultiSet {
            return "\(sets.map { "\($0.gamesUs)-\($0.gamesThem)" }.joined(separator: ", "))"
        }

        switch sport {
        case .tennis: return nil
        default:
            guard let latestSet else { return nil }
            return
                "\((latestSet.games).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))"
        }
    }

    public var label: String {
        template?.name ?? sport.label
    }

    public init(
        from template: ScoreKeepMatchTemplate, markAsUsed: Bool = true,
        sets: [ScoreKeepSet] = [ScoreKeepSet()], startedAt: Date = .now, endedAt: Date? = nil,
        startingServe: ScoreKeepTeam? = nil
    ) {
        self.template = markAsUsed ? template : nil
        self.sport = template.sport
        self.environment = template.environment
        self._rules = template.rules
        self._sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.startingServe = startingServe
    }

    public init(
        _ sport: ScoreKeepSport = .volleyball,
        environment: ScoreKeepActivityEnvironment = .indoor,
        rules: ScoreKeepMatchRules = ScoreKeepMatchRules(),
        sets: [ScoreKeepSet] = [ScoreKeepSet()],
        startedAt: Date = .now,
        endedAt: Date? = nil,
        startingServe: ScoreKeepTeam? = nil
    ) {
        self.sport = sport
        self.environment = environment
        self._sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self._rules = rules
        self.startingServe = startingServe
    }

    public func setsFor(_ team: ScoreKeepTeam) -> Int {
        return team == .us ? setsUs : setsThem
    }

    private var debugScoreDescription: String {
        return sets.map { set in
            set.games.map { game in
                return "\(game.scoreUs)-\(game.scoreThem)"
            }.joined(separator: ", ")
        }.joined(separator: " | ")
    }

    public func scorePoint(_ team: ScoreKeepTeam) {
        guard let game = latestGame else { return }
        game.scorePoint(team)
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

        warmup = ScoreKeepWarmup(startedAt: .now)
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

        if rules.setRules.canPlayAnotherGame(latestSet) {
            latestSet.startGame(startedAt: now)
            return
        }

        latestSet.endedAt = now

        if rules.hasWinner(self) && rules.winBehavior == .end {
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

        let set = ScoreKeepSet(
            number: latestNumber + 1, startedAt: startedAt,
            startingServe: latestStartingServe?.opposingTeam)

        var sets = self.sets
        sets.append(set)
        _sets = sets
    }
}

@Model
public class ScoreKeepSet {
    public var match: ScoreKeepMatch?
    public var rules: ScoreKeepSetRules? { self.match?.rules.setRulesFor(self) }

    public var number: Int = 1

    @Relationship(deleteRule: .cascade, inverse: \ScoreKeepGame.set)
    public var _games: [ScoreKeepGame]?
    public var games: [ScoreKeepGame] {
        guard let _games else { return [] }

        // @see https://stackoverflow.com/questions/76889986/swiftdata-ios-17-array-in-random-order
        return _games.sorted { $0.number < $1.number }
    }
    public var latestGame: ScoreKeepGame? { games.last }

    public var createdAt: Date = Date.now
    public var startedAt: Date = Date.now
    public var endedAt: Date?

    public var hasEnded: Bool { endedAt != nil }

    public var gamesUs: Int { games.count { $0.winner == .us } }
    public var gamesThem: Int { games.count { $0.winner == .them } }

    public var winner: ScoreKeepTeam? {
        if !hasEnded { return nil }

        let gamesUs = gamesUs
        let gamesThem = gamesThem
        return gamesUs > gamesThem ? .us : gamesThem > gamesUs ? .them : nil
    }

    public var hasWinner: Bool { winner != nil }

    public var hasMoreGames: Bool {
        guard let rules = match?.rules.setRulesFor(self) else { return true }
        return rules.canPlayAnotherGame(self)
    }

    public var isTied: Bool {
        gamesUs == gamesThem
    }

    public var isMultiGame: Bool { match?.rules.setRules.isMultiGame ?? true }

    public var startingServe: ScoreKeepTeam? { games.first?.startingServe }

    public var isLatestInMatch: Bool {
        guard let latestSet = match?.latestSet else { return false }
        return latestSet.number == number
    }

    public var isLastInMatch: Bool {
        guard let maximumSets = match?.rules.maximumSetCount else { return false }
        return maximumSets == number
    }

    public init(
        number: Int = 1, games: [ScoreKeepGame]? = nil,
        startedAt: Date = Date(), endedAt: Date? = nil, startingServe: ScoreKeepTeam? = nil
    ) {
        let games = games ?? [ScoreKeepGame(startedAt: startedAt, startingServe: startingServe)]
        for game in games {
            game.set = self
        }

        self.number = number
        self._games = games
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
    }

    public func gamesFor(_ team: ScoreKeepTeam) -> Int {
        return team == .us ? gamesUs : gamesThem
    }

    public func startGame(startedAt: Date = .now, startingServe: ScoreKeepTeam? = nil) {
        let latestGame = latestGame
        let latestNumber = latestGame?.number ?? 0
        let latestStartingServe = latestGame?.startingServe

        let game = ScoreKeepGame(
            number: latestNumber + 1, startedAt: startedAt,
            startingServe: startingServe ?? latestStartingServe?.opposingTeam)

        var games = self.games
        games.append(game)
        self._games = games
    }
}

@Model
public class ScoreKeepGame {
    public var set: ScoreKeepSet?
    public var match: ScoreKeepMatch? { self.set?.match }
    public var rules: ScoreKeepGameRules? { self.set?.rules?.gameRulesFor(game: self) }

    public var number: Int = 1

    public var createdAt: Date = Date.now
    public var startedAt: Date = Date.now
    public var endedAt: Date?

    public var _scores: [ScoreKeepGameScore]?
    public var scores: [ScoreKeepGameScore] {
        guard let scores = _scores else { return [] }

        return scores.sorted { $0.timestamp < $1.timestamp }
    }

    public var scoreUs: Int { _scores?.reduce(0) { $0 + $1.us } ?? 0 }
    public var scoreThem: Int { _scores?.reduce(0) { $0 + $1.them } ?? 0 }

    public var hasEnded: Bool { endedAt != nil }

    public var leading: ScoreKeepTeam? {
        let scoreUs = scoreUs
        let scoreThem = scoreThem

        if scoreUs > scoreThem { return .us }
        if scoreThem > scoreUs { return .them }
        return nil
    }

    public var winner: ScoreKeepTeam? {
        if !hasEnded { return nil }

        let scoreUs = scoreUs
        let scoreThem = scoreThem
        return scoreUs > scoreThem ? .us : scoreThem > scoreUs ? .them : nil
    }

    public var hasWinner: Bool { winner != nil }

    public var isTied: Bool {
        scoreUs == scoreThem
    }

    public var startingServe: ScoreKeepTeam?

    public var servingTeam: ScoreKeepTeam? {
        if hasEnded { return nil }

        let sport = set?.match?.sport
        let serviceRotation = sport?.gameServiceRotation ?? .lastWinner

        if serviceRotation == .lastWinner {
            if let lastScore = scores.last(where: { $0.source == .point }) {
                return lastScore.team
            }
        }

        return startingServe
    }

    public var isLatestInSet: Bool {
        guard let latestGame = set?.latestGame else { return false }
        return latestGame.number == number
    }

    public var isLastInSet: Bool {
        guard let set, let maximumGames = match?.rules.setRulesFor(set).maximumGameCount else {
            return true
        }
        return maximumGames == number
    }

    public init(
        number: Int = 1,
        scores: [ScoreKeepGameScore] = [],
        startedAt: Date = .now,
        endedAt: Date? = nil,
        startingServe: ScoreKeepTeam? = nil
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
        startingServe: ScoreKeepTeam? = nil
    ) {
        // Append an amount of ` ScoreKeepTeam`s to an array, according to the `us` and `them` values
        let usScores: [ScoreKeepGameScore] = Array(
            repeating: ScoreKeepGameScore(.us, at: startedAt), count: us)
        let themScores: [ScoreKeepGameScore] = Array(
            repeating: ScoreKeepGameScore(.them, at: startedAt), count: them)

        self._scores = (usScores + themScores).shuffled()

        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = .now
        self.startingServe = startingServe
    }

    public func scorePoint(_ team: ScoreKeepTeam, at timestamp: Date = .now) {
        if hasEnded { return }

        var scores = self._scores ?? []

        let score = ScoreKeepGameScore(
            team, serve: servingTeam, scoring: match?.sport.gameServiceScoring, at: timestamp)

        scores.append(score)
        _scores = scores

        guard let rules else { return }
        
        if rules.hasWinner(self) {
            self.endedAt = Date.now

            if let set = set, let setRules = set.rules, !setRules.canPlayAnotherGame(set) {
                set.endedAt = endedAt
            }
        }
    }

    public var canUndo: Bool {
        if hasEnded { return false }
        // There must be at least one score whose source was a real point
        guard let scores = _scores else { return false }
        return scores.contains { $0.source == .point }
    }

    public func undo() {
        if hasEnded { return }

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

    public func scoreFor(_ team: ScoreKeepTeam) -> Int {
        team == .us ? scoreUs : scoreThem
    }

    public func serveStreakFor(_ team: ScoreKeepTeam) -> Int {
        var streak = 0

        for score in scores {
            if score.team != team || score.serve != team { break }
            streak += 1
        }

        return streak
    }
}

public enum ScoreKeepGameScoreSource: String, Codable {
    case point, edit
}

public struct ScoreKeepGameScore: Codable, Equatable {
    public var team: ScoreKeepTeam?
    public var us: Int
    public var them: Int
    public var timestamp: Date
    public var source: ScoreKeepGameScoreSource
    public var serve: ScoreKeepTeam?

    public init(
        us: Int = 0, them: Int = 0, serve: ScoreKeepTeam? = nil, at timestamp: Date = .now,
        source: ScoreKeepGameScoreSource = .point
    ) {
        self.team = source == .point ? us > them ? .us : .them : nil
        self.us = us
        self.them = them
        self.timestamp = timestamp
        self.serve = serve
        self.source = source
    }

    public init(
        _ team: ScoreKeepTeam, serve: ScoreKeepTeam? = nil,
        scoring: ScoreKeepServiceScoringRule? = nil, at timestamp: Date = .now
    ) {
        let adjustment = defaultAdjustmentForTeam(team, serve: serve, scoring: scoring)
        self.team = team
        self.us = team == .us ? adjustment : 0
        self.them = team == .them ? adjustment : 0
        self.timestamp = timestamp
        self.serve = serve
        self.source = .point
    }

    public func adjustment(_ team: ScoreKeepTeam) -> Int {
        switch team {
        case .us:
            return us
        case .them:
            return them
        }
    }
}

private func defaultAdjustmentForTeam(
    _ team: ScoreKeepTeam, serve: ScoreKeepTeam? = nil, scoring: ScoreKeepServiceScoringRule? = nil
) -> Int {
    let scoring = scoring ?? .rally

    switch scoring {
    case .rally: return 1
    case .sideOut: return team == serve ? 1 : 0
    }
}

@Model
public class ScoreKeepWarmup {
    public var match: ScoreKeepMatch?

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

public enum ScoreKeepMatchColor: String, Codable {
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

    public static var allCases: [ScoreKeepMatchColor] {
        [.green, .yellow, .indigo, .purple, .teal, .blue, .orange, .pink]
    }
}

@Model
public class ScoreKeepMatchTemplate {
    public var _matches: [ScoreKeepMatch]?

    public var sport: ScoreKeepSport = ScoreKeepSport.volleyball
    public var name: String = "Volleyball"
    public var color: ScoreKeepMatchColor = ScoreKeepMatchColor.green
    public var environment: ScoreKeepActivityEnvironment = ScoreKeepActivityEnvironment.indoor
    public var _rules: ScoreKeepMatchRules?
    public var rules: ScoreKeepMatchRules {
        get { _rules ?? ScoreKeepMatchRules() }
        set { _rules = newValue }
    }

    public var createdAt: Date = Date.now
    public var lastUsedAt: Date?
    public var warmup: ScoreKeepWarmupRule = ScoreKeepWarmupRule.open
    public var startWorkout: Bool = false

    public init(
        _ sport: ScoreKeepSport,
        name: String,
        color: ScoreKeepMatchColor = .green,
        environment: ScoreKeepActivityEnvironment = .indoor,
        rules: ScoreKeepMatchRules? = nil,
        warmup: ScoreKeepWarmupRule = .open,
        startWorkout: Bool = false
    ) {
        self.sport = sport
        self.name = name
        self.color = color
        self.environment = environment
        self._rules = rules ?? sport.defaultRules(environment: environment)
        self.createdAt = Date()
        self.warmup = warmup
        self.startWorkout = startWorkout
    }

    public func createMatch(markAsUsed: Bool = true) -> ScoreKeepMatch {
        if markAsUsed {
            lastUsedAt = Date()
        }

        return ScoreKeepMatch(from: self, markAsUsed: markAsUsed)
    }
}

public enum ScoreKeepTeamColor: String, Codable {
    case green, yellow, indigo, purple, teal, blue, orange, pink, red

    public var color: Color {
        switch self {
        case .blue: return Color.blue
        case .red: return Color.red
        case .green: return Color.green
        case .yellow: return Color.yellow
        case .indigo: return Color.indigo
        case .purple: return Color.purple
        case .teal: return Color.teal
        case .orange: return Color.orange
        case .pink: return Color.pink
        }
    }

    public static var allCases: [ScoreKeepTeamColor] {
        [.blue, .red, .green, .yellow, .indigo, .purple, .teal, .orange, .pink]
    }
}

public struct ScoreKeepMatchTemplateTeam {
    public let team: ScoreKeepTeam
    public let label: String
    public let shortLabel: String
    public let color: ScoreKeepTeamColor
    public let size: Int?

    public init(
        team: ScoreKeepTeam, label: String? = nil, shortLabel: String? = nil,
        color: ScoreKeepTeamColor? = nil, size: Int? = nil
    ) {
        self.team = team
        self.label = label ?? team.defaultLabel(size: size)
        self.shortLabel = shortLabel ?? team.defaultShortLabel(size: size)
        self.color = color ?? team.defaultColor
        self.size = size
    }

}

public enum ScoreKeepWarmupRule: String, Codable {
    case none
    case open
}

public enum ScoreKeepWinBehaviorRule: String, Codable {
    case end
    case keepPlaying
}

public struct ScoreKeepMatchRules: Codable, Equatable {
    public var winAt: Int?
    public var winBy: Int?
    public var maximum: Int?
    public var winBehavior: ScoreKeepWinBehaviorRule
    public var setRules: ScoreKeepSetRules
    public var lastSetRules: ScoreKeepSetRules?

    enum CodingKeys: String, CodingKey {
        case winAt, winBy, maximum, winBehavior, setRules, lastSetRules
    }

    public init(
        winAt: Int? = 1, winBy: Int? = nil, maximum: Int? = nil,
        winBehavior: ScoreKeepWinBehaviorRule = .end,
        setRules: ScoreKeepSetRules = ScoreKeepSetRules(),
        lastSetRules: ScoreKeepSetRules? = nil
    ) {
        self.winAt = winAt
        self.winBy = winBy
        self.maximum = maximum
        self.winBehavior = winBehavior
        self.setRules = setRules
        self.lastSetRules = lastSetRules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        winAt = try container.decodeIfPresent(Int.self, forKey: .winAt)
        winBy = try container.decodeIfPresent(Int.self, forKey: .winBy)
        maximum = try container.decodeIfPresent(Int.self, forKey: .maximum)
        winBehavior = try container.decodeIfPresent(ScoreKeepWinBehaviorRule.self, forKey: .winBehavior) ?? .end
        setRules = try container.decode(ScoreKeepSetRules.self, forKey: .setRules)
        lastSetRules = try container.decodeIfPresent(ScoreKeepSetRules.self, forKey: .lastSetRules)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(winAt, forKey: .winAt)
        try container.encodeIfPresent(winBy, forKey: .winBy)
        try container.encodeIfPresent(maximum, forKey: .maximum)
        try container.encode(winBehavior, forKey: .winBehavior)
        try container.encode(setRules, forKey: .setRules)
        try container.encodeIfPresent(lastSetRules, forKey: .lastSetRules)
    }

    public var isMultiSet: Bool {
        guard let winAt else { return false }
        return winAt > 1
    }

    public func setRulesFor(_ set: ScoreKeepSet) -> ScoreKeepSetRules {
        return set.isLastInMatch ? (lastSetRules ?? setRules) : setRules
    }

    public var primaryLabel: String {
        guard let winAt, let maximumSetCount else { return "Open match" }

        if winAt == 1 {
            return setRules.primaryLabel
        }

        if winBehavior == .keepPlaying {
            return "Best of \(maximumSetCount) sets"
        }

        return "First to \(winAt) sets"
    }

    public var secondaryLabel: String {
        if winAt == nil { return "" }

        return setRules.secondaryLabel
    }

    public func checkForWinner(_ match: ScoreKeepMatch) -> ScoreKeepTeam? {
        if let winner = match.winner { return winner }

        guard let winAt else { return nil }

        let winBy = self.winBy ?? 1

        let setsUs = match.setsUs
        let setsThem = match.setsThem

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

    public func hasWinner(_ match: ScoreKeepMatch) -> Bool {
        checkForWinner(match) != nil
    }

    public func canPlayAnotherSet(_ match: ScoreKeepMatch) -> Bool {
        if winAt == nil { return true }

        if hasWinner(match) && winBehavior == .end { return false }

        guard let maximumSetCount else { return true }

        return match.sets.count < maximumSetCount
    }

    public var maximumSetCount: Int? {
        if let maximum { return (maximum * 2) - 1 }
        if let winAt { return (winAt * 2) - 1 }
        return nil
    }
}

public struct ScoreKeepSetRules: Codable, Equatable {
    public var winAt: Int?
    public var winBy: Int?
    public var maximum: Int?
    public var winBehavior: ScoreKeepWinBehaviorRule
    public var gameRules: ScoreKeepGameRules
    public var lastGameRules: ScoreKeepGameRules?

    enum CodingKeys: String, CodingKey {
        case winAt, winBy, maximum, winBehavior, gameRules, lastGameRules
    }

    public init(
        winAt: Int? = nil, winBy: Int? = nil, maximum: Int? = nil,
        winBehavior: ScoreKeepWinBehaviorRule = .end,
        gameRules: ScoreKeepGameRules = ScoreKeepGameRules(),
        lastGameRules: ScoreKeepGameRules? = nil
    ) {
        self.winAt = winAt
        self.winBy = winBy
        self.maximum = maximum
        self.winBehavior = winBehavior
        self.gameRules = gameRules
        self.lastGameRules = lastGameRules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.winAt = try container.decodeIfPresent(Int.self, forKey: .winAt)
        self.winBy = try container.decodeIfPresent(Int.self, forKey: .winBy)
        self.maximum = try container.decodeIfPresent(Int.self, forKey: .maximum)
        self.winBehavior = try container.decodeIfPresent(ScoreKeepWinBehaviorRule.self, forKey: .winBehavior) ?? .end
        self.gameRules = try container.decode(ScoreKeepGameRules.self, forKey: .gameRules)
        self.lastGameRules = try container.decodeIfPresent(ScoreKeepGameRules.self, forKey: .lastGameRules)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(winAt, forKey: .winAt)
        try container.encodeIfPresent(winBy, forKey: .winBy)
        try container.encodeIfPresent(maximum, forKey: .maximum)
        try container.encode(winBehavior, forKey: .winBehavior)
        try container.encode(gameRules, forKey: .gameRules)
        try container.encodeIfPresent(lastGameRules, forKey: .lastGameRules)
    }

    public var isMultiGame: Bool {
        guard let winAt else { return false }
        return winAt > 1
    }

    public func gameRulesFor(game: ScoreKeepGame) -> ScoreKeepGameRules {
        return game.isLastInSet ? (lastGameRules ?? gameRules) : gameRules
    }

    public var primaryLabel: String {
        guard let winAt, let maximumGameCount else { return "Open set" }

        if winAt == 1 {
            return gameRules.primaryLabel
        }

        if winBehavior == .keepPlaying {
            return "Best of \(maximumGameCount) games"
        }

        return "First to \(winAt) games"
    }

    public var secondaryLabel: String {
        guard let winAt, winAt > 1 else { return "" }

        guard let gamesWinAt = gameRules.winAt else { return "Open games" }

        return "Games to \(gamesWinAt) points"
    }

    public func checkForWinner(_ set: ScoreKeepSet) -> ScoreKeepTeam? {
        if let winner = set.winner { return winner }

        guard let winAt else { return nil }

        let winBy = self.winBy ?? 1

        let gamesUs = set.gamesUs
        let gamesThem = set.gamesThem

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

    public func hasWinner(_ set: ScoreKeepSet) -> Bool {
        checkForWinner(set) != nil
    }

    public func canPlayAnotherGame(_ set: ScoreKeepSet) -> Bool {
        if winAt == nil { return true }

        print("ScoreKeepSetScoringRules.canPlayAnotherGame()")
        print("match: \(set.match?.scoreSummaryString ?? "<no match>")")
        print(
            "winAt: \(winAt ?? -1), " + "hasWinner: \(hasWinner(set)), "
                + "playItOut: \(winBehavior == .keepPlaying), "
                + "impliedMaximumGameNumber: \(maximumGameCount ?? -1)"
        )

        if hasWinner(set) && winBehavior == .end { return false }

        guard let maximumGameCount else { return true }

        return set.games.count < maximumGameCount
    }

    public var maximumGameCount: Int? {
        if let maximum { return (maximum * 2) - 1 }
        if let winAt { return (winAt * 2) - 1 }
        return nil
    }
}

public struct ScoreKeepGameRules: Codable, Equatable {
    public var winAt: Int?
    public var winBy: Int?
    public var maximum: Int?

    public init(winAt: Int? = nil, winBy: Int? = nil, maximum: Int? = nil) {
        self.winAt = winAt
        self.winBy = winBy
        self.maximum = maximum
    }

    public var primaryLabel: String {
        guard let winAt else { return "Open game" }

        return "First to \(winAt) points"
    }

    public func checkForWinner(_ game: ScoreKeepGame) -> ScoreKeepTeam? {
        if let winner = game.winner { return winner }

        guard let winAt else { return nil }

        let winBy = self.winBy ?? 1

        let scoreUs = game.scoreUs
        let scoreThem = game.scoreThem

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

    public func hasWinner(_ game: ScoreKeepGame) -> Bool {
        checkForWinner(game) != nil
    }
}

public class ScoreKeepModelContainer {
    public let schema = Schema([
        ScoreKeepMatch.self,
        ScoreKeepSet.self,
        ScoreKeepGame.self,
        ScoreKeepWarmup.self,
        ScoreKeepMatchTemplate.self,
    ])

    public init() {

    }

    public func sharedModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [configuration])
    }

    public func testModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
