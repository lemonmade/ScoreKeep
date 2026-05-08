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

    @Test("redo replays the last undone score")
    @MainActor
    func redoReplaysUndoneScore() throws {
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

        #expect(game.canRedo == false)

        game.undo()
        #expect(game.scoreUs == 1)
        #expect(game.canRedo == true)

        game.redo()
        #expect(game.scoreUs == 2)
        #expect(game.scoreThem == 1)
        #expect(game.canRedo == false)
    }

    @Test("scoring a new point clears the redo stack")
    @MainActor
    func scoringClearsRedoStack() throws {
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
        game.undo()
        #expect(game.canRedo == true)

        game.scorePoint(.them)
        #expect(game.canRedo == false)
    }

    @Test("undo is allowed on a finished game and re-opens it")
    @MainActor
    func undoOnFinishedGameReopensIt() throws {
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
        game.scorePoint(.us)
        #expect(game.hasEnded == true)
        #expect(game.canUndo == true)

        game.undo()
        #expect(game.scoreUs == 2)
        #expect(game.hasEnded == false)
        #expect(game.canRedo == true)
    }

    @Test("canRedo is false on a finished game")
    @MainActor
    func canRedoFalseOnFinishedGame() throws {
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
        game.scorePoint(.us)
        #expect(game.hasEnded == true)
        #expect(game.canRedo == false)
    }

    @Test("ScoreKeepMatch.redo delegates to latest game")
    @MainActor
    func matchRedoDelegates() throws {
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
        match.scorePoint(.them)
        match.undo()
        #expect(match.canRedo == true)

        match.redo()
        #expect(match.canRedo == false)
        #expect(match.latestGame?.scoreUs == 1)
        #expect(match.latestGame?.scoreThem == 1)
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

    /// Mirrors what `StartView.startNewMatch` does at runtime: build a match from a
    /// template, insert into the context, and call `startGame()`. Then verify the
    /// freshly-created game has live rules (so scoring + tennis 15-30-40 work).
    @Test("Live match flow: tennis startGame yields a game with canonical rules")
    @MainActor
    func liveTennisFlowResolvesGameRules() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(
            .tennis, name: "Tennis", environment: .outdoor
        )
        context.insert(template)

        let match = template.createMatch()
        context.insert(match)
        match.startGame()

        let game = try #require(match.latestGame)
        #expect(game.set != nil, "game.set should be wired by the inverse relationship")
        #expect(game.set?.match != nil, "set.match should be wired by the inverse relationship")

        let rules = try #require(
            game.rules,
            "game.rules should resolve via set.rules.gameRulesFor(game:)"
        )
        #expect(rules.winAt == 4)
        #expect(rules.winBy == 2)

        // 15-30-40 mapping should fire for canonical tennis.
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "0")
        match.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "15")
        match.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "30")
        match.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "40")
        match.scorePoint(.us)
        #expect(game.hasEnded, "game should end after 4-0 in canonical tennis")
    }

    /// Mirrors `StartView.swift` exactly: `defaultTemplates` is built in-memory
    /// (NOT inserted into the context), then the user taps one to start a match.
    /// Only the match is inserted; the template remains detached.
    @Test("StartView flow: detached template still produces canonical game rules")
    @MainActor
    func startViewFlowDetachedTemplateResolvesGameRules() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        // Note: template is NOT inserted, exactly like StartView.defaultTemplates.
        let template = ScoreKeepMatchTemplate(
            .tennis, name: "Tennis", environment: .outdoor
        )

        let match = template.createMatch()
        context.insert(match)
        match.startGame()

        let game = try #require(match.latestGame)
        #expect(game.set != nil, "game.set inverse relationship should wire even if template is detached")
        #expect(game.set?.match != nil, "set.match inverse relationship should wire even if template is detached")

        let rules = try #require(game.rules, "rules should resolve")
        #expect(rules.winAt == 4)

        match.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "15")
        match.scorePoint(.us)
        match.scorePoint(.us)
        match.scorePoint(.us)
        #expect(game.hasEnded, "game should end at 4-0 even when template is detached")
    }

    /// Same as the StartView flow but with `context.save()` after `startGame()` —
    /// matches the exact runtime ordering. Hypothesis: save is invalidating the
    /// in-memory relationship graph, leaving game.rules nil.
    @Test("StartView flow with save: tennis still resolves game rules after save")
    @MainActor
    func startViewFlowWithSaveResolvesGameRules() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(
            .tennis, name: "Tennis", environment: .outdoor
        )

        let match = template.createMatch()
        context.insert(match)
        match.startGame()
        try context.save()

        let game = try #require(match.latestGame)
        let rules = try #require(game.rules, "rules should resolve after save")
        #expect(rules.winAt == 4)

        match.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "15")
    }
}

