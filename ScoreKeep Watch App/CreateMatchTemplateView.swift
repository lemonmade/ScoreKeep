//
//  CreateMatchTemplateView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI

struct CreateMatchTemplateView: View {
    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var navigation

    @Bindable var template = MatchTemplate(
        .volleyball,
        name: "Volleyball",
        environment: .indoor,
        scoring: MatchScoringRules(
            setsWinAt: 1,
            setScoring: MatchSetScoringRules(
                gamesWinAt: 6,
                gameScoring: MatchGameScoringRules(
                    winScore: 25
                )
            )
        )
    )
    
    private var scoring: MatchScoringRules {
        template.scoring
    }
    
    private var setScoring: MatchSetScoringRules {
        scoring.setScoring
    }
    
    
    private var gameScoring: MatchGameScoringRules {
        setScoring.gameScoring
    }
    
    @State private var gameScoringWinScore = 25 {
        didSet {
            template.scoring = MatchScoringRules(
                setsWinAt: scoring.setsWinAt,setsMaximum: scoring.setsMaximum,
                setScoring: MatchSetScoringRules(
                    gamesWinAt: setScoring.gamesWinAt,
                    gamesMaximum: setScoring.gamesMaximum,
                    playItOut: setScoring.playItOut,
                    gameScoring: MatchGameScoringRules(
                        winScore: gameScoringWinScore,
                        maximumScore: gameScoring.maximumScore,
                        winBy: gameScoring.winBy
                    ),
                    gameTimebreakerScoring: setScoring.gameTimebreakerScoring
                ),
                setTiebreakerScoring: scoring.setTimebreakerScoring
            )
        }
    }
    
    @State private var gameScoringMaximumScore = 27 {
        didSet {
            template.scoring = MatchScoringRules(
                setsWinAt: scoring.setsWinAt,setsMaximum: scoring.setsMaximum,
                setScoring: MatchSetScoringRules(
                    gamesWinAt: setScoring.gamesWinAt,
                    gamesMaximum: setScoring.gamesMaximum,
                    playItOut: setScoring.playItOut,
                    gameScoring: MatchGameScoringRules(
                        winScore: gameScoring.winScore,
                        maximumScore: gameScoringMaximumScore,
                        winBy: gameScoring.winBy
                    ),
                    gameTimebreakerScoring: setScoring.gameTimebreakerScoring
                ),
                setTiebreakerScoring: scoring.setTimebreakerScoring
            )
            
            if gameScoringWinScore < gameScoringMaximumScore {
                self.gameScoringWinScore = gameScoringMaximumScore
            }
        }
    }
    
    @State private var gameScoringWinBy = 1 {
        didSet {
            template.scoring = MatchScoringRules(
                setsWinAt: scoring.setsWinAt,setsMaximum: scoring.setsMaximum,
                setScoring: MatchSetScoringRules(
                    gamesWinAt: setScoring.gamesWinAt,
                    gamesMaximum: setScoring.gamesMaximum,
                    playItOut: setScoring.playItOut,
                    gameScoring: MatchGameScoringRules(
                        winScore: gameScoring.winScore,
                        maximumScore: gameScoring.maximumScore,
                        winBy: gameScoringWinBy
                    ),
                    gameTimebreakerScoring: setScoring.gameTimebreakerScoring
                ),
                setTiebreakerScoring: scoring.setTimebreakerScoring
            )
        }
    }
    
    @State private var matchColor: MatchColor = .green
    
    enum MatchColor: String {
        case red, blue, green, yellow
        
        var color: Color {
            switch self {
            case .red: return Color.red
            case .blue: return Color.blue
            case .green: return Color.green
            case .yellow: return Color.yellow
            }
        }
        
        static var allCases: [MatchColor] { [.red, .blue, .green, .yellow] }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField("Name", text: $template.name)
                
//                Picker("Color", selection: $matchColor) {
//                    Text("").frame(maxWidth: .infinity, minHeight: 30).background(MatchColor.red.color).tag(MatchColor.red)
//                    Text("").frame(width: 30, height: 30).background(MatchColor.blue.color).tag(MatchColor.blue)
//                    Text("").frame(width: 30, height: 30).background(MatchColor.green.color).tag(MatchColor.green)
//                }
//                .pickerStyle(.navigationLink)
                
                Picker("Environment", selection: $template.environment) {
                    Text("Indoor").tag(MatchEnvironment.indoor)
                    Text("Outdoor").tag(MatchEnvironment.outdoor)
                }
                .pickerStyle(.navigationLink)
                
                VStack {
                    Text("Win at")
                    
                    Stepper(value: $gameScoringWinScore, in: 1...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinScore)").fontWeight(.bold)
                            Text(" points")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                }
                
                VStack {
                    Text("Maximum score")

                    Stepper(value: $gameScoringMaximumScore, in: gameScoringWinScore...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringMaximumScore)").fontWeight(.bold)
                            Text(" points")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                }
                
                VStack {
                    Text("Win by")

                    Stepper(value: $gameScoringWinBy, in: 1...10, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinBy)").fontWeight(.bold)
                            Text(" points")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                }
                
                Button {
                    context.insert(template)
                    // TODO
                    try? context.save()
                    navigation.pop()
                } label: {
                    Text("Create")
                }
                .tint(.green)
            }
        }
        .navigationTitle("New Game")
    }
}

#Preview {
    CreateMatchTemplateView()
        .environment(NavigationManager())
}
