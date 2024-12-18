//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftData

@Model
final class GameScore {
    var ruleset: GameScoreRuleset
    var sets: [GameSetScore]
    var startedAt: Date
    var endedAt: Date?
    
    init(ruleset: GameScoreRuleset, sets: [GameSetScore], startedAt: Date, endedAt: Date? = nil) {
        self.ruleset = ruleset
        self.sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

@Model
class GameSetScore {
    var score0: Int
    var score1: Int
    var startedAt: Date
    var endedAt: Date?
    
    init(score0: Int, score1: Int, startedAt: Date, endedAt: Date? = nil) {
        self.score0 = score0
        self.score1 = score1
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

@Model
class GameScoreRuleset {
    var winScore: Int
    var winBy: Int
    
    init(winScore: Int, winBy: Int = 1) {
        self.winScore = winScore
        self.winBy = winBy
    }
}
