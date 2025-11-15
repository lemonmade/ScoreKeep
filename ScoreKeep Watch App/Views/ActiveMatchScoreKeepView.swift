//
//  GameScoreKeepView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI
import ScoreKeepCore

struct ActiveMatchScoreKeepView: View {
    @Environment(Match.self) private var match

    var body: some View {
        if match.latestGame != nil {
            ActiveMatchScoreKeepGameView(match: match)
        } else {
            // TODO
            EmptyView()
        }
    }
}

struct ActiveMatchScoreKeepGameView: View {
    var match: Match

    private let spacing: CGFloat = 8
    private let outerPadding = EdgeInsets(
        top: 40, leading: 12, bottom: 21, trailing: 12)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: spacing) {
                GameScoreTeamButtonView(
                    team: .them, match: match,
                    size: geometryToButtonSize(geometry)
                )

                GameScoreTeamButtonView(
                    team: .us, match: match,
                    size: geometryToButtonSize(geometry)
                )
            }
            .padding(outerPadding)
        }
        .edgesIgnoringSafeArea(.all)

    }
    
    private func geometryToButtonSize(_ geometry: GeometryProxy) -> CGSize {
        let size = CGSize(
            width: geometry.size.width
                - (outerPadding.leading + outerPadding.trailing),
            height: (geometry.size.height - spacing
                - (outerPadding.top + outerPadding.bottom)) / 2
        )

        return size
    }

    private func paddingFromGeometry(geometry: GeometryProxy) -> EdgeInsets {
        print(geometry.safeAreaInsets)
        return geometry.safeAreaInsets
    }
}

struct GameScoreTeamButtonView: View {
    var team: MatchTeam
    var match: Match
    var size: CGSize
    
    var keyColor: Color {
        team == .us ? .blue : .red
    }
    
    var game: MatchGame {
        match.latestGame!
    }

    var body: some View {
        
        Button(action: {
            match.scorePoint(team)
        }) {
            GameScoreTeamScoreView(match: match, team: team, game: game, size: size)
                .foregroundStyle(keyColor)
        }
        .frame(width: size.width, height: size.height)
        .buttonStyle(CustomButtonStyle(keyColor: keyColor))
        .disabled(game.hasEnded)
        .sensoryFeedback(.impact(weight: .medium), trigger: game.scoreFor(team)) { old, new in
            return old != new
            
        }
        .onChange(of: game.number) {
            print("GameScoreTeamButtonView, number: \(game.number), hasEnded: \(game.hasEnded), match: \(game.set?.match?.scoreSummaryString ?? "<no match>")")
        }
    }
}

struct CustomButtonStyle: ButtonStyle {
    var keyColor: Color

    func makeBody(configuration: Configuration) -> some View {
        CustomButtonStyleView(configuration: configuration, keyColor: keyColor)
    }
    
    struct CustomButtonStyleView: View {
        let configuration: ButtonStyle.Configuration
        let keyColor: Color

        @Environment(\.isEnabled) private var isEnabled: Bool
        
        var body: some View {
            configuration.label
                .background(keyColor.opacity(0.2)) // Background with color opacity
                .cornerRadius(20) // Rounded corners
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: -2)
                        .strokeBorder(.red.opacity(0.0), lineWidth: 2) // Border with transparency
                )
                .opacity(isEnabled ? 1 : 0.6)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Subtle press effect
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

struct GameScoreTeamScoreView: View {
    var match: Match
    var team: MatchTeam
    var game: MatchGame
    var size: CGSize
    
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
                        .frame(width: 24, height: 24)
                } else {
                    GameScoreTeamServeIndicatorView(team: team, match: match, game: game)
                }
                
                Text(team == .us ? "Us" : "Them")
                    .textCase(.uppercase)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding([.leading, .trailing], 4)
                    .background(keyColor)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                if score < 10 && match.sport != .tennis {
                    Text("0")
                        .font(.system(size: 70, weight: .bold))
                        .opacity(0.5)
                }
                Text(normalizedScoreLabel)
                    .font(.system(size: 70, weight: .bold))
                    .contentTransition(.numericText(value: Double(normalizedScore)))
            }
            .fontDesign(.rounded)
        }
        .padding(8)
        .monospacedDigit()
        // Allows the whole button to be pressable
        .contentShape(.rect)
        // Fill the container
        .frame(width: size.width, height: size.height, alignment: .trailing)
    }
}

struct GameScoreTeamServeIndicatorView: View {
    var team: MatchTeam
    var match: Match
    var game: MatchGame
    
    var body: some View {
        if team == game.servingTeam {
            HStack(alignment: .bottom, spacing: 2) {
                Image(systemName: match.sport.ballIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                // If we aren’t rotating on every point, “service streaks” are a little odd.
                // I should probably just make this an explicit option
                // instead, though.
                if match.sport.gameServiceRotation == .lastWinner {
                    let streak = game.serveStreakFor(team)
                    if streak > 0 {
                        Text("\(streak)")
                            .font(.system(size: 14,  weight: .semibold, design: .rounded))
                            .frame(height: 14)
                    }
                }
            }
        } else {
            Spacer().frame(height: 24)
        }
    }
}

#Preview {
    ActiveMatchScoreKeepView()
        .environment(
            Match(
                .volleyball,
                scoring: MatchScoringRules(
                    winAt: 5,
                    setScoring: MatchSetScoringRules(
                        winAt: 5,
                        gameScoring: MatchGameScoringRules(
                            winAt: 25
                        )
                    )
                )
            )
        )
}
