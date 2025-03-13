//
//  MatchTotalScoreSummaryView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-05.
//

import SwiftData
import SwiftUI

struct MatchTotalScoreSummaryView: View {
    var us: Int
    var them: Int
    var winner: MatchTeam? = nil

    init(us: Int, them: Int, winner: MatchTeam? = nil) {
        self.us = us
        self.them = them
        self.winner = winner
    }

    init(match: Match) {
        self.us = match.isMultiSet ? match.setsUs : (match.sets.last?.gamesUs ?? 0)
        self.them = match.isMultiSet ? match.setsThem : (match.sets.last?.gamesThem ?? 0)
        self.winner = match.winner
    }

    init(game: MatchGame) {
        self.us = game.scoreUs
        self.them = game.scoreThem
        self.winner = game.winner
    }

    private let cornerRadiusOutside: CGFloat = 8
    private let cornerRadiusInside: CGFloat = 4
    private let innerPadding: CGFloat = 4
    private let outerPadding: CGFloat = 16
    private let backgroundOpacity = 0.25

    var body: some View {
        Grid(verticalSpacing: 0) {
            GridRow {
                Text("\(us)")
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
                Text("\(them)")
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

enum ScoreLayout {
    case selfFirst
    case selfPointsInward
}

struct MatchSummaryScoreTableView: View {
    var match: Match
    var layout: ScoreLayout = .selfFirst

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
    
    func row(for team: MatchTeam) -> some View {
        let latestSet = match.latestSet!
        let latestGame = latestSet.latestGame!
        let color = team == .us ? Color.blue : Color.red
        let label = team == .us ? "Us" : "Them"
        
        return HStack(spacing: 0) {
            let fontWeight = fontWeight(winner: match.winner == team)
            
            Text(label)
                .fontWeight(fontWeight)
                .foregroundColor(color)
                .padding(.vertical, verticalPadding)
                .padding(.leading, outerPadding)
                .padding(.trailing, innerPadding)

            Spacer()
            
            ForEach(latestSet.orderedGames) { game in
                MatchSummaryScoreTableNumberView(game.scoreFor(team), pad: true, verticalPosition: .top, horizontalPosition: game == latestGame ? .trailing : .inner)
                    .fontWeight(boldestFontWeight)
                    .opacity(0)
                    .overlay {
                        MatchSummaryScoreTableNumberView(game.scoreFor(team), verticalPosition: .top, horizontalPosition: game == latestGame ? .trailing : .inner)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                            .fontWeight(fontWeight)
                            .foregroundColor(color)
                    }
                
            }
        }
        .background {
            RoundedRectangle(cornerRadius: cornerRadiusOutside)
                .fill(color.opacity(backgroundOpacity))
                .stroke(color.opacity(match.winner == team ? 1 : 0), lineWidth: 2)
        }
        .foregroundColor(color)
    }
    
    var body: some View {
        let latestSet = match.latestSet!
        let latestGame = latestSet.latestGame!
        
        VStack(spacing: 2) {
            switch layout {
            case .selfFirst:
                row(for: .us)
                row(for: .them)
            case .selfPointsInward:
                row(for: .them)
                row(for: .us)
            }
        }
        .monospacedDigit()
    }
}

enum MatchSummaryScoreTableCellVerticalPosition {
    case top, bottom
}

enum MatchSummaryScoreTableCellHorizontalPosition {
    case leading, inner, trailing
}

struct MatchSummaryScoreTableNumberView: View {
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
    
    init(_ number: Int, pad: Bool = false, verticalPosition: MatchSummaryScoreTableCellVerticalPosition, horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition) {
        self.number = number
        self.pad = pad
        self.verticalPosition = verticalPosition
        self.horizontalPosition = horizontalPosition
    }
    
    var body: some View {
        Text("\(pad && number < 10 ? "0" : "")\(number)")
            .padding(EdgeInsets(top: verticalPadding, leading: leadingPadding, bottom: verticalPadding, trailing: trailingPadding))
    }
}

struct MatchSummaryScoreTableBackgroundView: View {
    let color: Color
    let winner: Bool
    let horizontalPosition: MatchSummaryScoreTableCellHorizontalPosition
    let verticalPosition: MatchSummaryScoreTableCellVerticalPosition
    
    private let cornerRadiusOutside: CGFloat = 12
    private let cornerRadiusInside: CGFloat = 8
    private let backgroundOpacity = 0.25
    
    private var cornerRadii: RectangleCornerRadii {
        switch (horizontalPosition) {
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
                bottomLeading: verticalPosition == .bottom ? cornerRadiusOutside : cornerRadiusInside,
                bottomTrailing: 0,
                topTrailing: 0
            )
        case .trailing:
            return RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: 0,
                bottomTrailing: verticalPosition == .bottom ? cornerRadiusOutside : cornerRadiusInside,
                topTrailing: verticalPosition == .top ? cornerRadiusOutside : cornerRadiusInside
            )
        }
    }
    
    private var leadingPadding: CGFloat {
        switch (horizontalPosition) {
        case .leading:
            return 1
        default:
            return -2
        }
    }
    
    private var trailingPadding: CGFloat {
        switch (horizontalPosition) {
        case .trailing:
            return 1
        default:
            return -2
        }
    }
    
    var body: some View {
        if winner {
            UnevenRoundedRectangle(cornerRadii: cornerRadii)
                .fill(color.opacity(backgroundOpacity))
                .strokeBorder(color, style: StrokeStyle(lineWidth: 2))
                .padding(
                    EdgeInsets(top: 1, leading: leadingPadding, bottom: 1, trailing: trailingPadding)
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
                        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: horizontalPosition == .trailing ? 0 : -2)
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
        match: Match(
            .volleyball,
            scoring: MatchScoringRules(
                setsWinAt: 1,
                setScoring: MatchSetScoringRules(
                    gamesWinAt: 2,
                    gameScoring: MatchGameScoringRules(
                        winScore: 10
                    )
                )
            ),
            sets: [
                MatchSet(
                    games: [
                        MatchGame(us: 10, them: 5, endedAt: .now.advanced(by: -1000)),
                        MatchGame(us: 10, them: 2, endedAt: .now),
                    ],
                    endedAt: .now
                )
            ],
            startedAt: .now.advanced(by: -2000),
            endedAt: .now
        )
//        match: Match(
//            .volleyball,
//            scoring: MatchScoringRules(
//                setsWinAt: 1,
//                setScoring: MatchSetScoringRules(
//                    gamesWinAt: 2,
//                    gameScoring: MatchGameScoringRules(
//                        winScore: 10
//                    )
//                )
//            ),
//            sets: [
//                MatchSet(
//                    games: [
//                        MatchGame(us: 10, them: 2, endedAt: .now.advanced(by: -1000)),
//                        MatchGame(us: 10, them: 2, endedAt: .now),
//                    ],
//                    endedAt: .now
//                )
//            ],
//            startedAt: .now.advanced(by: -2000)
//        )
    )
    .safeAreaPadding(.all, 10)
}
