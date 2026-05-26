//
//  ActiveMatchView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-01-07.
//

import ScoreKeepCore
import ScoreKeepUI
import SwiftUI

struct ActiveMatchView: View {
  @Environment(ScoreKeepMatch.self) private var match
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    if let warmup = match.warmup, !warmup.hasEnded {
      ActiveMatchWarmupView(
        match: match,
        onDismiss: { dismiss() }
      )
    } else if match.latestGame != nil {
      ActiveMatchScoringView(
        match: match,
        onDismiss: { dismiss() }
      )
    } else {
      ContentUnavailableView(
        "No active game",
        systemImage: "sportscourt",
        description: Text("Start a game to begin scoring")
      )
    }
  }
}

// MARK: - Scoring screen

struct ActiveMatchScoringView: View {
  @Bindable var match: ScoreKeepMatch
  var onDismiss: () -> Void

  @State private var showEditSheet: Bool = false

  private var canStartNextGame: Bool {
    guard let latestGame = match.latestGame else { return false }
    return latestGame.hasEnded && !match.hasWinner && match.hasMoreGames
  }

  /// Only show the per-set/per-game table when it adds context beyond the
  /// headline scoreboard — multi-set matches, or short single-set formats
  /// (best-of-2…5 games) where each game's score is worth surfacing.
  private var showsScoreTable: Bool {
    let isMultiGameOrMore = match.isMultiSet || (match.latestSet?.isMultiGame ?? false)
    guard isMultiGameOrMore else { return false }

    if !match.isMultiSet {
      let maxGames = match.rules.setRules.maximumGameCount ?? 0
      return maxGames >= 2 && maxGames <= 5
    }

    return true
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        ActiveMatchHeaderView(match: match)
          .padding(.horizontal, 20)
          .padding(.top, 8)

        if showsScoreTable {
          MatchScoreboardTableView(match: match)
            .padding(.horizontal, 20)
        }

        if canStartNextGame {
          Button {
            withAnimation(.snappy) { match.startGame() }
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "play.fill")
              Text("Start Next Game")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(0.18), in: Capsule())
            .foregroundStyle(Color.accentColor)
          }
          .padding(.horizontal, 20)
          .transition(.scale.combined(with: .opacity))
        }

        Spacer(minLength: 0)

        ActiveMatchScoringButtonsRow(
          match: match,
          onLongPress: { showEditSheet = true }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .background(Color(.systemGroupedBackground))
      .navigationTitle(match.label)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            withAnimation { match.end() }
            onDismiss()
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "xmark")
              Text("End Match")
            }
          }
          .tint(.red)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showEditSheet = true
          } label: {
            Image(systemName: "ellipsis.circle")
          }
          .accessibilityLabel("More actions")
        }
      }
      .animation(.snappy, value: canStartNextGame)
      .sheet(isPresented: $showEditSheet) {
        ActiveMatchEditSheet(match: match)
          .presentationDetents([.medium])
      }
    }
  }
}

// MARK: - Apple Sports–style header

struct ActiveMatchHeaderView: View {
  var match: ScoreKeepMatch

  /// Pills are sized to a uniform width so the two halves are visually balanced
  /// regardless of label length ("Us" vs "Opp" vs longer participant names).
  private let pillWidth: CGFloat = 56

  var body: some View {
    VStack(spacing: 6) {
      HStack(alignment: .center, spacing: 8) {
        ActiveMatchHeaderTeamView(
          match: match, team: .us, alignment: .leading, pillWidth: pillWidth
        )

        ActiveMatchHeaderCenterView(match: match)

        ActiveMatchHeaderTeamView(
          match: match, team: .them, alignment: .trailing, pillWidth: pillWidth
        )
      }
    }
  }
}

private struct ActiveMatchHeaderTeamView: View {
  var match: ScoreKeepMatch
  var team: ScoreKeepTeam
  var alignment: HorizontalAlignment
  var pillWidth: CGFloat

  private var participant: ScoreKeepMatchParticipant { match.participant(for: team) }
  private var keyColor: Color { participant.resolvedColor.color }
  private var shortLabel: String { participant.resolvedShortLabel }

  private var game: ScoreKeepGame? { match.latestGame }

  private var normalizedScore: Int {
    guard let game else { return 0 }
    return match.sport.normalizedScoreFor(team, game: game)
  }

  private var normalizedScoreLabel: String {
    guard let game else { return "0" }
    return match.sport.normalizedScoreLabelFor(team, game: game)
  }

  private var transitionValue: Double {
    if normalizedScoreLabel == "Ad" { return Double(normalizedScore) + 5 }
    return Double(normalizedScore)
  }

