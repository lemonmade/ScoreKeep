//
//  StartView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-16.
//

import ScoreKeepCore
import ScoreKeepUI
import SwiftData
import SwiftUI

struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ScoreKeepMatchTemplate.lastUsedAt, order: .reverse) private var templates: [ScoreKeepMatchTemplate]
    @Query(sort: \ScoreKeepMatch.endedAt, order: .reverse) private var matches: [ScoreKeepMatch]

    @State private var activeMatch: ScoreKeepMatch?

    private let defaultTemplates: [ScoreKeepMatchTemplate] = createDefaultTemplates()

    private var maxRecentMatches: Int {
        return min(5, matches.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Start new match") {
                    ForEach(defaultTemplates) { template in
                        Button {
                            startNewMatch(from: template)
                        } label: {
                            HStack {
                                Image(systemName: template.sport.figureIcon)
                                    .frame(width: 24)
                                Text(template.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                Section(
                    header: RecentMatchHeaderView(
                        moreLinkVisibility: matches.count > maxRecentMatches ? .visible : .hidden)
                ) {
                    ForEach(matches[0..<maxRecentMatches]) { match in
                        NavigationLink {
                            MatchHistoryDetailView(match: match)
                        } label: {
                            MatchHistorySummaryView(match: match)
                        }
                    }
                }
            }
            .navigationTitle("Start")
            .sheet(item: $activeMatch) { match in
                ActiveMatchView()
                    .environment(match)
                    .interactiveDismissDisabled()
            }
        }
    }

    private func startNewMatch(from template: ScoreKeepMatchTemplate) {
        let match = template.createMatch()
        context.insert(match)

        // Start the first game
        match.startGame()

        // Save context
        try? context.save()

        // Navigate to active match view
        activeMatch = match
    }
}

private func createDefaultTemplates() -> [ScoreKeepMatchTemplate] {
    let volleyball = ScoreKeepMatchTemplate(
        .volleyball,
        name: "Indoor volleyball",
        color: .green,
        environment: .indoor,
    )
    let tennis = ScoreKeepMatchTemplate(
        .tennis,
        name: "Tennis",
        color: .yellow,
        environment: .outdoor,
    )
    let pickleball = ScoreKeepMatchTemplate(
        .pickleball,
        name: "Pickleball",
        color: .green,
        environment: .outdoor,
    )
    let squash = ScoreKeepMatchTemplate(
        .squash,
        name: "Squash",
        color: .pink,
        environment: .indoor,
    )
    let ultimate = ScoreKeepMatchTemplate(
        .ultimate,
        name: "Ultimate frisbee",
        color: .purple,
        environment: .outdoor,
    )

    return [volleyball, tennis, ultimate, squash, pickleball]
}

struct RecentMatchHeaderView: View {
    @Environment(AppNavigation.self) private var navigation

    var moreLinkVisibility: Visibility = .visible

    var body: some View {
        HStack(spacing: 12) {
            Text("Recent matches")
                .foregroundStyle(.primary)

            if moreLinkVisibility != .hidden {
                Button {
                    navigation.tab = .history
                } label: {
                    HStack(spacing: 4) {
                        Text("More")
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
    }
}

#Preview {
    StartView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
        .environment(AppNavigation())
}
