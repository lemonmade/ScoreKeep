//
//  MatchScoreboardView.swift
//  ScoreKeepUI
//
//  Shared scoreboard layout: large per-team headline scores, win/serve
//  indicators, participant pills, and an optional per-set/per-game score
//  table beneath. Used by the watch's active-match controls and history
//  detail, and the iOS history detail page.
//

import ScoreKeepCore
import SwiftUI

/// What the headline numbers and the per-team status icon should reflect.
/// - `currentGame`: the active match's latest game — points label, winner
///   check during the dead time between games, ball during live play.
/// - `matchOutcome`: history mode. Treat the match as over and pick the
///   "headline" score that the match was decided at (sets / games / points)
///   plus only a winner indicator.
public enum MatchScoreboardSummaryStyle {
    case currentGame
    case matchOutcome
}

/// Visual scale. Watch uses `.compact`; iOS uses `.prominent`.
public enum MatchScoreboardSize {
    case compact
    case prominent

    var pillFontSize: CGFloat {
        switch self {
        case .compact: return 9
        case .prominent: return 12
        }
    }

    var pillPaddingH: CGFloat { self == .compact ? 5 : 7 }
    var pillPaddingV: CGFloat { self == .compact ? 2 : 3 }

    var scoreFontSize: CGFloat {
        switch self {
        case .compact: return 34
        case .prominent: return 64
        }
    }

    var statusIconFontSize: CGFloat {
        switch self {
        case .compact: return 12
        case .prominent: return 22
        }
    }

    var headerSpacing: CGFloat { self == .compact ? 4 : 8 }

    var tableCellWidth: CGFloat { self == .compact ? 22 : 30 }
    var tableTrailingPadding: CGFloat { self == .compact ? 8 : 12 }
    var tableNumberFontSize: CGFloat { self == .compact ? 14 : 18 }
    var tableLabelFontSize: CGFloat { self == .compact ? 13 : 16 }
    var tableHeaderFontSize: CGFloat { self == .compact ? 9 : 11 }
    var tableTiebreakFontSize: CGFloat { self == .compact ? 8 : 11 }
    var tableLabelLeadingPadding: CGFloat { self == .compact ? 8 : 12 }
    var tableLabelVerticalPadding: CGFloat { self == .compact ? 4 : 8 }
    var tableLabelDotSize: CGFloat { self == .compact ? 7 : 9 }
    var tableCornerRadius: CGFloat { self == .compact ? 10 : 12 }
}

// MARK: - Header

public struct MatchScoreboardHeaderView: View {
    public var match: ScoreKeepMatch
    public var summaryStyle: MatchScoreboardSummaryStyle
    public var size: MatchScoreboardSize

    public init(
        match: ScoreKeepMatch,
        summaryStyle: MatchScoreboardSummaryStyle = .currentGame,
        size: MatchScoreboardSize = .prominent
    ) {
        self.match = match
        self.summaryStyle = summaryStyle
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: size.headerSpacing) {
                teamPill(.us)
                scoreText(.us)
                teamStatusIcon(.us)
            }

            Spacer(minLength: size.headerSpacing)