  private var isWinner: Bool { game?.winner == team }
  private var isServing: Bool { game?.servingTeam == team && game?.hasEnded == false }

  var body: some View {
    VStack(spacing: 10) {
      scoreText

      HStack(spacing: 6) {
        if alignment == .leading {
          teamPill
          serveIndicatorSlot
        } else {
          serveIndicatorSlot
          teamPill
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  /// Fixed-size slot so the serve ball appearing/disappearing never shifts the
  /// pill or the score above it.
  private var serveIndicatorSlot: some View {
    ZStack {
      if isServing { serveIcon }
    }
    .frame(width: 18, height: 18)
  }

  private var teamPill: some View {
    HStack(spacing: 4) {
      if isWinner {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 10, weight: .bold))
      }
      Text(shortLabel)
        .lineLimit(1)
    }
    .font(.caption)
    .fontWeight(.heavy)
    .textCase(.uppercase)
    .foregroundStyle(.white)
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .frame(minWidth: pillWidth)
    .background(keyColor, in: Capsule())
    .shadow(color: keyColor.opacity(0.25), radius: 4, y: 2)
  }

  private var scoreText: some View {
    GameScoreNumberView(
      label: normalizedScoreLabel,
      transitionValue: transitionValue,
      color: keyColor
    )
    .foregroundStyle(keyColor)
  }

  private var serveIcon: some View {
    Image(systemName: match.sport.ballIcon)
      .font(.system(size: 14, weight: .bold))
      .foregroundStyle(keyColor.opacity(0.85))
      .transition(.scale.combined(with: .opacity))
  }
}

private struct ActiveMatchHeaderCenterView: View {
  var match: ScoreKeepMatch

  private var game: ScoreKeepGame? { match.latestGame }

  private var titleText: String {
    if match.hasWinner { return "Final" }
    if let game, game.hasEnded { return "Game \(game.number) Over" }
    if let game { return "Game \(game.number)" }
    return ""
  }

  var body: some View {
    VStack(spacing: 2) {
      Text(titleText)
        .font(.caption2)
        .fontWeight(.semibold)
        .textCase(.uppercase)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      if let game, !match.hasWinner {
        TimelineView(.periodic(from: game.startedAt, by: 1)) { context in
          Text(
            context.date,
            format: .stopwatch(startingAt: game.startedAt, maxPrecision: .seconds(1))
          )
        }
        .font(.system(.caption2, design: .rounded).monospacedDigit())
        .foregroundStyle(.tertiary)
      }

      if match.isMultiSet, let set = match.latestSet {
        Text("Set \(set.number)")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.tertiary)
      }
    }
    .fixedSize()
    .padding(.horizontal, 4)
  }
}

// MARK: - Side-by-side scoring buttons

struct ActiveMatchScoringButtonsRow: View {
  var match: ScoreKeepMatch
  var onLongPress: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      ScoreKeepTeamScoringButton(team: .us, match: match, onLongPress: onLongPress)
      ScoreKeepTeamScoringButton(team: .them, match: match, onLongPress: onLongPress)
    }
  }
}

struct ScoreKeepTeamScoringButton: View {
  var team: ScoreKeepTeam
  var match: ScoreKeepMatch
  var onLongPress: (() -> Void)?

  @State private var longPressTriggered = false

  private var participant: ScoreKeepMatchParticipant {
    match.participant(for: team)
  }

  private var keyColor: Color { participant.resolvedColor.color }
  private var game: ScoreKeepGame? { match.latestGame }
  private var isDisabled: Bool { game?.hasEnded ?? true }
  private var isServing: Bool { game?.servingTeam == team && game?.hasEnded == false }

  var body: some View {
    Button {
      if longPressTriggered { return }
      guard let game, !game.hasEnded else { return }
      withAnimation(.snappy) { match.scorePoint(team) }
    } label: {
      ScoreKeepTeamScoringButtonLabel(
        match: match, team: team, isServing: isServing
      )
    }
    .buttonStyle(ScoreKeepFilledButtonStyle(keyColor: keyColor))
    .simultaneousGesture(
      LongPressGesture(minimumDuration: 0.6)
        .onEnded { _ in
          longPressTriggered = true
          onLongPress?()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            longPressTriggered = false
          }
        }
    )
    .disabled(isDisabled)
    .sensoryFeedback(.impact(weight: .medium), trigger: game?.scoreFor(team) ?? 0) { old, new in
      old != new
    }
    .sensoryFeedback(.selection, trigger: longPressTriggered)
  }
}

private struct ScoreKeepTeamScoringButtonLabel: View {
  var match: ScoreKeepMatch
  var team: ScoreKeepTeam
  var isServing: Bool

  private var participant: ScoreKeepMatchParticipant { match.participant(for: team) }
  private var keyColor: Color { participant.resolvedColor.color }

