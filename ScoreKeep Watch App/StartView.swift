//
//  ContentView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import HealthKit
import SwiftUI
import SwiftData

struct StartView: View {
    private let navigation = NavigationManager()

    @Query(sort: \MatchTemplate.lastUsedAt, order: .reverse) private var templates: [MatchTemplate]
    
    private let indoorVolleyball = MatchTemplate(
        .volleyball,
        name: "Indoor volleyball",
        color: .blue,
        environment: .indoor,
        scoring: MatchScoringRules(
            setsWinAt: 3,
            playItOut: false,
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
        color: .green,
        environment: .outdoor,
        scoring: MatchScoringRules(
            setsWinAt: 1,
            playItOut: true,
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
                ForEach(templates) { template in
                    StartMatchNavigationLinkView(template: template)
                }
                
                if templates.isEmpty {
                    StartMatchNavigationLinkView(template: indoorVolleyball)

                    StartMatchNavigationLinkView(template: beachVolleyball)
                }
                
                CreateMatchTemplateNavigationLinkView()
            }
            .navigationBarTitle("ScoreKeep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    MatchHistoryNavigationLinkView()
                }
            }
            .listStyle(.carousel)
            // Had to lift this up from `StartGameNavigationLinkView`, because the list
            // creates views lazily
            .navigationDestination(for: NavigationLocation.ActiveMatch.self) { matchLocation in
                ActiveMatchView(template: matchLocation.template)
                    .environment(navigation)
            }
            .navigationDestination(for: NavigationLocation.MatchHistory.self) { _ in
                MatchHistoryListView()
                    .environment(navigation)
            }
            .navigationDestination(for: NavigationLocation.TemplateCreate.self) { _ in
                CreateMatchTemplateView()
                    .environment(navigation)
            }
            .environment(navigation)
        }
    }
}

struct StartMatchNavigationLinkView: View {
    var template: MatchTemplate
    var markAsUsed: Bool = true
    
    private var detailText: String {
        var ofText: String = ""
        
        if template.scoring.isMultiSet {
            ofText = template.scoring.playItOut ? "Best-of-\(template.scoring.setsMaximum)" : "First to \(template.scoring.setsWinAt)"
        } else {
            ofText = template.scoring.setScoring.playItOut ? "Best-of-\(template.scoring.setScoring.gamesMaximum)" : "First to \(template.scoring.setScoring.gamesWinAt)"
        }
        
        let gameText = "games to \(template.scoring.setScoring.gameScoring.winScore)"
        
        return "\(ofText), \(gameText)"
    }
    
    var body: some View {
        NavigationLink(value: NavigationLocation.ActiveMatch(template: template)) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "figure.volleyball")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.headline)
                    Text(detailText)
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
            }
            
        }
        .padding(
            EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        )
        .tint(template.color.color)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 20)
                .fill(template.color.color.opacity(0.2))
        )
    }
}

struct MatchHistoryNavigationLinkView: View {
    var body: some View {
        NavigationLink(value: NavigationLocation.MatchHistory()) {
            Label("Finished games", systemImage: "calendar")
        }
    }
}

struct CreateMatchTemplateNavigationLinkView: View {
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
