//
//  GameScoreKeepView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct ActiveMatchScoreKeepView: View {
    @Environment(Match.self) private var match

    var body: some View {
        if let game = match.latestGame {
            ActiveMatchScoreKeepGameView(match: match, game: game)
        } else {
            // TODO
            EmptyView()
        }
    }
}

struct ActiveMatchScoreKeepGameView: View {
    var match: Match
    var game: MatchGame

    private let spacing: CGFloat = 8
    private let outerPadding = EdgeInsets(
        top: 40, leading: 12, bottom: 21, trailing: 12)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: spacing) {
                GameScoreTeamButtonView(
                    team: .them, match: match, game: game,
                    size: geometryToButtonSize(geometry)
                )

                GameScoreTeamButtonView(
                    team: .us, match: match, game: game,
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
    var game: MatchGame
    var size: CGSize
    
    var keyColor: Color {
        team == .us ? .blue : .red
    }

    var body: some View {
        Button(action: {
            match.score(team)
        }) {
            GameScoreTeamScoreView(team: team, game: game, size: size)
                .foregroundStyle(keyColor)
        }
        .frame(width: size.width, height: size.height)
        .buttonStyle(CustomButtonStyle(keyColor: keyColor))
        .disabled(game.hasEnded)
        .sensoryFeedback(.impact(weight: .medium), trigger: game.scoreFor(team)) { old, new in
            return old != new
            
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
    var team: MatchTeam
    var game: MatchGame
    var size: CGSize
    
    var score: Int {
        game.scoreFor(team)
    }
    
    var keyColor: Color {
        team == .us ? .blue : .red
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(team == .us ? "Us" : "Them")
                .textCase(.uppercase)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding([.leading, .trailing], 4)
                .background(keyColor)
                .cornerRadius(8)
                .offset(y: -10)
            
            Spacer()
            
            HStack(spacing: 0) {
                if score < 10 {
                    Text("0")
                        .font(.system(size: 70, weight: .bold))
                        .opacity(0.5)
                }
                Text("\(score)")
                    .font(.system(size: 70, weight: .bold))
                    .contentTransition(.numericText(value: Double(score)))
            }
        }
        .padding(8)
        .monospacedDigit()
        // Allows the whole button to be pressable
        .contentShape(.rect)
        // Fill the container
        .frame(width: size.width, height: size.height, alignment: .trailing)
    }
}

#Preview {
    ActiveMatchScoreKeepView()
        .environment(
            Match(
                .volleyball,
                scoring: MatchScoringRules(
                    setsWinAt: 5,
                    setScoring: MatchSetScoringRules(
                        gamesWinAt: 5,
                        gameScoring: MatchGameScoringRules(
                            winScore: 25
                        )
                    )
                )
            )
        )
}
