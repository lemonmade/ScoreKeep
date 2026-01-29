//
//  ActiveMatchView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-01-07.
//

import ScoreKeepCore
import SwiftUI

struct ActiveMatchView: View {
    @Environment(ScoreKeepMatch.self) private var match
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if match.latestGame != nil {
            ActiveMatchScoringView(match: match, onDismiss: {
                dismiss()
            })
        } else {
            ContentUnavailableView(
                "No active game",
                systemImage: "sportscourt",
                description: Text("Start a game to begin scoring")
            )
        }
    }
}

struct ActiveMatchScoringView: View {
    var match: ScoreKeepMatch
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top half: Match summary
                    ActiveMatchSummarySection(match: match)
                        .frame(height: geometry.size.height * 0.4)
                        .background(Color(.systemBackground))
                    
                    // Bottom half: Scoring buttons
                    ActiveMatchScoringButtonsSection(match: match)
                        .frame(height: geometry.size.height * 0.6)
                }
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        match.startGame()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next Game")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .disabled(!canStartNextGame)
                }
            }
        }
    }
    
    private var canStartNextGame: Bool {
        guard let latestGame = match.latestGame else { return false }
        return latestGame.hasEnded && !match.hasWinner
    }
}

// MARK: - Summary Section

struct ActiveMatchSummarySection: View {
  var match: ScoreKeepMatch

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Score table
        ScoreKeepMatchSummaryScoreTableView(match: match)
          .padding(.horizontal)

        // Time elapsed
        HStack(spacing: 8) {
          TimelineView(.periodic(from: match.startedAt, by: 0.1)) { context in
            Text(
              context.date,
              format: .stopwatch(startingAt: match.startedAt, maxPrecision: .seconds(1))
            )
          }
        }
        .font(.system(.caption, design: .rounded).monospacedDigit())
        .foregroundStyle(.secondary)

        // Match info
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: match.sport.figureIcon)
              .font(.title3)
            Text(match.label)
              .font(.headline)
          }

          HStack(spacing: 12) {
            Label(match.rules.primaryLabel, systemImage: "trophy")
            Label(match.rules.secondaryLabel, systemImage: "chart.bar")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
      }
      .padding(.vertical)
    }
  }
}

// MARK: - Scoring Buttons Section

struct ActiveMatchScoringButtonsSection: View {
  var match: ScoreKeepMatch

  private let spacing: CGFloat = 12
  private let padding: CGFloat = 16

  @State private var showUndoSheet: Bool = false

  var body: some View {
    VStack(spacing: spacing) {
      ScoreKeepTeamScoringButton(
        team: .them,
        match: match,
        onLongPress: { showUndoSheet = true }
      )

      ScoreKeepTeamScoringButton(
        team: .us,
        match: match,
        onLongPress: { showUndoSheet = true }
      )
    }
    .padding(padding)
    .sheet(isPresented: $showUndoSheet) {
      ActiveMatchEditSheet(match: match)
        .presentationDetents([.medium])
    }
  }
}

// MARK: - Team Scoring Button

struct ScoreKeepTeamScoringButton: View {
  var team: ScoreKeepTeam
  var match: ScoreKeepMatch
  var onLongPress: (() -> Void)?

  @State private var longPressTriggered = false

  var keyColor: Color {
    team == .us ? .blue : .red
  }

  var game: ScoreKeepGame {
    match.latestGame!
  }

  var body: some View {
    Button(
      action: {
        if longPressTriggered { return }
        match.scorePoint(team)
      },
      label: {
        ScoreKeepTeamScoreView(match: match, team: team, game: game)
          .foregroundStyle(keyColor)
      }
    )
    .buttonStyle(ScoreKeepButtonStyle(keyColor: keyColor))
    .simultaneousGesture(
      LongPressGesture(minimumDuration: 1)
        .onEnded { _ in
          longPressTriggered = true
          onLongPress?()

          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            longPressTriggered = false
          }
        }
    )
    .disabled(game.hasEnded)
    .sensoryFeedback(
      .impact(weight: .medium), trigger: game.scoreFor(team),
      condition: { old, new in
        return old != new
      }
    )
    .sensoryFeedback(.selection, trigger: longPressTriggered)
  }
}

struct ScoreKeepButtonStyle: ButtonStyle {
  var keyColor: Color

  func makeBody(configuration: Configuration) -> some View {
    ScoreKeepButtonStyleView(configuration: configuration, keyColor: keyColor)
  }

  struct ScoreKeepButtonStyleView: View {
    let configuration: ButtonStyle.Configuration
    let keyColor: Color

    @Environment(\.isEnabled) private var isEnabled: Bool

    var body: some View {
      configuration.label
        .background(keyColor.opacity(0.2))
        .cornerRadius(20)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .strokeBorder(keyColor.opacity(0.3), lineWidth: 2)
        )
        .opacity(isEnabled ? 1 : 0.6)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
  }
}

struct ScoreKeepTeamScoreView: View {
  var match: ScoreKeepMatch
  var team: ScoreKeepTeam
  var game: ScoreKeepGame