// MARK: - ScoreKeepMatchParticipant Tests

@Suite("ScoreKeepMatchParticipant.deriveShortLabel")
struct ScoreKeepMatchParticipantDeriveShortLabelTests {
    @Test("Single word takes first 3 letters, uppercased")
    func singleWordPrefix() {
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "Lakers") == "LAK")
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "Opponent") == "OPP")
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "You") == "YOU")
    }

    @Test("Single word shorter than 3 letters returns the word uppercased")
    func singleShortWord() {
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "Us") == "US")
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "I") == "I")
    }

    @Test("Multi-word names use initials, uppercased")
    func multiWordInitials() {
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "Chris Sauve") == "CS")
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "Los Angeles Lakers") == "LAL")
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "John F Kennedy") == "JFK")
    }

    @Test("Initials cap at 4 characters")
    func initialsCap() {
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "a b c d e f") == "ABCD")
    }

    @Test("Whitespace is normalized")
    func extraWhitespace() {
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "  Mary  Anne  ") == "MA")
    }

    @Test("Hyphenated names are treated as a single word")
    func hyphenatedSingleWord() {
        #expect(ScoreKeepMatchParticipant.deriveShortLabel(from: "Mary-Anne") == "MAR")
    }

    @Test("resolvedShortLabel falls back to derivation when no override")
    func resolvedShortLabelDerivation() {
        let withName = ScoreKeepMatchParticipant(team: .us, name: "Chris Sauve")
        #expect(withName.resolvedShortLabel == "CS")

        let withoutName = ScoreKeepMatchParticipant(team: .them)
        #expect(withoutName.resolvedShortLabel == "OPP")
    }

    @Test("resolvedShortLabel honours an explicit override")
    func resolvedShortLabelOverride() {
        let participant = ScoreKeepMatchParticipant(
            team: .us, name: "Chris Sauve", shortLabel: "CMS"
        )
        #expect(participant.resolvedShortLabel == "CMS")
    }
}

// MARK: - Tennis Tiebreak Tests

@Suite("Tennis tiebreak")
struct TennisTiebreakTests {
    /// Build a tennis match whose set has played 12 alternating-winner games (6-6),
    /// plus an empty 13th game ready to be played as the tiebreak. Models are
    /// constructed without a SwiftData container — the rules logic doesn't need it,
    /// and skipping the container avoids ModelContext lifecycle issues across tests.
    @MainActor
    private func makeMatchAtTiebreak(
        rules: ScoreKeepMatchRules = ScoreKeepSport.tennis.defaultRules(),
        startingServe: ScoreKeepTeam = .us
    ) -> (ScoreKeepMatch, ScoreKeepGame) {
        var games: [ScoreKeepGame] = []
        for i in 1...12 {
            let usWins = (i % 2 == 1)
            games.append(
                ScoreKeepGame(
                    number: i,
                    us: usWins ? 4 : 0,
                    them: usWins ? 0 : 4,
                    endedAt: .now
                )
            )
        }
        let tiebreak = ScoreKeepGame(number: 13, startingServe: startingServe)
        games.append(tiebreak)

        let set = ScoreKeepSet(number: 1, games: games, startingServe: startingServe)
        let match = ScoreKeepMatch(.tennis, rules: rules, sets: [set], startingServe: startingServe)
        set.match = match
        return (match, tiebreak)
    }

