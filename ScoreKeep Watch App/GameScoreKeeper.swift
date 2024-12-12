//
//  GameScoreKeeper.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-11.
//

import Foundation

struct GameRules {
    let winningScore: Int
    let maxScore: Int
    var winBy: Int = 1
}

class GameSet: Identifiable, ObservableObject {
    let id = UUID()
    let number: Int
    let startTime: Date
    let rules: GameRules

    @Published private(set) var team0Score: Int = 0
    @Published private(set) var team1Score: Int = 0
    
    init(number: Int, rules: GameRules, startTime: Date = Date()) {
        self.number = number
        self.rules = rules
        self.startTime = startTime
    }

    var isFinished: Bool {
        if team0Score >= rules.winningScore || team1Score >= rules.winningScore {
            return team0Score >= rules.maxScore || team1Score >= rules.maxScore || abs(team0Score - team1Score) >= rules.winBy
        }

        return false
    }
    
    func addPointToTeam0() {
        guard !isFinished else { return }
        team0Score += 1
    }

    func addPointToTeam1() {
        guard !isFinished else { return }
        team1Score += 1
    }
}

class GameScoreKeeper: ObservableObject {
    @Published var latestSet: GameSet = GameSet(
        number: 1,
        rules: GameRules(winningScore: 25, maxScore: 27, winBy: 2)
    )
    
    @Published private(set) var sets: [GameSet] = []
    
    init() {
        self.sets.append(latestSet)
    }

    // Methods to add points
    func addPointToTeam0() {
        latestSet.addPointToTeam0()
    }

    func addPointToTeam1() {
        latestSet.addPointToTeam1()
    }

    // Record and finalize the current set
    func startNewSet() {
        let newSet = GameSet(number: latestSet.number + 1, rules: latestSet.rules)
        sets.append(newSet)
        latestSet = newSet
    }
}
