import Foundation
import SwiftData
import Testing

@testable import ScoreKeepCore

// MARK: - ScoreKeepGameRules Tests

@Suite("ScoreKeepGameRules")
struct ScoreKeepGameRulesTests {
    @Test("No winner below winAt")
    func noWinnerBelowWinAt() {
        let rules = ScoreKeepGameRules(winAt: 25, winBy: 2)
        let game = ScoreKeepGame(us: 20, them: 15)
        #expect(rules.checkForWinner(game) == nil)
    }

    @Test("Winner when score >= winAt and lead >= winBy")
    func winnerWithSufficientLead() {
        let rules = ScoreKeepGameRules(winAt: 25, winBy: 2)
        let game = ScoreKeepGame(us: 25, them: 20)
        #expect(rules.checkForWinner(game) == .us)
    }

    @Test("No winner when score >= winAt but lead < winBy")
    func noWinnerInsufficientLead() {
        let rules = ScoreKeepGameRules(winAt: 25, winBy: 2)
        let game = ScoreKeepGame(us: 25, them: 24)
        #expect(rules.checkForWinner(game) == nil)
    }

    @Test("Winner at maximum regardless of lead")
    func winnerAtMaximum() {
        let rules = ScoreKeepGameRules(winAt: 25, winBy: 2, maximum: 30)
        let game = ScoreKeepGame(us: 30, them: 29)
        #expect(rules.checkForWinner(game) == .us)
    }

    @Test("Them wins symmetrically")
    func themWins() {
        let rules = ScoreKeepGameRules(winAt: 11, winBy: 1)
        let game = ScoreKeepGame(us: 8, them: 11)
        #expect(rules.checkForWinner(game) == .them)
    }

    @Test("No winner with winAt nil (open game)")
    func openGameNoWinner() {
        let rules = ScoreKeepGameRules()
        let game = ScoreKeepGame(us: 100, them: 50)
        #expect(rules.checkForWinner(game) == nil)
    }

    @Test("hasWinner returns correct boolean")
    func hasWinnerBoolean() {
        let rules = ScoreKeepGameRules(winAt: 5)
        let noWinner = ScoreKeepGame(us: 3, them: 2)
        let withWinner = ScoreKeepGame(us: 5, them: 2)
        #expect(rules.hasWinner(noWinner) == false)
        #expect(rules.hasWinner(withWinner) == true)
    }

    @Test("Win by 1 at exact winAt")
    func winByOneAtExactWinAt() {
        let rules = ScoreKeepGameRules(winAt: 25, winBy: 1)
        let game = ScoreKeepGame(us: 25, them: 24)
        #expect(rules.checkForWinner(game) == .us)
    }
}

// MARK: - ScoreKeepSetRules Tests

@Suite("ScoreKeepSetRules")
struct ScoreKeepSetRulesTests {
    @Test("canPlayAnotherGame returns false at maximum game count")
    func cannotPlayBeyondMaximum() {
        let rules = ScoreKeepSetRules(
            winAt: 3,
            gameRules: ScoreKeepGameRules(winAt: 25)
        )
        // Maximum game count is (3 * 2) - 1 = 5
        let set = ScoreKeepSet(
            games: (1...5).map { ScoreKeepGame(number: $0, us: 25, them: 20, endedAt: .now) }
        )
        #expect(rules.canPlayAnotherGame(set) == false)
    }

    @Test("canPlayAnotherGame returns true with keepPlaying after winner")
    func canPlayWithKeepPlaying() {
        let rules = ScoreKeepSetRules(
            winAt: 2,
            winBehavior: .keepPlaying,
            gameRules: ScoreKeepGameRules(winAt: 25)
        )
        // Us won 2 games, them won 0 — winner exists but keepPlaying
        let set = ScoreKeepSet(
            games: [
                ScoreKeepGame(number: 1, us: 25, them: 20, endedAt: .now),
                ScoreKeepGame(number: 2, us: 25, them: 20, endedAt: .now),
            ]
        )
        #expect(rules.canPlayAnotherGame(set) == true)
    }

    @Test("canPlayAnotherGame returns false with .end after winner")
    func cannotPlayWithEnd() {
        let rules = ScoreKeepSetRules(
            winAt: 2,
            winBehavior: .end,
            gameRules: ScoreKeepGameRules(winAt: 25)
        )
        let set = ScoreKeepSet(
            games: [
                ScoreKeepGame(number: 1, us: 25, them: 20, endedAt: .now),
                ScoreKeepGame(number: 2, us: 25, them: 20, endedAt: .now),
            ]
        )
        #expect(rules.canPlayAnotherGame(set) == false)
    }

    @Test("maximumGameCount calculation")
    func maximumGameCount() {
        let rules = ScoreKeepSetRules(winAt: 3)
        #expect(rules.maximumGameCount == 5)

        let rulesWithMax = ScoreKeepSetRules(winAt: 3, maximum: 4)
        #expect(rulesWithMax.maximumGameCount == 7)
    }