            HStack(spacing: size.headerSpacing) {
                teamStatusIcon(.them)
                scoreText(.them)
                teamPill(.them)
            }
        }
    }

    @ViewBuilder
    private func teamPill(_ team: ScoreKeepTeam) -> some View {
        let participant = match.participant(for: team)
        let color = participant.resolvedColor.color

        Text(participant.resolvedShortLabel)
            .font(.system(size: size.pillFontSize, weight: .heavy))
            .textCase(.uppercase)
            .foregroundStyle(.black)
            .lineLimit(1)
            .padding(.horizontal, size.pillPaddingH)
            .padding(.vertical, size.pillPaddingV)
            .background(color, in: Capsule())
            .fixedSize()
    }

    @ViewBuilder
    private func teamStatusIcon(_ team: ScoreKeepTeam) -> some View {
        let color = match.participant(for: team).resolvedColor.color

        switch summaryStyle {
        case .currentGame:
            let game = match.latestGame
            if let game, game.winner == team {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size.statusIconFontSize, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale.combined(with: .opacity))
            } else if let game, !game.hasEnded, game.servingTeam == team {
                Image(systemName: match.sport.ballIcon)
                    .font(.system(size: size.statusIconFontSize, weight: .bold))
                    .foregroundStyle(color)
                    .transition(.scale.combined(with: .opacity))
            }
        case .matchOutcome:
            if match.winner == team {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size.statusIconFontSize, weight: .bold))
                    .foregroundStyle(color)
            }
        }
    }

    private func headlineScore(
        for team: ScoreKeepTeam
    ) -> (label: String, transitionValue: Double) {
        switch summaryStyle {
        case .currentGame:
            let game = match.latestGame
            let normalizedScore = game.map { match.sport.normalizedScoreFor(team, game: $0) } ?? 0
            let label = game.map { match.sport.normalizedScoreLabelFor(team, game: $0) } ?? "0"
            let transition = label == "Ad" ? Double(normalizedScore) + 5 : Double(normalizedScore)
            return (label, transition)
        case .matchOutcome:
            if match.isMultiSet {
                let count = match.setsFor(team)
                return (String(count), Double(count))
            }
            if let latestSet = match.latestSet, latestSet.isMultiGame {
                let count = latestSet.gamesFor(team)
                return (String(count), Double(count))
            }
            if let latestGame = match.latestGame {
                let normalizedScore = match.sport.normalizedScoreFor(team, game: latestGame)
                let label = match.sport.normalizedScoreLabelFor(team, game: latestGame)
                let transition = label == "Ad" ? Double(normalizedScore) + 5 : Double(normalizedScore)
                return (label, transition)
            }
            return ("0", 0)
        }
    }

    @ViewBuilder
    private func scoreText(_ team: ScoreKeepTeam) -> some View {
        let (label, transitionValue) = headlineScore(for: team)
        let color = match.participant(for: team).resolvedColor.color

        Text(label)
            .font(.system(size: size.scoreFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: transitionValue))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Score table

public struct MatchScoreboardTableView: View {
    public var match: ScoreKeepMatch
    public var size: MatchScoreboardSize

    public init(
        match: ScoreKeepMatch,
        size: MatchScoreboardSize = .prominent
    ) {
        self.match = match
        self.size = size
    }

    /// In a single-set match with a small number of possible games (e.g. squash
    /// best-of-3 or best-of-5), show each game's score as its own column instead
    /// of a single "games won" summary. Tennis sets, volleyball "first to N"
    /// single-game sets, and other long-format matches keep the summary cell.
    private var perGameSingleSetMax: Int { 5 }

    private enum TableMode {
        case multiSetPerSet
        case singleSetPerGame
        case singleSetSummary
    }

    private var mode: TableMode {
        if match.isMultiSet { return .multiSetPerSet }
        if let max = match.rules.setRules.maximumGameCount,
           max >= 2, max <= perGameSingleSetMax {
            return .singleSetPerGame
        }
        return .singleSetSummary
    }

    private var columns: [TableColumn] {
        switch mode {
        case .multiSetPerSet:
            return match.sets.map { set in
                let isCurrent = set.isLatestInMatch && !set.hasEnded
                return TableColumn(
                    id: set.number,
                    isCurrent: isCurrent,
                    us: set.gamesUs,
                    them: set.gamesThem,
                    tiebreakUs: isCurrent ? nil : set.tiebreakGame?.scoreUs,
                    tiebreakThem: isCurrent ? nil : set.tiebreakGame?.scoreThem
                )
            }
        case .singleSetPerGame:
            let games = match.latestSet?.games.filter { $0.hasEnded } ?? []
            return games.map { game in
                TableColumn(
                    id: game.number,
                    isCurrent: false,
                    us: game.scoreUs,
                    them: game.scoreThem,
                    tiebreakUs: nil,
                    tiebreakThem: nil
                )
            }
        case .singleSetSummary:
            return []
        }
    }

    public var body: some View {
        let columns = self.columns

        VStack(spacing: 2) {
            if !columns.isEmpty {
                headerRow(columns: columns)
            }

            VStack(spacing: 0) {
                row(team: .us, columns: columns)
                rowDivider
                row(team: .them, columns: columns)
            }
            .background(
                RoundedRectangle(cornerRadius: size.tableCornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.tableCornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    private func headerRow(columns: [TableColumn]) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    Text("\(column.id)")
                        .font(.system(size: size.tableHeaderFontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(width: size.tableCellWidth)
                }
            }
            .padding(.trailing, size.tableTrailingPadding)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(height: 0.5)
    }

    @ViewBuilder
    private func row(team: ScoreKeepTeam, columns: [TableColumn]) -> some View {
        let isUs = team == .us
        let participant = match.participant(for: team)

        HStack(spacing: 0) {
            teamLabel(participant: participant)
                .frame(maxWidth: .infinity, alignment: .leading)

            scoresArea(team: team, isUs: isUs, columns: columns)
                .padding(.trailing, size.tableTrailingPadding)
        }
    }

    @ViewBuilder
    private func scoresArea(
        team: ScoreKeepTeam,
        isUs: Bool,
        columns: [TableColumn]
    ) -> some View {
        if columns.isEmpty {
            let games = match.latestSet?.gamesFor(team) ?? 0
            cell(value: games, tiebreak: nil, isCurrent: false)
        } else {
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    cell(
                        value: isUs ? column.us : column.them,
                        tiebreak: isUs ? column.tiebreakUs : column.tiebreakThem,
                        isCurrent: column.isCurrent
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func teamLabel(participant: ScoreKeepMatchParticipant) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(participant.resolvedColor.color)
                .frame(width: size.tableLabelDotSize, height: size.tableLabelDotSize)
            Text(participant.resolvedName)
                .font(.system(size: size.tableLabelFontSize, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, size.tableLabelLeadingPadding)
        .padding(.vertical, size.tableLabelVerticalPadding)
    }

    @ViewBuilder
    private func cell(value: Int, tiebreak: Int?, isCurrent: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.system(size: size.tableNumberFontSize, weight: isCurrent ? .semibold : .regular, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
            if let tiebreak {
                Text("\(tiebreak)")
                    .font(.system(size: size.tableTiebreakFontSize, weight: .regular, design: .rounded))
                    .baselineOffset(4)
                    .monospacedDigit()
            }
        }
        .frame(width: size.tableCellWidth)
    }
}

private struct TableColumn: Identifiable {
    let id: Int
    let isCurrent: Bool
    let us: Int
    let them: Int
    let tiebreakUs: Int?
    let tiebreakThem: Int?
}
