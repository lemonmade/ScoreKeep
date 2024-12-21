//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftUI
import SwiftData

enum GameSport {
    case volleyball
}

@Model
final class Game {
    var rules: GameRules
    var sets: [GameSet]
    var startedAt: Date
    var endedAt: Date?
    var sport: GameSport
    
    var latestSet: GameSet? { sets.last }
    
    init(rules: GameRules, sets: [GameSet] = [], startedAt: Date = Date(), endedAt: Date? = nil) {
        self.rules = rules
        self.sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    func scoreTeam0() {
        guard let set = latestSet else { return }
        
        set.score0 += 1
        
        if (set.score0 < rules.winScore) { return }
        if (set.score0 - set.score1 < rules.winBy) { return }
        
        set.endedAt = Date()
    }
    
    func scoreTeam1() {
        guard let set = latestSet else { return }
        
        set.score1 += 1
        
        if (set.score1 < rules.winScore) { return }
        if (set.score1 - set.score0 < rules.winBy) { return }
        
        set.endedAt = Date()
    }
}

@Model
class GameSet {
    var score0: Int
    var score1: Int
    var startedAt: Date
    var endedAt: Date?
    
    var isFinished: Bool { endedAt != nil }
    
    init(score0: Int = 0, score1: Int = 0, startedAt: Date = Date(), endedAt: Date? = nil) {
        self.score0 = score0
        self.score1 = score1
        self.startedAt = startedAt
        self.endedAt = endedAt
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
}

@Model
class GameTemplate {
    var sport: GameSport
    var rules: GameRules
    
    init(_ sport: GameSport = .volleyball, rules: GameRules) {
        self.sport = sport
        self.rules = rules
    }
}