    @Test("isMultiGame")
    func isMultiGame() {
        #expect(ScoreKeepSetRules(winAt: 1).isMultiGame == false)
        #expect(ScoreKeepSetRules(winAt: 3).isMultiGame == true)
    }
}

// MARK: - ScoreKeepMatchRules Tests

@Suite("ScoreKeepMatchRules")
struct ScoreKeepMatchRulesTests {
    @Test("isMultiSet")
    func isMultiSet() {
        #expect(ScoreKeepMatchRules(winAt: 1).isMultiSet == false)
        #expect(ScoreKeepMatchRules(winAt: 3).isMultiSet == true)
    }

    @Test("maximumSetCount calculation")
    func maximumSetCount() {
        let rules = ScoreKeepMatchRules(winAt: 3)
        #expect(rules.maximumSetCount == 5)
    }
}

// MARK: - ScoreKeepGame Tests (SwiftData)

@Suite("ScoreKeepGame")
struct ScoreKeepGameTests {
    private func makeContainer() throws -> ModelContainer {
        ScoreKeepModelContainer().testModelContainer()
    }

    @Test("scorePoint increments correct team")
    @MainActor
    func scorePointIncrementsCorrectTeam() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)
        match.startGame()

        guard let game = match.latestGame else {
            Issue.record("No game created")
            return
        }

        game.scorePoint(.us)
        #expect(game.scoreUs == 1)
        #expect(game.scoreThem == 0)

        game.scorePoint(.them)
        #expect(game.scoreUs == 1)
        #expect(game.scoreThem == 1)
    }

    @Test("scorePoint auto-ends game at winning score")
    @MainActor
    func scorePointAutoEndsGame() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 3)
                )
            )
        )
        context.insert(match)
        match.startGame()

        guard let game = match.latestGame else {
            Issue.record("No game created")
            return
        }

        game.scorePoint(.us)
        game.scorePoint(.us)
        #expect(game.endedAt == nil)

        game.scorePoint(.us)
        #expect(game.endedAt != nil)
        #expect(game.winner == .us)
    }

    @Test("scorePoint does nothing after game ended")
    @MainActor
    func scorePointIgnoredAfterEnd() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 2)
                )
            )
        )
        context.insert(match)
        match.startGame()

        guard let game = match.latestGame else {
            Issue.record("No game created")
            return
        }

        game.scorePoint(.us)
        game.scorePoint(.us)
        #expect(game.hasEnded)

        game.scorePoint(.them)
        #expect(game.scoreThem == 0)
    }

    @Test("undo removes last score and clears endedAt")
    @MainActor
    func undoRemovesLastScore() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)
        match.startGame()

        guard let game = match.latestGame else {
            Issue.record("No game created")
            return
        }

        game.scorePoint(.us)
        game.scorePoint(.them)
        game.scorePoint(.us)

        #expect(game.scoreUs == 2)
        #expect(game.scoreThem == 1)

        game.undo()
        #expect(game.scoreUs == 1)
        #expect(game.scoreThem == 1)
    }

    @Test("canUndo returns false with no scores")
    @MainActor
    func canUndoNoScores() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)
        match.startGame()

        guard let game = match.latestGame else {
            Issue.record("No game created")
            return
        }

        #expect(game.canUndo == false)

        game.scorePoint(.us)
        #expect(game.canUndo == true)
    }

    @Test("serveStreakFor counts from most recent score")
    @MainActor
    func serveStreakFromEnd() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)
        match.startGame()

        guard let game = match.latestGame else {
            Issue.record("No game created")
            return
        }

        // Score pattern: us, us, them, us, us, us
        // With lastWinner rotation:
        //   score 1: us scores, serve=nil (no starting serve)
        //   score 2: us scores, serve=.us (last winner was .us)
        //   score 3: them scores, serve=.us
        //   score 4: us scores, serve=.them (last winner was .them)
        //   score 5: us scores, serve=.us (last winner was .us)
        //   score 6: us scores, serve=.us (last winner was .us)
        // Streak for .us from end: score 6 (team=.us, serve=.us) ✓,
        //   score 5 (team=.us, serve=.us) ✓,
        //   score 4 (team=.us, serve=.them) ✗ — breaks
        game.scorePoint(.us)
        game.scorePoint(.us)
        game.scorePoint(.them)
        game.scorePoint(.us)
        game.scorePoint(.us)
        game.scorePoint(.us)

        #expect(game.serveStreakFor(.us) == 2)
        #expect(game.serveStreakFor(.them) == 0)
    }
}

// MARK: - ScoreKeepMatch Tests (SwiftData)

@Suite("ScoreKeepMatch")
struct ScoreKeepMatchTests {
    private func makeContainer() throws -> ModelContainer {
        ScoreKeepModelContainer().testModelContainer()
    }

