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
    
    private let shortVolleyball = MatchTemplate(
        .volleyball,
        name: "Short volleyball",
        environment: .indoor,
        scoring: MatchScoringRules(
            setsWinAt: 1,
            setScoring: MatchSetScoringRules(
                gamesWinAt: 2,
                gameScoring: MatchGameScoringRules(
                    winScore: 10
                )
            )
        )
    )
    
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
        @Bindable var gameNavigation = gameNavigation
        
        NavigationStack(path: $gameNavigation.path) {
            List {
                StartGameNavigationLinkView(template: shortVolleyball)

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
            // Had to lift this up from `StartGameNavigationLinkView`, because the list
            // creates views lazily
            .navigationDestination(for: MatchTemplate.self) { template in
                // Interesting that I have to pass down context; without this, the context
                // is missing and throws an error within this view.
                GameView(template: template)
                    .environment(gameNavigation)
            }
            .navigationDestination(for: MatchHistoryNavigationDestination.self) { _ in
                GameHistoryView()
            }
            .navigationDestination(for: MatchCreateTemplateNavigationDestination.self) { _ in
                GameRulesCreateView()
            }
            .environment(gameNavigation)
        }
    }
}

struct MatchHistoryNavigationDestination: Hashable {
    
}

struct MatchCreateTemplateNavigationDestination: Hashable {
    
}

struct StartGameNavigationLinkView: View {
    var template: MatchTemplate
    
    private var tintColor: Color {
        switch template.sport {
            case .volleyball:
            return template.environment == .indoor ? .blue : .yellow
        }
    }
    
    var body: some View {
        NavigationLink(value: template) {
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
        NavigationLink(value: MatchHistoryNavigationDestination()) {
            Label("Finished games", systemImage: "calendar")
        }
    }
}

struct StartGameRulesCreateLinkView: View {
    var body: some View {
        NavigationLink(value: MatchCreateTemplateNavigationDestination()) {
            Text("New match")
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}


#Preview {
    StartView()
}
