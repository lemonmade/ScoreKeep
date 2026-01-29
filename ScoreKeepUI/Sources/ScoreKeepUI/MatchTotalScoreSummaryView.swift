//
//  MatchTotalScoreSummaryView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-05.
//

import ScoreKeepCore
import SwiftData
import SwiftUI

public struct MatchTotalScoreSummaryView: View {
    var us: String
    var them: String
    var winner: ScoreKeepTeam?

    public init(us: Int, them: Int, winner: ScoreKeepTeam? = nil) {
        self.us = String(us)
        self.them = String(them)
        self.winner = winner
    }

    public init(us: String, them: String, winner: ScoreKeepTeam? = nil) {
        self.us = us
        self.them = them
        self.winner = winner
    }

    public init(match: ScoreKeepMatch) {
        if match.isMultiSet {
            self.us = String(match.setsUs)
            self.them = String(match.setsThem)
        } else if let lastSet = match.sets.last {
            if lastSet.isMultiGame {
                self.us = String(lastSet.gamesUs)
                self.them = String(lastSet.gamesThem)
            } else {
                let lastGame = lastSet.games.last
                self.us = String(lastGame?.scoreUs ?? 0)
                self.them = String(lastGame?.scoreThem ?? 0)
            }
        } else {
            self.us = "0"
            self.them = "0"
        }

        self.winner = match.winner
    }

    public init(game: ScoreKeepGame) {
        self.us =
            game.match?.sport.normalizedScoreLabelFor(.us, game: game) ?? String(game.scoreUs)
        self.them =
            game.match?.sport.normalizedScoreLabelFor(.them, game: game)
            ?? String(game.scoreThem)
        self.winner = game.winner
    }

    private let cornerRadiusOutside: CGFloat = 8
    private let cornerRadiusInside: CGFloat = 4
    private let innerPadding: CGFloat = 4
    private let outerPadding: CGFloat = 16
    private let backgroundOpacity = 0.25

    public var body: some View {
        Grid(verticalSpacing: 0) {
            GridRow {
                Text(us)
                    .fontWeight(winner == .us ? .bold : .regular)
                    .foregroundColor(.blue)
                    .padding(
                        EdgeInsets(
                            top: innerPadding,
                            leading: outerPadding,
                            bottom: innerPadding,
                            trailing: outerPadding
                        )
                    )
            }
            .background {
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: cornerRadiusOutside,
                        bottomLeading: winner == .us ? cornerRadiusInside : 0,
                        bottomTrailing: winner == .us ? cornerRadiusInside : 0,
                        topTrailing: cornerRadiusOutside
                    )
                )
                .fill(.blue.opacity(backgroundOpacity))
                .stroke(
                    .blue,
                    style: StrokeStyle(lineWidth: winner == .us ? 2 : 0)
                )
            }

            GridRow {
                Text(them)
                    .fontWeight(winner == .them ? .bold : .regular)
                    .foregroundColor(.red)
                    .padding(
                        EdgeInsets(
                            top: innerPadding,
                            leading: outerPadding,
                            bottom: innerPadding,
                            trailing: outerPadding
                        )
                    )
            }

            .background {
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: winner == .them ? cornerRadiusInside : 0,
                        bottomLeading: cornerRadiusOutside,
                        bottomTrailing: cornerRadiusOutside,
                        topTrailing: winner == .them ? cornerRadiusInside : 0
                    )
                )
                .fill(.red.opacity(backgroundOpacity))
                .stroke(
                    .red,
                    style: StrokeStyle(lineWidth: winner == .them ? 2 : 0)
                )
            }
        }
        .monospacedDigit()
    }
}

public enum ScoreLayout {
    case selfFirst
    case selfPointsInward
}

public struct MatchSummaryScoreTableView: View {
    var match: ScoreKeepMatch
    var layout: ScoreLayout = .selfFirst

    public init(match: ScoreKeepMatch, layout: ScoreLayout = .selfFirst) {
        self.match = match
        self.layout = layout
    }

    public var body: some View {
        VStack(spacing: 2) {
            switch layout {
            case .selfFirst:
                MatchSummaryScoreTableRowView(match: match, team: .us)
                MatchSummaryScoreTableRowView(match: match, team: .them)
            case .selfPointsInward:
                MatchSummaryScoreTableRowView(match: match, team: .them)
                MatchSummaryScoreTableRowView(match: match, team: .us)
            }
        }
        .monospacedDigit()
    }
    //    var body: some View {
    //        Grid(verticalSpacing: 2) {
    //            GridRow {
    //                Text("Us")
    //                Spacer().frame(height: 0)
    //                Text("Them")
    //            }
    //
    //            if let latestGame = match.latestGame {
    //                GridRow {
    //                    Text("\(match.sport.normalizedScoreLabelFor(.us, game: latestGame))")
    //
    //                    Text("Game \(latestGame.number)").frame(width: .infinity)
    //
    //                    Text("\(match.sport.normalizedScoreLabelFor(.them, game: latestGame))")
    //                }
    //            }
    //        }
    //    }
}

