//
//  ContentView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import HealthKit
import SwiftData
import SwiftUI

struct StartView: View {
    private let navigation = NavigationManager()

    @Environment(WorkoutManager.self) private var workoutManager
    @Query(sort: \MatchTemplate.lastUsedAt, order: .reverse) private
        var templates: [MatchTemplate]

    private let indoorVolleyball = MatchTemplate(
        .volleyball,
        name: "Indoor volleyball",
        color: .green,
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
        color: .yellow,
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
    
    private let ultimate = MatchTemplate(
        .ultimate,
        name: "Ultimate frisbee",
        color: .purple,
        environment: .outdoor,
        scoring: MatchScoringRules(
            setsWinAt: 1,
            setScoring: MatchSetScoringRules(
                gamesWinAt: 1,
                gameScoring: MatchGameScoringRules(
                    winScore: 15
                )
            )
        )
    )
    
    private let squash = MatchTemplate(
        .squash,
        name: "Squash",
        color: .pink,
        environment: .outdoor,
        scoring: MatchScoringRules(
            setsWinAt: 1,
            setScoring: MatchSetScoringRules(
                gamesWinAt: 3,
                gameScoring: MatchGameScoringRules(
                    winScore: 11
                ),
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
                    
                    StartMatchNavigationLinkView(template: ultimate)
                    
                    StartMatchNavigationLinkView(template: squash)
                }

                CreateMatchTemplateButtonView()
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
            .navigationDestination(for: NavigationLocation.ActiveMatch.self) {
                matchLocation in
                ActiveMatchView(template: matchLocation.template)
                    .environment(navigation)
            }
            .navigationDestination(for: NavigationLocation.MatchHistory.self) {
                _ in
                MatchHistoryListView()
                    .environment(navigation)
            }
            .navigationDestination(for: NavigationLocation.MatchHistoryDetail.self) { destination in
                MatchHistoryDetailView(match: destination.match)
            }
            .navigationDestination(for: NavigationLocation.TemplateCreate.self)
            { createMatchTemplateDestination in
                CreateMatchTemplateView(template: createMatchTemplateDestination.template)
                    .environment(navigation)
            }
            .environment(navigation)
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}

struct StartMatchNavigationLinkView: View {
    var template: MatchTemplate
    var markAsUsed: Bool = true
    
    @Environment(NavigationManager.self) private var navigation

    private var detailText: String {
        var ofText: String = ""
        
        if template.scoring.isMultiSet {
            ofText =
                template.scoring.playItOut
                ? "Best of \(template.scoring.setsMaximum) sets"
                : "First to \(template.scoring.setsWinAt) sets"
        } else {
            if template.scoring.setScoring.isMultiGame {
                ofText = "Best of \(template.scoring.setScoring.gamesMaximum) games"
            }
        }

        return "\(ofText)"
    }

    private var detailSecondaryText: String {
        if template.scoring.setScoring.isMultiGame {
            return "Games to \(template.scoring.setScoring.gameScoring.winScore) points"
        }

        return "First to \(template.scoring.setScoring.gameScoring.winScore) points"
    }
    
    private var systemImage: String {
        switch template.sport {
        case .squash: return "figure.squash"
        case .ultimate: return "figure.disc.sports"
        case .volleyball: return "figure.volleyball"
        }
    }

    var body: some View {
        NavigationLink(
            value: NavigationLocation.ActiveMatch(template: template)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .fontWeight(.bold)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 0) {
                    Text(template.name)
                        .font(.headline)
                    
                    if !detailText.isEmpty {
                        Text(detailText)
                            .font(.caption2)
                            .foregroundStyle(.tint)
                    }

                    Text(detailSecondaryText)
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(
            EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        )
        .tint(template.color.color)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 20)
                .fill(template.color.color.opacity(0.2))
        )
        .overlay(alignment: .topTrailing) {
            Button {
                navigation.navigate(to: NavigationLocation.TemplateCreate(template: template))
            } label: {
                ZStack {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .fontWeight(.bold)
                        .foregroundStyle(template.color.color)
                        .padding(8)
                        .background(
                            Circle()
                                .inset(by: 3)
                                .fill(template.color.color.opacity(0.2))
                        )
                }
                .offset(y: 12)    
            }
            .buttonStyle(.plain)
        }
    }
}

struct MatchHistoryNavigationLinkView: View {
    var body: some View {
        NavigationLink(value: NavigationLocation.MatchHistory()) {
            Label("Finished games", systemImage: "calendar")
        }
    }
}

struct CreateMatchTemplateButtonView: View {
    @Environment(NavigationManager.self) private var navigation
    
    var body: some View {
        Button {
            navigation.navigate(to: NavigationLocation.TemplateCreate())
        } label: {
            Text("New match")
        }
        .buttonStyle(BorderedButtonStyle(tint: .gray))
        .foregroundStyle(.primary)

//        .backgroundStyle(.regularMaterial)
        .listRowBackground(EmptyView())
    }
}

#Preview {
    StartView()
        .environment(WorkoutManager())
}