  var body: some View {
    VStack(spacing: 12) {
      // Top: serve indicator (reserves space when not serving so layout doesn't jump)
      ZStack {
        if isServing {
          Image(systemName: match.sport.ballIcon)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .frame(height: 28)

      Image(systemName: "plus")
        .font(.system(size: 36, weight: .bold))
        .foregroundStyle(.white)

      Text(participant.resolvedShortLabel)
        .font(.caption)
        .fontWeight(.heavy)
        .textCase(.uppercase)
        .foregroundStyle(keyColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.white, in: Capsule())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, 24)
    .contentShape(.rect)
  }
}

struct ScoreKeepFilledButtonStyle: ButtonStyle {
  var keyColor: Color

  func makeBody(configuration: Configuration) -> some View {
    ScoreKeepFilledButtonStyleBody(configuration: configuration, keyColor: keyColor)
  }
}

private struct ScoreKeepFilledButtonStyleBody: View {
  let configuration: ButtonStyle.Configuration
  let keyColor: Color

  @Environment(\.isEnabled) private var isEnabled: Bool

  var body: some View {
    configuration.label
      .background(keyColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
      .shadow(color: keyColor.opacity(0.35), radius: 12, y: 6)
      .opacity(isEnabled ? 1 : 0.45)
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

// MARK: - Edit Sheet

struct ActiveMatchEditSheet: View {
  @Environment(\.dismiss) var dismiss
  var match: ScoreKeepMatch

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            withAnimation { match.undo() }
            dismiss()
          } label: {
            Label("Undo last point", systemImage: "arrow.uturn.backward")
          }
          .disabled(!match.canUndo)

          Button {
            withAnimation { match.redo() }
            dismiss()
          } label: {
            Label("Redo last point", systemImage: "arrow.uturn.forward")
          }
          .disabled(!match.canRedo)
        }
      }
      .navigationTitle("Actions")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

// MARK: - Warmup View

struct ActiveMatchWarmupView: View {
  var match: ScoreKeepMatch
  var onDismiss: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 32) {
        Spacer()

        VStack(spacing: 16) {
          Image(systemName: "figure.run")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundStyle(.secondary)

          Text("Warmup")
            .font(.largeTitle)
            .fontWeight(.bold)

          if let warmup = match.warmup {
            TimelineView(.periodic(from: warmup.startedAt, by: 0.1)) { context in
              Text(
                context.date,
                format: .stopwatch(startingAt: warmup.startedAt, maxPrecision: .seconds(1))
              )
            }
            .font(.system(.title, design: .rounded).monospacedDigit())
            .foregroundStyle(.secondary)
          }
        }

        Spacer()

        Button {
          match.startGame()
        } label: {
          Text("Start Match")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(16)
        }
        .padding(.horizontal)
      }
      .navigationTitle(match.label)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            match.end()
            onDismiss()
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "xmark")
              Text("End Match")
            }
          }
        }
      }
    }
  }
}

// MARK: - Preview

#Preview("Tennis, multi-set") {
  ActiveMatchView()
    .environment(
      ScoreKeepMatch(
        from: ScoreKeepMatchTemplate(
          .tennis,
          name: "Tennis",
          color: .neutral,
          environment: .outdoor,
          rules: ScoreKeepMatchRules(
            winAt: 2,
            setRules: ScoreKeepSetRules(
              winAt: 6,
              winBy: 2,
              maximum: 7,
              gameRules: ScoreKeepGameRules(winAt: 4, winBy: 2)
            )
          )
        ),
        sets: [
          ScoreKeepSet(
            number: 1,
            games: [
              ScoreKeepGame(us: 4, them: 2, endedAt: .now.advanced(by: -200)),
              ScoreKeepGame(us: 4, them: 1, endedAt: .now.advanced(by: -150)),
            ],
            endedAt: .now.advanced(by: -150)
          ),
          ScoreKeepSet(
            number: 2,
            games: [
              ScoreKeepGame(us: 1, them: 4, endedAt: .now.advanced(by: -80)),
              ScoreKeepGame(us: 2, them: 1),
            ]
          ),
        ]
      )
    )
}

#Preview("Volleyball, single set") {
  ActiveMatchView()
    .environment(
      ScoreKeepMatch(
        from: ScoreKeepMatchTemplate(
          .volleyball,
          name: "Indoor volleyball",
          environment: .indoor
        ),
        sets: [
          ScoreKeepSet(
            games: [
              ScoreKeepGame(us: 25, them: 19, endedAt: .now.advanced(by: -100)),
              ScoreKeepGame(us: 12, them: 8),
            ]
          ),
        ]
      )
    )
}
