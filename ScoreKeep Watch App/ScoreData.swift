//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftUI
import SwiftData

enum GameSport: String, Codable {
    case volleyball
}

enum GameTeam: String, Codable {
    case us, them
}

@Model
final class Game {
    var rules: GameRules
    var sets: [GameSet]
    var startedAt: Date
    var endedAt: Date?
    var sport: GameSport
    var indoor: Bool
    
    var latestSet: GameSet? { sets.last }
    
    init(from template: GameTemplate) {
        self.sport = template.sport
        self.indoor = template.indoor
        self.rules = template.rules
        self.sets = [GameSet()]
        self.startedAt = Date()
    }
    
    init(_ sport: GameSport = .volleyball, indoor: Bool = true, rules: GameRules, sets: [GameSet] = [GameSet()], startedAt: Date = Date(), endedAt: Date? = nil) {
        self.sport = sport
        self.indoor = indoor
        self.rules = rules
        self.sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    func score(_ team: GameTeam) {
        // TODO
        guard let set = latestSet, !set.hasEnded else { return }
        
        set.score(team)

        if (rules.winner(for: set) != nil) {
            set.endedAt = Date()
        }
    }
}

@Model
class GameSet {
    var scoreUs: Int
    var scoreThem: Int
    var startedAt: Date
    var endedAt: Date?
    
    var hasEnded: Bool { endedAt != nil }
    
    init(us scoreUs: Int = 0, them scoreThem: Int = 0, startedAt: Date = Date(), endedAt: Date? = nil) {
        self.scoreUs = scoreUs
        self.scoreThem = scoreThem
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    func score(_ team: GameTeam, to: Int? = nil) {
        if team == .us {
            let finalTo = to ?? self.scoreUs + 1
            self.scoreUs = finalTo
        } else {
            let finalTo = to ?? self.scoreThem + 1
            self.scoreThem = finalTo
        }
    }
    
    func scoreFor(_ team: GameTeam) -> Int {
        team == .us ? scoreUs : scoreThem
    }
}

@Model
class GameRules {
    var winScore: Int
    var winBy: Int
    
    init(winScore: Int, winBy: Int = 1) {
        self.winScore = winScore
        self.winBy = winBy
    }
    
    func winner(for gameSet: GameSet) -> GameTeam? {
        if (gameSet.scoreUs >= winScore) {
            if (gameSet.scoreUs - gameSet.scoreThem >= winBy) {
                return .us
            }
        } else if (gameSet.scoreThem >= winScore) {
            if (gameSet.scoreThem - gameSet.scoreUs >= winBy) {
                return .them
            }
        }
        
        return nil
    }
}

@Model
class GameTemplate {
    var sport: GameSport
    var indoor: Bool
    var rules: GameRules
    
    init(_ sport: GameSport = .volleyball, indoor: Bool = true, rules: GameRules) {
        self.sport = sport
        self.indoor = indoor
        self.rules = rules
    }
}