    @Test("startGame creates first set and game")
    @MainActor
    func startGameCreatesSetAndGame() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)

        #expect(match.sets.isEmpty)

        match.startGame()

        #expect(match.sets.count == 1)
        #expect(match.latestSet?.games.count == 1)
        #expect(match.latestGame != nil)
    }

    @Test("scorePoint delegates to latest game")
    @MainActor
    func scorePointDelegatesToGame() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)
        match.startGame()

        match.scorePoint(.us)
        #expect(match.latestGame?.scoreUs == 1)
    }

    @Test("startGame advances to next game in same set")
    @MainActor
    func startGameNextGameInSet() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    winAt: 3,
                    gameRules: ScoreKeepGameRules(winAt: 3)
                )
            )
        )
        context.insert(match)
        match.startGame()

        // Win game 1
        match.scorePoint(.us)
        match.scorePoint(.us)
        match.scorePoint(.us)

        #expect(match.latestGame?.hasEnded == true)

        match.startGame()
        #expect(match.sets.count == 1)
        #expect(match.latestSet?.games.count == 2)
        #expect(match.latestGame?.number == 2)
    }

    @Test("startGame advances to next set when set is won")
    @MainActor
    func startGameNextSet() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                winAt: 2,
                setRules: ScoreKeepSetRules(
                    winAt: 1,
                    gameRules: ScoreKeepGameRules(winAt: 3)
                )
            )
        )
        context.insert(match)
        match.startGame()

        // Win game 1 in set 1
        match.scorePoint(.us)
        match.scorePoint(.us)
        match.scorePoint(.us)

        // Set is won (winAt: 1 game), advance to next set
        match.startGame()
        #expect(match.sets.count == 2)
        #expect(match.latestSet?.number == 2)
    }

    @Test("end sets endedAt on game, set, and match")
    @MainActor
    func endSetsAllEndedAt() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)
        match.startGame()
        match.scorePoint(.us)

        match.end()

        #expect(match.endedAt != nil)
        #expect(match.latestSet?.endedAt != nil)
        #expect(match.latestGame?.endedAt != nil)
    }

    @Test("startWarmup creates warmup")
    @MainActor
    func startWarmupCreatesWarmup() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(.volleyball)
        context.insert(match)

        #expect(match.warmup == nil)

        match.startWarmup()
        #expect(match.warmup != nil)
        #expect(match.warmup?.hasEnded == false)
    }

    @Test("startWarmup is idempotent")
    @MainActor
    func startWarmupIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(.volleyball)
        context.insert(match)

        match.startWarmup()
        let warmup = match.warmup

        match.startWarmup()
        #expect(match.warmup === warmup)
    }

    @Test("Starting serve propagates from match to first game")
    @MainActor
    func startingServePropagatesFromMatch() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                setRules: ScoreKeepSetRules(
                    gameRules: ScoreKeepGameRules(winAt: 25)
                )
            )
        )
        context.insert(match)

        // Simulate warmup flow: set starting serve before creating first game
        match.startingServe = .them
        match.startGame()

        #expect(match.latestGame?.startingServe == .them)
    }

    @Test("Starting serve alternates between sets")
    @MainActor
    func startingServeAlternatesBetweenSets() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let match = ScoreKeepMatch(
            .volleyball,
            rules: ScoreKeepMatchRules(
                winAt: 3,
                setRules: ScoreKeepSetRules(
                    winAt: 1,
                    gameRules: ScoreKeepGameRules(winAt: 3)
                )
            ),
            startingServe: .us
        )
        context.insert(match)

        // Start and win set 1
        match.startGame()
        #expect(match.latestGame?.startingServe == .us)

        match.scorePoint(.us)
        match.scorePoint(.us)
        match.scorePoint(.us)

        // Start set 2 — should alternate to .them
        match.startGame()
        #expect(match.latestSet?.number == 2)
        #expect(match.latestGame?.startingServe == .them)
    }
}

// MARK: - ScoreKeepMatchTemplate Tests

@Suite("ScoreKeepMatchTemplate")
struct ScoreKeepMatchTemplateTests {
    @Test("createMatch returns match with template's rules and sport")
    @MainActor
    func createMatchUsesTemplateRulesAndSport() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let rules = ScoreKeepMatchRules(
            winAt: 3,
            setRules: ScoreKeepSetRules(
                winAt: 6,
                gameRules: ScoreKeepGameRules(winAt: 25, winBy: 2)
            )
        )
        let template = ScoreKeepMatchTemplate(
            .volleyball,
            name: "Test",
            rules: rules
        )
        context.insert(template)

        let match = template.createMatch()
        #expect(match.sport == .volleyball)
        #expect(match.rules == rules)
    }

    @Test("createMatch with markAsUsed sets lastUsedAt")
    @MainActor
    func createMatchSetsLastUsedAt() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(.volleyball, name: "Test")
        context.insert(template)

        #expect(template.lastUsedAt == nil)
        _ = template.createMatch(markAsUsed: true)
        #expect(template.lastUsedAt != nil)
    }

    @Test("createMatch with markAsUsed false does not set lastUsedAt")
    @MainActor
    func createMatchDoesNotSetLastUsedAt() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(.volleyball, name: "Test")
        context.insert(template)

        _ = template.createMatch(markAsUsed: false)
        #expect(template.lastUsedAt == nil)
    }
}