    @Test("Tiebreak game is recognised as last-in-set and a tiebreak")
    @MainActor
    func tiebreakRecognised() {
        let (_, tiebreak) = makeMatchAtTiebreak()

        #expect(tiebreak.isLastInSet == true)
        #expect(tiebreak.isTiebreak == true)
        #expect(tiebreak.rules?.winAt == 7)
        #expect(tiebreak.rules?.winBy == 2)
    }

    @Test("Tiebreak shows raw point counts, never 15-30-40 or Ad")
    @MainActor
    func tiebreakRendersRawScores() {
        let (match, tiebreak) = makeMatchAtTiebreak()

        // Score 5-4 in the tiebreak (us leads).
        for _ in 0..<5 { tiebreak.scorePoint(.us) }
        for _ in 0..<4 { tiebreak.scorePoint(.them) }

        #expect(match.sport.normalizedScoreFor(.us, game: tiebreak) == 5)
        #expect(match.sport.normalizedScoreFor(.them, game: tiebreak) == 4)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: tiebreak) == "5")
        #expect(match.sport.normalizedScoreLabelFor(.them, game: tiebreak) == "4")
    }

    @Test("Tiebreak ends on win-by-2, no ceiling")
    @MainActor
    func tiebreakWinByTwo() {
        let (_, tiebreak) = makeMatchAtTiebreak()

        // Interleave to avoid hitting win-by-2 mid-loop.
        for _ in 0..<6 {
            tiebreak.scorePoint(.us)
            tiebreak.scorePoint(.them)
        }
        // 6-6: no winner
        #expect(tiebreak.hasEnded == false)

        // 7-6: scoreUs >= winAt but lead is 1, not enough.
        tiebreak.scorePoint(.us)
        #expect(tiebreak.hasEnded == false)

        // 8-6: lead of 2 wins.
        tiebreak.scorePoint(.us)
        #expect(tiebreak.hasEnded == true)
        #expect(tiebreak.winner == .us)
    }

    @Test("Tiebreak service rotation: starter serves point 1, then alternates every 2")
    @MainActor
    func tiebreakServiceRotation() {
        let (_, tiebreak) = makeMatchAtTiebreak(startingServe: .us)

        // Expected serve sequence for the first 12 points starting with .us:
        // point 1: us, points 2-3: them, points 4-5: us, points 6-7: them,
        // points 8-9: us, points 10-11: them, point 12: us
        let expected: [ScoreKeepTeam] = [
            .us, .them, .them, .us, .us, .them, .them, .us, .us, .them, .them, .us,
        ]

        for (idx, expectedTeam) in expected.enumerated() {
            #expect(
                tiebreak.servingTeam == expectedTeam,
                "Wrong server before point \(idx + 1)"
            )
            // Score doesn't matter for serve rotation, alternate to keep things tied-ish.
            tiebreak.scorePoint(idx.isMultiple(of: 2) ? .us : .them)
        }
    }

    @Test("ScoreKeepSet.tiebreakGame is nil before tiebreak starts")
    @MainActor
    func tiebreakGameAccessorEmpty() {
        let (match, _) = makeMatchAtTiebreak()
        let set = match.sets.first!
        #expect(set.tiebreakGame == nil)
    }

    @Test("ScoreKeepSet.tiebreakGame returns the 13th game once a point is played")
    @MainActor
    func tiebreakGameAccessorPopulated() {
        let (match, tiebreak) = makeMatchAtTiebreak()
        tiebreak.scorePoint(.us)

        let set = match.sets.first!
        #expect(set.tiebreakGame === tiebreak)
        #expect(set.tiebreakGame?.scoreFor(.us) == 1)
    }
}

