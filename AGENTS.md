# ScoreKeep — Agent Guide

ScoreKeep is a native scorekeeping app for **iOS** and **watchOS** (Apple Watch first). It tracks live matches across volleyball, ultimate, squash, tennis, and pickleball, with sport-specific rules (rotation, side-out vs. rally, tennis ad scoring). The Watch app is the primary live-scoring surface; the iOS app handles templates, history, and sharing.

## Strategic context: funnel into Sessions

ScoreKeep ships as a **standalone app**, but it is also designed to be a **specialized funnel** into the Sessions app at `../../Sessions` (i.e. `/Users/lemon/dev/Sessions` relative to this checkout's parent). Sessions is a broader scheduling/operations product that already knows about real-world events, participants, and teams. ScoreKeep's job in the joint product is to be the *best possible "score this match right now" experience* and feed structured results back into Sessions.

That dual mandate shapes every design call:

- **Standalone-complete first.** Every feature must work for a user who has never heard of Sessions. Don't build code paths that require a Sessions context to function. The iOS/Watch apps continue to use SwiftData + CloudKit on their own.
- **Eventually, matches arrive injected from Sessions.** Sessions knows the schedule (when a match starts, who's playing, which teams). When that integration lands, ScoreKeep should accept a "pre-filled" match and let the user just keep score — no template setup, real participant names, real team names, real opponents. Today's `MatchTemplate` flow is the standalone equivalent of what Sessions will inject.
- **Participants and teams are the next big domain expansion.** Today the model uses `MatchTeam.us` / `MatchTeam.them` and there is no concept of a participant or named team. Adding real participants/teams (probably as new `@Model` types in `ScoreKeepCore`) is the bridge that lets injected Sessions data feel native, *and* makes the standalone app meaningfully better (named opponents, history filtered by team, multi-player stats). When you design these models, design them to be populatable from Sessions data without making them depend on Sessions.
- **The web sharing endpoint at `scorekeep.watch` is a separate surface.** It's how a user shares a finished match publicly. Don't conflate it with the (future) Sessions integration, which is private app-to-app data flow.

When in doubt: would this still make sense if Sessions did not exist? If yes, ship it. If it only makes sense as part of Sessions, slow down — there's probably a way to model it so the standalone path keeps working.

## Project layout

```
ScoreKeep.xcodeproj             # umbrella Xcode project
ScoreKeep iOS App/              # iOS target
  Pages/                        # top-level navigation destinations
  Views/                        # supporting iOS views
ScoreKeep Watch App/            # watchOS target
  Views/                        # watch-specific views (Active*, History*, etc.)
  WorkoutManager.swift          # HealthKit workout integration
  NavigationManager.swift       # watch navigation state
ScoreKeepCore/                  # Swift package: data model + business logic
  Sources/ScoreKeepCore/
    MatchModels.swift           # Match, MatchSet, MatchGame, MatchTemplate, scoring rules
    ScoreKeepModels.swift       # higher-level / shared model glue
    ScoreKeepWeb.swift          # GraphQL client for scorekeep.watch sharing
    ScoreKeepCore.swift
ScoreKeepUI/                    # Swift package: shared SwiftUI components used by both apps
  Sources/ScoreKeepUI/
    MatchTotalScoreSummaryView.swift
    MatchHistorySummaryView.swift
```

Both Swift packages target **iOS 26 / watchOS 26 / macOS 26** with **swift-tools-version 6.2**. `ScoreKeepUI` depends on `ScoreKeepCore`. The two app targets depend on both packages via the Xcode project.

## Data model essentials

The model lives in [ScoreKeepCore/Sources/ScoreKeepCore/MatchModels.swift](ScoreKeepCore/Sources/ScoreKeepCore/MatchModels.swift). The hierarchy:

- `Match` — one match. Has a `MatchSport`, `MatchEnvironment`, `MatchScoringRules`, and a list of `MatchSet`s. Optionally references a `MatchTemplate` it was created from and a `MatchWarmup`.
- `MatchSet` — one set within a match. Has a list of `MatchGame`s.
- `MatchGame` — one game (or "rally sequence") within a set. Holds an array of `MatchGameScore` events.
- `MatchTemplate` — reusable preset (sport, name, color, scoring rules, warmup behavior, "start workout" flag). The user picks one to create a new match.
- `MatchWarmup` — optional pre-match warmup period.
- `MatchScoringRules` / `MatchSetScoringRules` / `MatchGameScoringRules` — three nested layers of scoring config (winAt / winBy / maximum / playItOut) with sport-aware defaults.

All entities are persisted via **SwiftData** with **CloudKit** sync (`cloudKitDatabase: .automatic`). The shared schema is declared in `MatchModelContainer`.

A few conventions worth knowing before you edit models:

- Public types and members across `ScoreKeepCore` are explicitly marked `public` — required because the apps consume the package.
- SwiftData relationships use the `_propertyName` private storage + a sorted public accessor pattern (e.g. `_sets` / `sets`, `_games` / `games`) to work around SwiftData's unordered relationship arrays. Preserve this when adding new collections.
- `MatchTeam` is a two-value enum (`.us`, `.them`). When you add real participants/teams, do **not** rip out `MatchTeam` — a lot of scoring logic keys off it. The likely migration is "`us`/`them` are role-labels within a match; participants/teams are separate entities that get *assigned* to those roles."
- Sport-specific behavior (service rotation, side-out vs. rally, tennis ad scoring) lives on `MatchSport` itself. Add new sports there.

## Web / sharing

[ScoreKeepCore/Sources/ScoreKeepCore/ScoreKeepWeb.swift](ScoreKeepCore/Sources/ScoreKeepCore/ScoreKeepWeb.swift) posts a `createMatch` GraphQL mutation to `https://scorekeep.watch/graphql` and returns a `https://scorekeep.watch/match/<id>` URL. This is **public sharing**, not Sessions integration — the two should remain independent.

## Working with the codebase

- Open `ScoreKeep.xcodeproj` in Xcode to build the apps. The Swift packages are referenced from the project.
- Lint config is at `.swiftlint.yml`.
- Tests:
  - `ScoreKeepCore/Tests/ScoreKeepCoreTests/`
  - `ScoreKeepUI/Tests/ScoreKeepUITests/`
  - `ScoreKeep iOS AppTests/`, `ScoreKeep iOS AppUITests/`
  - `ScoreKeep Watch AppTests/`, `ScoreKeep Watch AppUITests/`
- Prefer running model/business-logic tests via `swift test` inside the relevant package directory; run app/UI tests via Xcode (they need the simulator).
- For UI changes, build & run the actual target — type checks alone do not verify watchOS layout or HealthKit/CloudKit behavior.

## Stylistic notes

- SwiftUI everywhere; no UIKit/AppKit unless wrapping something Apple hasn't bridged.
- Keep view files focused on one screen; common subviews graduate into `ScoreKeepUI`.
- Prefer extending `MatchSport` / `MatchScoringRules` over branching on sport at the call site.
- Don't introduce dependencies on Sessions, networking layers, or auth in `ScoreKeepCore` until the Sessions integration is actually being built — keep the standalone build clean.