public struct MatchSummaryScoreTableRowView: View {
    @Bindable var match: ScoreKeepMatch
    var team: ScoreKeepTeam

    @State private var latestGame: ScoreKeepGame?

    public init(match: ScoreKeepMatch, team: ScoreKeepTeam) {
        self.match = match
        self.team = team
        self.latestGame = match.latestGame
    }

    private var latestSet: ScoreKeepSet? {
        latestGame?.set
    }

    private let cornerRadiusOutside: CGFloat = 12
    private let innerPadding: CGFloat = 8
    private let outerPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 5
    private let backgroundOpacity = 0.25

    private let winnerFontWeight: Font.Weight = .bold
    private let nonWinnerFontWeight: Font.Weight = .regular
    private var boldestFontWeight: Font.Weight { winnerFontWeight }

    private func fontWeight(winner: Bool = false) -> Font.Weight {
        return winner ? winnerFontWeight : nonWinnerFontWeight
    }

    public var body: some View {
        let color = team == .us ? Color.blue : Color.red
        let label = team == .us ? "Us" : "Them"
        let hasWinner = match.hasWinner
        let showLatestGame = !hasWinner && latestGame != nil

        HStack(spacing: 0) {
            let fontWeight = fontWeight(winner: match.winner == team)

            Text(label)
                .fontWeight(fontWeight)
                .foregroundColor(color)
                .padding(.vertical, verticalPadding)
                .padding(.leading, outerPadding)
                .padding(.trailing, innerPadding)

            Spacer()

            if !match.isMultiSet, let set = latestSet,
               let maximumGameCount = set.rules?.maximumGameCount,
                maximumGameCount <= 3
            {
                let filteredGames = hasWinner ? set.games : set.games.filter { $0 != latestGame }

                ForEach(filteredGames) { game in
                    let score = match.sport.normalizedScoreFor(team, game: game)

                    MatchSummaryScoreTableNumberView(
                        score, pad: true, verticalPosition: .top,
                        horizontalPosition: game.isLatestInSet ? .trailing : .inner
                    )
                    .fontWeight(boldestFontWeight)
                    .opacity(0)
                    .overlay {
                        MatchSummaryScoreTableNumberView(
                            score, verticalPosition: .top,
                            horizontalPosition: game.isLatestInSet ? .trailing : .inner
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .fontWeight(fontWeight)
                        .foregroundColor(color)
                    }

                }
            } else {
                ForEach(match.sets) { set in
                    let score = set.gamesFor(team)
                    let horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition =
                        showLatestGame || !set.isLatestInMatch ? .inner : .trailing

                    MatchSummaryScoreTableNumberView(
                        score, verticalPosition: .top, horizontalPosition: horizontalPosition
                    )
                    .fontWeight(boldestFontWeight)
                    .opacity(0)
                    .overlay {
                        MatchSummaryScoreTableNumberView(
                            score, verticalPosition: .top, horizontalPosition: horizontalPosition
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .fontWeight(fontWeight)
                        .foregroundColor(color)
                    }
                }
            }

            if !hasWinner {
                if let game = latestGame {
                    let score = match.sport.normalizedScoreFor(team, game: game)

                    MatchSummaryScoreTableNumberView(
                        score, pad: true, verticalPosition: .top, horizontalPosition: .trailing
                    )
                    .fontWeight(boldestFontWeight)
                    .opacity(0)
                    .overlay {
                        MatchSummaryScoreTableNumberView(
                            score, verticalPosition: .top, horizontalPosition: .trailing
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .fontWeight(fontWeight)
                        .foregroundColor(color)
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: cornerRadiusOutside)
                .fill(color.opacity(backgroundOpacity))
                .stroke(color.opacity(match.winner == team ? 1 : 0), lineWidth: 2)
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

public enum MatchSummaryScoreTableCellVerticalPosition {
    case top, bottom
}

public enum MatchSummaryScoreTableCellHorizontalPosition {
    case leading, inner, trailing
}

public struct MatchSummaryScoreTableNumberView: View {
    private let number: Int
    private let pad: Bool
    private let verticalPosition: MatchSummaryScoreTableCellVerticalPosition
    private let horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition

    private let verticalPadding: CGFloat = 5
    private var leadingPadding: CGFloat {
        switch horizontalPosition {
        case .inner: return 4
        case .leading: return 10
        case .trailing: return 4
        }
    }

    private var trailingPadding: CGFloat {
        switch horizontalPosition {
        case .inner: return 4
        case .leading: return 4
        case .trailing: return 10
        }
    }

    init(
        _ number: Int, pad: Bool = false,
        verticalPosition: MatchSummaryScoreTableCellVerticalPosition,
        horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition
    ) {
        self.number = number
        self.pad = pad
        self.verticalPosition = verticalPosition
        self.horizontalPosition = horizontalPosition
    }

    public var body: some View {
        Text("\(pad && number < 10 ? "0" : "")\(number)")
            .padding(
                EdgeInsets(
                    top: verticalPadding, leading: leadingPadding, bottom: verticalPadding,
                    trailing: trailingPadding))
    }
}

public struct MatchSummaryScoreTableBackgroundView: View {
    let color: Color
    let winner: Bool
    let horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition
    let verticalPosition: MatchSummaryScoreTableCellVerticalPosition

    public init(
        color: Color, winner: Bool,
        horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition,
        verticalPosition: MatchSummaryScoreTableCellVerticalPosition
    ) {
        self.color = color
        self.winner = winner
        self.horizontalPosition = horizontalPosition
        self.verticalPosition = verticalPosition
    }

    private let cornerRadiusOutside: CGFloat = 12
    private let cornerRadiusInside: CGFloat = 8
    private let backgroundOpacity = 0.25

    private var cornerRadii: RectangleCornerRadii {
        switch horizontalPosition {
        case .inner:
            return RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: 0
            )
        case .leading:
            return RectangleCornerRadii(
                topLeading: verticalPosition == .top ? cornerRadiusOutside : cornerRadiusInside,
                bottomLeading: verticalPosition == .bottom
                    ? cornerRadiusOutside : cornerRadiusInside,
                bottomTrailing: 0,
                topTrailing: 0
            )
        case .trailing:
            return RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: 0,
                bottomTrailing: verticalPosition == .bottom
                    ? cornerRadiusOutside : cornerRadiusInside,
                topTrailing: verticalPosition == .top ? cornerRadiusOutside : cornerRadiusInside
            )
        }
    }

    private var leadingPadding: CGFloat {
        switch horizontalPosition {
        case .leading:
            return 1
        default:
            return -2
        }
    }

    private var trailingPadding: CGFloat {
        switch horizontalPosition {
        case .trailing:
            return 1
        default:
            return -2
        }
    }

    public var body: some View {
        if winner {
            UnevenRoundedRectangle(cornerRadii: cornerRadii)
                .fill(color.opacity(backgroundOpacity))
                .strokeBorder(color, style: StrokeStyle(lineWidth: 2))
                .padding(
                    EdgeInsets(
                        top: 1, leading: leadingPadding, bottom: 1, trailing: trailingPadding)
                )
                //                .mask(alignment: .trailing) {
                //                    VStack(spacing: 0) {
                //                        Rectangle().frame(height: 2)
                //                        HStack {
                //                            if horizontalPosition != .leading {
                //                                Spacer().frame(width: 2)
                //                            }
                //                            Rectangle()
                //
                //                            if horizontalPosition != .trailing {
                //                                Spacer().frame(width: 2)
                //                            }
                //                        }
                //                        Rectangle().frame(height: 2)
                //                    }
                //                    .padding(
                //                        EdgeInsets(top: -2, leading: horizontalPosition == .leading ? -1 : -2, bottom: -2, trailing: horizontalPosition == .trailing ? -1 : -2)
                //                    )
                //                }
                .mask(alignment: .trailing) {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: 3)
                        HStack {
                            Rectangle()

                            if horizontalPosition != .trailing {
                                Spacer().frame(width: 2)
                            }
                        }
                        Rectangle().frame(height: 3)
                    }
                    .padding(
                        EdgeInsets(
                            top: 0, leading: 0, bottom: 0,
                            trailing: horizontalPosition == .trailing ? 0 : -2)
                    )
                }
        } else {
            UnevenRoundedRectangle(cornerRadii: cornerRadii)
                .fill(color.opacity(backgroundOpacity))
        }
    }
}

#Preview {
    MatchSummaryScoreTableView(
        match: ScoreKeepMatch(
            .tennis,
            environment: .outdoor,
            sets: [
                ScoreKeepSet(
                    games: [
                        ScoreKeepGame(us: 6, them: 4, endedAt: .now.advanced(by: -1000)),
                        ScoreKeepGame(us: 4, them: 2, endedAt: .now),
                        ScoreKeepGame(us: 1, them: 4, endedAt: .now),
                        ScoreKeepGame(us: 6, them: 4, endedAt: .now),
                    ],
                    endedAt: .now
                ),
            ],
            startedAt: .now.advanced(by: -2000),
            endedAt: .now
        )
    )
    .safeAreaPadding(.all, 10)
}