// MARK: - Tennis Score Label Tests

@Suite("Tennis score labels")
struct TennisScoreLabelTests {
    @MainActor
    private func makeTennisGame(
        rules: ScoreKeepMatchRules = ScoreKeepSport.tennis.defaultRules()
    ) -> (ScoreKeepMatch, ScoreKeepGame) {
        let game = ScoreKeepGame(number: 1)
        let set = ScoreKeepSet(number: 1, games: [game])
        let match = ScoreKeepMatch(.tennis, rules: rules, sets: [set])
        set.match = match
        return (match, game)
    }

    @Test("Canonical tennis: 0/15/30/40 mapping applies")
    @MainActor
    func canonicalTennisMapping() {
        let (match, game) = makeTennisGame()

        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "0")
        game.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "15")
        game.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "30")
        game.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "40")
    }

    @Test("Canonical tennis: leading team shows 'Ad' at deuce+1")
    @MainActor
    func canonicalAdvantageLabel() {
        let (match, game) = makeTennisGame()

        // 3-3 = deuce
        for _ in 0..<3 { game.scorePoint(.us) }
        for _ in 0..<3 { game.scorePoint(.them) }
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "40")
        #expect(match.sport.normalizedScoreLabelFor(.them, game: game) == "40")

        // 4-3: us has Ad
        game.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "Ad")
        #expect(match.sport.normalizedScoreLabelFor(.them, game: game) == "40")
    }

    @Test("No-ad tennis (winBy=1): keeps 15-30-40 mapping but never shows Ad")
    @MainActor
    func noAdKeepsMappingButNoAdvantage() {
        let noAdRules = ScoreKeepMatchRules(
            winAt: 1, winBy: 1, maximum: 1,
            setRules: ScoreKeepSetRules(
                winAt: 6, winBy: 2, maximum: 7,
                gameRules: ScoreKeepGameRules(winAt: 4, winBy: 1),
                lastGameRules: ScoreKeepGameRules(winAt: 7, winBy: 2)
            )
        )
        let (match, game) = makeTennisGame(rules: noAdRules)

        for _ in 0..<3 { game.scorePoint(.us) }
        for _ in 0..<3 { game.scorePoint(.them) }
        // No-ad still uses 15-30-40 visually — that's how the score is conventionally shown.
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "40")
        #expect(match.sport.normalizedScoreLabelFor(.them, game: game) == "40")
    }

    @Test("Games-to-five tennis (winAt=5): no 15-30-40 mapping")
    @MainActor
    func gamesToFiveSkipsTennisMapping() {
        let customRules = ScoreKeepMatchRules(
            winAt: 1, winBy: 1, maximum: 1,
            setRules: ScoreKeepSetRules(
                winAt: 5, winBy: 2, maximum: 6,
                gameRules: ScoreKeepGameRules(winAt: 5, winBy: 2),
                lastGameRules: ScoreKeepGameRules(winAt: 7, winBy: 2)
            )
        )
        let (match, game) = makeTennisGame(rules: customRules)

        game.scorePoint(.us)
        game.scorePoint(.us)
        #expect(match.sport.normalizedScoreLabelFor(.us, game: game) == "2")
    }

    @Test("Detached tennis game (no resolvable rules) still shows 15-30-40")
    @MainActor
    func detachedTennisGameUsesCanonicalMapping() {
        // A bare game with no parent set/match — `game.rules` returns nil. The
        // history detail view can hit this if the inverse relationship isn't
        // hydrated. We default to canonical tennis mapping so users see 15/30/40
        // instead of raw 1/2/3.
        let game = ScoreKeepGame(number: 1, us: 2, them: 1)
        #expect(game.rules == nil)
        #expect(ScoreKeepSport.tennis.normalizedScoreLabelFor(.us, game: game) == "30")
        #expect(ScoreKeepSport.tennis.normalizedScoreLabelFor(.them, game: game) == "15")
    }
}

