//
//  ContentView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import HealthKit
import SwiftUI

struct StartView: View {
    private let navigation = NavigationManager()
    
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
        @Bindable var navigation = navigation
        
        NavigationStack(path: $navigation.path) {
            List {
                StartGameNavigationLinkView(template: shortVolleyball)

//                StartGameNavigationLinkView(template: indoorVolleyball)
//
//                StartGameNavigationLinkView(template: beachVolleyball)
                
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
            .navigationDestination(for: NavigationLocation.ActiveMatch.self) { matchLocation in
                MatchView(match: matchLocation.match)
                    .environment(navigation)
            }
            .navigationDestination(for: NavigationLocation.MatchHistory.self) { _ in
                MatchHistoryView()
            }
            .navigationDestination(for: NavigationLocation.TemplateCreate.self) { _ in
                MatchTemplateCreateView()
            }
            .environment(navigation)
        }
    }
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
        NavigationLink(value: NavigationLocation.ActiveMatch(match: template.createMatch())) {
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
        NavigationLink(value: NavigationLocation.MatchHistory()) {
            Label("Finished games", systemImage: "calendar")
        }
    }
}

struct StartGameRulesCreateLinkView: View {
    var body: some View {
        NavigationLink(value: NavigationLocation.TemplateCreate()) {
            Text("New match")
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}


#Preview {
    StartView()
}
