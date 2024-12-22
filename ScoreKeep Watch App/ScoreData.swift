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
    
    var latestSet: MatchSet? { sets.last }
    var latestGame: MatchGame? { latestSet?.latestGame }
    
    init(_ sport: MatchSport = .volleyball, environment: MatchEnvironment = .indoor, sets: [MatchSet] = [MatchSet()], startedAt: Date = Date(), endedAt: Date? = nil, scoring: MatchScoringRules) {
        self.sport = sport
        self.environment = environment
        self.sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.scoring = scoring
    }
    
    func score(_ team: MatchTeam) {
        // TODO
        guard let set = latestSet, !set.hasEnded, let game = set.latestGame, !game.hasEnded else { return }
        
        game.score(team)
        
        if (scoring.setScoring.gameScoring.hasWinner(game)) {
            game.endedAt = Date()
        }
        
        if (scoring.setScoring.hasWinner(set)) {
            set.endedAt = Date()
        }
    }
    
    func startGame() {
        let now = Date()
        
        if latestSet == nil {
            sets.append(MatchSet(games: []))
        }
        
        if let latestGame = latestGame, !latestGame.hasEnded {
            latestGame.endedAt = now
        }
        
        let newGame = MatchGame(startedAt: now)
        latestSet?.games.append(newGame)
    }
}

@Model
class MatchSet {
    var games: [MatchGame]

    var latestGame: MatchGame? { games.last }
    
    var createdAt: Date
    var startedAt: Date
    var endedAt: Date?
    
    var hasEnded: Bool { endedAt != nil }
    
    var gamesUs: Int { games.count { $0.hasEnded && $0.scoreUs > $0.scoreThem } }
    var gamesThem: Int { games.count { $0.hasEnded && $0.scoreThem > $0.scoreUs } }
    
    var winner: MatchTeam? {
        if !hasEnded { return nil }
        
        let gamesUs = gamesUs, gamesThem = gamesThem
        return gamesUs > gamesThem ? .us : gamesThem > gamesUs ? .them : nil
    }
    
    var hasWinner: Bool { winner != nil }
    
    var isTied: Bool {
        gamesUs == gamesThem
    }
    
    init(games: [MatchGame] = [MatchGame()], startedAt: Date = Date(), endedAt: Date? = nil) {
        self.games = games
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = Date()
    }
}

@Model
class MatchGame {
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
    
    init(us scoreUs: Int = 0, them scoreThem: Int = 0, startedAt: Date = Date(), endedAt: Date? = nil) {
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

@Model
class MatchTemplate {
    var sport: MatchSport
    var name: String
    var environment: MatchEnvironment
    var scoring: MatchScoringRules
    var createdAt: Date
    var lastUsedAt: Date?
    
    init(_ sport: MatchSport, name: String, environment: MatchEnvironment = .indoor, scoring: MatchScoringRules) {
        self.sport = sport
        self.name = name
        self.environment = environment
        self.scoring = scoring
        self.createdAt = Date()
    }
    
    func createMatch() -> Match {
        lastUsedAt = Date()
        
        let match = Match(sport, environment: environment, scoring: scoring)
        
        return match
    }
}

struct MatchScoringRules: Codable {
    var setsWinAt: Int
    var setsMaximum: Int
    var playItOut: Bool
    var setScoring: MatchSetScoringRules
    var setTimebreakerScoring: MatchSetScoringRules
    
    init(setsWinAt: Int, setsMaximum: Int? = nil, playItOut: Bool = false, setScoring: MatchSetScoringRules, setTiebreakerScoring: MatchSetScoringRules? = nil) {
        self.setsWinAt = setsWinAt
        self.setsMaximum = setsMaximum ?? ((setsWinAt * 2) - 1)
        self.playItOut = playItOut
        self.setScoring = setScoring
        self.setTimebreakerScoring = setTiebreakerScoring ?? setScoring
    }
}

struct MatchSetScoringRules: Codable {
    var gamesWinAt: Int
    var gamesMaximum: Int
    var playItOut: Bool
    var gameScoring: MatchGameScoringRules
    var gameTimebreakerScoring: MatchGameScoringRules
    
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
}

struct MatchGameScoringRules: Codable {
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

var indoorVolleyball = MatchTemplate(
    .volleyball,
    name: "Indoor Volleyball",
    environment: .indoor,
    scoring: MatchScoringRules(
        setsWinAt: 1,
        setScoring: MatchSetScoringRules(
            gamesWinAt: 3,
            playItOut: true,
            gameScoring: MatchGameScoringRules(
                winScore: 25,
                maximumScore: 27,
                winBy: 2
            )
        )
    )
)