  var score: Int {
    game.scoreFor(team)
  }

  var normalizedScore: Int {
    match.sport.normalizedScoreFor(team, game: game)
  }

  var normalizedScoreLabel: String {
    match.sport.normalizedScoreLabelFor(team, game: game)
  }

  var keyColor: Color {
    team == .us ? .blue : .red
  }

  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        if game.winner == team {
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .frame(width: 32, height: 32)
        } else {
          ScoreKeepTeamServeIndicatorView(team: team, match: match, game: game)
        }

        Text(team == .us ? "Us" : "Them")
          .textCase(.uppercase)
          .font(.caption)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(keyColor)
          .cornerRadius(8)
      }

      Spacer()

      HStack(spacing: 0) {
        if score < 10 && match.sport != .tennis {
          Text("0")
            .font(.system(size: 80, weight: .bold))
            .opacity(0.5)
        }
        Text(normalizedScoreLabel)
          .font(.system(size: 80, weight: .bold))
          .contentTransition(.numericText(value: Double(normalizedScore)))
      }
      .fontDesign(.rounded)
    }
    .padding(16)
    .monospacedDigit()
    .contentShape(.rect)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct ScoreKeepTeamServeIndicatorView: View {
  var team: ScoreKeepTeam
  var match: ScoreKeepMatch
  var game: ScoreKeepGame

  var body: some View {
    if team == game.servingTeam {
      HStack(alignment: .bottom, spacing: 4) {
        Image(systemName: match.sport.ballIcon)
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)

        if match.sport.gameServiceRotation == .lastWinner {
          let streak = game.serveStreakFor(team)
          if streak > 0 {
            Text("\(streak)")
              .font(.system(size: 18, weight: .semibold, design: .rounded))
              .frame(height: 18)
          }
        }
      }
    } else {
      Spacer().frame(height: 32)
    }
  }
}

// MARK: - Score Summary Table

struct ScoreKeepMatchSummaryScoreTableView: View {
  var match: ScoreKeepMatch

  var body: some View {
    VStack(spacing: 2) {
      ScoreKeepMatchSummaryScoreTableRowView(match: match, team: .us)
      ScoreKeepMatchSummaryScoreTableRowView(match: match, team: .them)
    }
    .monospacedDigit()
  }
}

struct ScoreKeepMatchSummaryScoreTableRowView: View {
  @Bindable var match: ScoreKeepMatch
  var team: ScoreKeepTeam

  @State private var latestGame: ScoreKeepGame?

  private var latestSet: ScoreKeepSet? {
    latestGame?.set
  }

  private let cornerRadiusOutside: CGFloat = 12
  private let innerPadding: CGFloat = 8
  private let outerPadding: CGFloat = 12
  private let verticalPadding: CGFloat = 8
  private let backgroundOpacity = 0.2

  private func fontWeight(winner: Bool = false) -> Font.Weight {
    return winner ? .bold : .regular
  }

  var body: some View {
    let color = team == .us ? Color.blue : Color.red
    let label = team == .us ? "Us" : "Them"
    let hasWinner = match.hasWinner

    HStack(spacing: 0) {
      let fontWeight = fontWeight(winner: match.winner == team)

      Text(label)
        .fontWeight(fontWeight)
        .foregroundColor(color)
        .padding(.vertical, verticalPadding)
        .padding(.leading, outerPadding)
        .padding(.trailing, innerPadding)

      Spacer()

      // Show sets if multi-set match
      if match.isMultiSet {
        ForEach(match.sets) { set in
          let score = set.gamesFor(team)

          Text("\(score)")
            .fontWeight(fontWeight)
            .foregroundColor(color)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, innerPadding)
        }
      }

      // Show current game score
      if !hasWinner {
        if let game = latestGame {
          let score = match.sport.normalizedScoreFor(team, game: game)

          Text("\(score < 10 && match.sport != .tennis ? "0" : "")\(score)")
            .fontWeight(fontWeight)
            .foregroundColor(color)
            .padding(.vertical, verticalPadding)
            .padding(.leading, innerPadding)
            .padding(.trailing, outerPadding)
        }
      }
    }
    .background {
      RoundedRectangle(cornerRadius: cornerRadiusOutside)
        .fill(color.opacity(backgroundOpacity))
        .strokeBorder(color.opacity(match.winner == team ? 1 : 0), lineWidth: 2)
    }
    .foregroundColor(color)
    .onAppear {
      self.latestGame = match.latestGame
    }
    .onChange(of: match.latestGame) {
      self.latestGame = match.latestGame
    }
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
            match.undo()
            dismiss()
          } label: {
            Label("Undo last score", systemImage: "arrow.uturn.backward")
          }
          .disabled(!match.canUndo)
        }
      }
      .navigationTitle("Actions")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Preview

#Preview {
  ActiveMatchView()
    .environment(
      ScoreKeepMatch(
        .volleyball,
        environment: .indoor,
        sets: [
          ScoreKeepSet(
            games: [
              ScoreKeepGame(us: 12, them: 8),
            ]
          ),
        ]
      )
    )
}
