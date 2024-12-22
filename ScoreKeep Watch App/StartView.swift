//
//  ContentView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import HealthKit
import SwiftUI

struct StartView: View {
    private let gameNavigation = GameNavigationManager()
    
    private let indoorVolleyball = MatchTemplate(
        .volleyball,
        name: "Indoor volleyball",
        environment: .indoor,
        scoring: MatchScoringRules(
            setsWinAt: 3,
            setScoring: MatchSetScoringRules(
                gamesWinAt: 6,
                gameScoring: MatchGameScoringRules(
                    winScore: 25
                )
            )
        )
    )
    
    private let beachVolleyball = MatchTemplate(
        .volleyball,
        name: "Beach volleyball",
        environment: .outdoor,
        scoring: MatchScoringRules(
            setsWinAt: 1,
            setScoring: MatchSetScoringRules(
                gamesWinAt: 3,
                gameScoring: MatchGameScoringRules(
                    winScore: 25
                )
            )
        )
    )
    
    var body: some View {
        List {
            StartGameNavigationLinkView(template: indoorVolleyball)
            
            StartGameNavigationLinkView(template: beachVolleyball)
            
            StartGameRulesCreateLinkView()
        }
        .navigationBarTitle("ScoreKeep")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StartGameHistoryLinkView()
            }
        }
        .listStyle(.carousel)
        .environment(gameNavigation)
    }
}

struct StartGameNavigationLinkView: View {
    var template: MatchTemplate
    @Environment(GameNavigationManager.self) private var gameNavigation
    
    private var tintColor: Color {
        switch template.sport {
            case .volleyball:
            return template.environment == .indoor ? .blue : .yellow
        }
    }
    
    var body: some View {
        @Bindable var gameNavigation = gameNavigation
        
        NavigationLink(isActive: $gameNavigation.isActive) {
            GameView(template: template)
                .environment(gameNavigation)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "figure.volleyball")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.headline)
                    Text("Best-of-\(template.scoring.setScoring.gamesMaximum), first to \(template.scoring.setScoring.gameScoring.maximumScore)")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            
        }
        .padding(
            EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
        )
        .tint(tintColor)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 20)
                .fill(tintColor.opacity(0.2))
        )
    }
}

struct StartGameHistoryLinkView: View {
    var body: some View {
        NavigationLink() {
            GameHistoryView()
        } label: {
            Image(systemName: "calendar")
        }
        .accessibilityLabel("Finished games")
    }
}

struct StartGameRulesCreateLinkView: View {
    var body: some View {
        NavigationLink {
            GameRulesCreateView()
        } label: {
            Text("New game")
                .frame(maxWidth: .infinity)
        }
    }
}


#Preview {
    StartView()
}
