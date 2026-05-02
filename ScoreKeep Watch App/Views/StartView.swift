//
//  ContentView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import HealthKit
import ScoreKeepCore
import SwiftData
import SwiftUI

struct StartView: View {
    private let navigation = NavigationManager()

    @Environment(WorkoutManager.self) private var workoutManager
    @Query(sort: \ScoreKeepMatchTemplate.lastUsedAt, order: .reverse) private
        var templates: [ScoreKeepMatchTemplate]

    private let indoorVolleyball = ScoreKeepMatchTemplate(
        .volleyball,
        name: "Indoor volleyball",
        color: .neutral,
        environment: .indoor,
        rules: ScoreKeepMatchRules(
            winAt: 3,
            setRules: ScoreKeepSetRules(
                winAt: 6,
                gameRules: ScoreKeepGameRules(
                    winAt: 25
                )
            )
        ),
        warmup: .open
    )

    private let tennis = ScoreKeepMatchTemplate(
        .tennis,
        name: "Tennis",
        color: .neutral,
        environment: .outdoor,
        rules: ScoreKeepMatchRules(
            winAt: 1,
            setRules: ScoreKeepSetRules(
                winAt: 6,
                winBy: 2,
                maximum: 7,
                winBehavior: .end,
                gameRules: ScoreKeepGameRules(
                    winAt: 4,
                    winBy: 2
                )
            )
        ),
        warmup: .open
    )

    private let ultimate = ScoreKeepMatchTemplate(
        .ultimate,
        name: "Ultimate frisbee",
        color: .neutral,
        environment: .outdoor,
        rules: ScoreKeepMatchRules(
            winAt: 1,
            setRules: ScoreKeepSetRules(
                winAt: 1,
                gameRules: ScoreKeepGameRules(
                    winAt: 15
                )
            )
        ),
        warmup: .open
    )

    private let squash = ScoreKeepMatchTemplate(
        .squash,
        name: "Squash",
        color: .neutral,
        environment: .outdoor,
        rules: ScoreKeepMatchRules(
            winAt: 1,
            setRules: ScoreKeepSetRules(
                winAt: 3,
                gameRules: ScoreKeepGameRules(
                    winAt: 11
                ),
            )
        ),
        warmup: .open
    )

    private let pickleball = ScoreKeepMatchTemplate(
        .pickleball,
        name: "Pickleball",
        color: .neutral,
        environment: .outdoor,
        rules: ScoreKeepMatchRules(
            winAt: 1,
            setRules: ScoreKeepSetRules(
                winAt: 2,
                winBehavior: .end,
                gameRules: ScoreKeepGameRules(
                    winAt: 11,
                    winBy: 2
                )
            )
        ),
        warmup: .open
    )

    private var unusedBuiltinTemplates: [ScoreKeepMatchTemplate] {
        return [indoorVolleyball, tennis, ultimate, squash, pickleball].filter {
            !templates.contains($0)
        }
    }

    var body: some View {
        @Bindable var navigation = navigation

        NavigationStack(path: $navigation.path) {
            List {
                ForEach(templates) { template in
                    StartMatchNavigationLinkView(template: template)
                }

                ForEach(unusedBuiltinTemplates) { template in
                    StartMatchNavigationLinkView(template: template)
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
            .navigationDestination(for: NavigationLocation.TemplateCreate.self) {
                createMatchTemplateDestination in
                MatchTemplateCreateView(template: createMatchTemplateDestination.template)
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
    var template: ScoreKeepMatchTemplate
    var markAsUsed: Bool = true

    @Environment(NavigationManager.self) private var navigation

    var body: some View {
        NavigationLink(
            value: NavigationLocation.ActiveMatch(template: template)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: template.sport.figureIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .fontWeight(.bold)
                    .foregroundStyle(.tint)

                MatchRulesDetailView(
                    name: template.name,
                    sport: template.sport,
                    rules: template.rules
                )
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
