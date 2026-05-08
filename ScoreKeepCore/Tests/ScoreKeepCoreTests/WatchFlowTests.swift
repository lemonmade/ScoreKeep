import Foundation
import SwiftData
import Testing

@testable import ScoreKeepCore

/// Regression tests for end-of-match propagation. SwiftData's @Model macro strips
/// `didSet` observers from synthesized accessors, so the previous didSet-based
/// chain (game.endedAt → set.endedAt → match.endedAt) never fired and matches
/// would keep accepting points past the win condition. See issue: ultimate
/// "first to 15" matches stayed open at 15-N, brand-new tennis games scored
/// past 4-0.
@Suite("End-condition propagation")
struct EndConditionPropagationTests {
    @Test("Ultimate first-to-15: game/set/match all end when score reaches 15")
    @MainActor
    func ultimateAutoEnd() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(
            .ultimate, name: "Ultimate frisbee",
            environment: .outdoor,
            warmup: .none
        )
        context.insert(template)

        let match = template.createMatch()
        match.startingServe = .us
        match.startGame()
        context.insert(match)
        try context.save()

        let game = try #require(match.latestGame)
        let set = try #require(game.set)

        for _ in 0..<10 { match.scorePoint(.them) }
        for _ in 0..<15 { match.scorePoint(.us) }

        #expect(game.hasEnded, "game should end at 15")
        #expect(set.hasEnded, "single-game set should end when its only game ends")
        #expect(match.hasEnded, "single-set match should end when its only set ends")
    }

    @Test("Tennis canonical: scoring stops at 4-0 because game ends")
    @MainActor
    func tennisGameAutoEnd() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(
            .tennis, name: "Tennis", environment: .outdoor, warmup: .none
        )
        context.insert(template)

        let match = template.createMatch()
        match.startingServe = .us
        match.startGame()
        context.insert(match)
        try context.save()

        let game = try #require(match.latestGame)

        for _ in 0..<10 { match.scorePoint(.us) }

        #expect(game.scoreUs == 4, "scoring should stop once the game ends at 4-0")
        #expect(game.hasEnded)
    }

    @Test("Warmup-then-start flow: tennis still auto-ends at 4-0")
    @MainActor
    func tennisWarmupFlowAutoEnd() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(
            .tennis, name: "Tennis", environment: .outdoor, warmup: .open
        )
        context.insert(template)

        let match = template.createMatch()
        match.startWarmup()
        context.insert(match)
        try context.save()

        // ActiveMatchWarmupView doesn't save between startGame() and the user's
        // first scoring tap, so we don't either — saving in between can detach
        // SwiftData relationships and is a separate concern.
        match.warmup?.end()
        match.startingServe = .us
        match.startGame()

        let game = try #require(match.latestGame)
        for _ in 0..<4 { match.scorePoint(.us) }

        #expect(game.hasEnded, "tennis game should end at 4-0 even after warmup flow")
    }
}

@Suite("Inverse-relationship hardening")
struct InverseRelationshipTests {
    @Test("addSet wires set.match inverse explicitly (not just via @Relationship)")
    @MainActor
    func addSetWiresInverse() throws {
        // No context at all — just verify the explicit assignments.
        let template = ScoreKeepMatchTemplate(
            .pickleball, name: "Pickleball", environment: .outdoor, warmup: .none
        )
        let match = template.createMatch()
        match.startingServe = .us
        match.startGame()

        let set = try #require(match.latestSet)
        let game = try #require(set.latestGame)

        #expect(set.match === match, "set.match should be set explicitly to match")
        #expect(game.set === set, "game.set should be set explicitly to set")
    }

    @Test("Pickleball post-save: scoring still respects 11-point cap")
    @MainActor
    func pickleballPostSave() throws {
        let container = ScoreKeepModelContainer().testModelContainer()
        let context = container.mainContext

        let template = ScoreKeepMatchTemplate(
            .pickleball,
            name: "Pickleball",
            environment: .outdoor,
            rules: ScoreKeepMatchRules(
                winAt: 1,
                setRules: ScoreKeepSetRules(
                    winAt: 2,
                    gameRules: ScoreKeepGameRules(winAt: 11, winBy: 2)
                )
            ),
            warmup: .open
        )

        // Watch flow: warmup template + onAppear ordering.
        let match = template.createMatch()
        match.startWarmup()
        context.insert(match)
        try context.save()

        // Warmup view: end warmup and start game. Force a save here to flush the
        // newly-created set/game. This is what differs from the test above and
        // mimics SwiftData's auto-save behaviour in a long-running app.
        match.warmup?.end()
        match.startingServe = .us
        match.startGame()
        try context.save()

        let game = try #require(match.latestGame)

        // Score 20 points for us — should cap at 11 because the game ends.
        for _ in 0..<20 { match.scorePoint(.us) }

        #expect(game.scoreUs <= 11, "game must not score past 11; got \(game.scoreUs)")
        #expect(game.hasEnded, "game must end at the win condition")
    }
}
