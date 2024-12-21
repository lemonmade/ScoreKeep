//
//  ScoreData.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class GameScore {
    var ruleset: GameScoreRuleset
    var sets: [GameSetScore]
    var startedAt: Date
    var endedAt: Date?
    
    var latestSet: GameSetScore? { sets.last }
    
    init(ruleset: GameScoreRuleset, sets: [GameSetScore] = [], startedAt: Date = Date(), endedAt: Date? = nil) {
        self.ruleset = ruleset
        self.sets = sets
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    func scoreTeam0() {
        guard let set = latestSet else { return }
        
        set.score0 += 1
        
        if (set.score0 < ruleset.winScore) { return }
        if (set.score0 - set.score1 < ruleset.winBy) { return }
        
        set.endedAt = Date()
    }
    
    func scoreTeam1() {
        guard let set = latestSet else { return }
        
        set.score1 += 1
        
        if (set.score1 < ruleset.winScore) { return }
        if (set.score1 - set.score0 < ruleset.winBy) { return }
        
        set.endedAt = Date()
    }
}

@Model
class GameSetScore {
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
class GameScoreRuleset {
    var winScore: Int
    var winBy: Int
    
    init(winScore: Int, winBy: Int = 1) {
        self.winScore = winScore
        self.winBy = winBy
    }
}
