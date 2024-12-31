//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftUI
import SwiftData

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
    var startedAt: Date
    var endedAt: Date?
    var scoring: MatchScoringRules
    var template: MatchTemplate?
    
    var hasEnded: Bool { endedAt != nil }
    
    var latestSet: MatchSet? { sets.last }
    var latestGame: MatchGame? { latestSet?.latestGame }
    
    var hasMoreGames: Bool {
        if hasEnded { return false }
        guard let latestSet else { return true }
        
        return scoring.setScoring.canPlayAnotherGame(latestSet) || scoring.canPlayAnotherSet(self)
    }
    
    var setsUs: Int { sets.count { $0.winner == .us } }
    var setsThem: Int { sets.count { $0.winner == .them } }
    
    var winner: MatchTeam? {
        if !hasEnded { return nil }
        
        let setsUs = setsUs, setsThem = setsThem
        return setsUs > setsThem ? .us : setsThem > setsUs ? .them : nil
    }
    
    var hasWinner: Bool { winner != nil }
    
    var isMultiSet: Bool { scoring.isMultiSet }
    
    init(from template: MatchTemplate, markAsUsed: Bool = true) {
        self.template = markAsUsed ? template : nil
        self.sport = template.sport
        self.environment = template.environment
        self.scoring = template.scoring
        self.sets = [MatchSet()]
        self.startedAt = Date()
    }
    
    init(_ sport: MatchSport = .volleyball, environment: MatchEnvironment = .indoor, scoring: MatchScoringRules, sets: [MatchSet] = [MatchSet()], startedAt: Date = Date(), endedAt: Date? = nil) {
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
    
    func score(_ team: MatchTeam) {
        // TODO
        guard let set = latestSet, !set.hasEnded, let game = set.latestGame, !game.hasEnded else { return }
        
        game.score(team)
        
        if (scoring.setScoring.gameScoring.hasWinner(game)) {
            game.endedAt = Date()
            
            if (!scoring.setScoring.canPlayAnotherGame(set)) {
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
            let newGame = MatchGame(number: latestGame.number + 1, startedAt: now)
            latestSet.games.append(newGame)
            return
        }
        
        latestSet.endedAt = now
        
        if scoring.hasWinner(self) && !scoring.playItOut {
            return
        }
        
        let newSet = MatchSet(number: latestSet.number + 1, games: [MatchGame(startedAt: now)], startedAt: now)
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

    var latestGame: MatchGame? { games.last }
    
    var createdAt: Date
    var startedAt: Date
    var endedAt: Date?
    
    var hasEnded: Bool { endedAt != nil }
    
    var gamesUs: Int { games.count { $0.winner == .us } }
    var gamesThem: Int { games.count { $0.winner == .them } }
    
    var winner: MatchTeam? {
        if !hasEnded { return nil }
        
        let gamesUs = gamesUs, gamesThem = gamesThem
        return gamesUs > gamesThem ? .us : gamesThem > gamesUs ? .them : nil
    }
    
    var hasWinner: Bool { winner != nil }
    
    var isTied: Bool {
        gamesUs == gamesThem
    }
    
    init(number: Int = 1, games: [MatchGame] = [MatchGame()], startedAt: Date = Date(), endedAt: Date? = nil) {
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
    
    var hasEnded: Bool { endedAt != nil }
    
    var winner: MatchTeam? {
        if !hasEnded { return nil }
        
        let scoreUs = scoreUs, scoreThem = scoreThem
        return scoreUs > scoreThem ? .us : scoreThem > scoreUs ? .them : nil
    }
    
    var hasWinner: Bool { winner != nil }
    
    var isTied: Bool {
        scoreUs == scoreThem
    }
    
    init(number: Int = 1, us scoreUs: Int = 0, them scoreThem: Int = 0, startedAt: Date = Date(), endedAt: Date? = nil) {
        self.number = number
        self.scoreUs = scoreUs
        self.scoreThem = scoreThem
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
    }
    
    func score(_ team: MatchTeam, to: Int? = nil) {
        if team == .us {
            let finalTo = to ?? self.scoreUs + 1
            self.scoreUs = finalTo
        } else {
            let finalTo = to ?? self.scoreThem + 1
            self.scoreThem = finalTo
        }
    }
    
    func scoreFor(_ team: MatchTeam) -> Int {
        team == .us ? scoreUs : scoreThem
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
    
    static var allCases: [MatchTemplateColor] { [.green, .yellow, .indigo, .purple, .teal, .blue, .orange, .pink] }
}

@Model
class MatchTemplate {
    var sport: MatchSport
    var name: String
    var color: MatchTemplateColor;
    var environment: MatchEnvironment
    var scoring: MatchScoringRules
    var createdAt: Date
    var lastUsedAt: Date?
    
    init(_ sport: MatchSport, name: String, color: MatchTemplateColor = .green, environment: MatchEnvironment = .indoor, scoring: MatchScoringRules) {
        self.sport = sport
        self.name = name
        self.color = color
        self.environment = environment
        self.scoring = scoring
        self.createdAt = Date()
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
    
    init(setsWinAt: Int, setsMaximum: Int? = nil, playItOut: Bool = false, setScoring: MatchSetScoringRules, setTiebreakerScoring: MatchSetScoringRules? = nil) {
        self.setsWinAt = setsWinAt
        self.setsMaximum = setsMaximum ?? ((setsWinAt * 2) - 1)
        self.playItOut = playItOut
        self.setScoring = setScoring
        self.setTimebreakerScoring = setTiebreakerScoring ?? setScoring
    }
    
    func checkForWinner(_ match: Match) -> MatchTeam? {
        if let winner = match.winner { return winner }
        
        let setsUs = match.setsUs, setsThem = match.setsThem
        
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
    
    init(gamesWinAt: Int, gamesMaximum: Int? = nil, playItOut: Bool = false, gameScoring: MatchGameScoringRules, gameTimebreakerScoring: MatchGameScoringRules? = nil) {
        self.gamesWinAt = gamesWinAt
        self.gamesMaximum = gamesMaximum ?? ((gamesWinAt * 2) - 1)
        self.playItOut = playItOut
        self.gameScoring = gameScoring
        self.gameTimebreakerScoring = gameTimebreakerScoring ?? gameScoring
    }
    
    func checkForWinner(_ set: MatchSet) -> MatchTeam? {
        if let winner = set.winner { return winner }
        
        let gamesUs = set.gamesUs, gamesThem = set.gamesThem
        
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
        return playItOut ? (set.games.count + 1) <= gamesMaximum : !hasWinner(set)
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
        let scoreUs = game.scoreUs, scoreThem = game.scoreThem
        
        if (scoreUs >= winScore) {
            if (scoreUs - scoreThem >= winBy) {
                return .us
            }
        } else if (scoreThem >= winScore) {
            if (scoreThem - scoreUs >= winBy) {
                return .them
            }
        }
        
        return nil
    }
    
    func hasWinner(_ game: MatchGame) -> Bool {
        checkForWinner(game) != nil
    }
}
