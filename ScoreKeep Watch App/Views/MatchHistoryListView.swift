//
//  MatchHistoryListView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI
import SwiftData

struct MatchHistoryListView: View {
    @Query(sort: \Match.startedAt, order: .reverse) private var matches: [Match]
    @Environment(\.modelContext) private var matchesContext
    @Environment(NavigationManager.self) private var navigation
    
    private let dateFormatter = Date.FormatStyle(
        date: .abbreviated,
        time: .none
    )
    
    var body: some View {
        if matches.isEmpty {
            VStack(spacing: 12) {
                Text("You haven’t played a match yet.")
                    .multilineTextAlignment(.center)
                
                Button {
                    navigation.navigate(to: NavigationLocation.TemplateCreate())
                } label: {
                    Text("Start one now")
                }
                .tint(.green)
            }
        } else {
            List {
                ForEach(matches) { match in
                    NavigationLink(
                        value: NavigationLocation
                            .MatchHistoryDetail(match: match)
                    ) {
                        HStack(alignment: .top, spacing: 8) {
                            MatchTotalScoreSummaryView(match: match)

                            VStack(alignment: .leading) {
                                Text(
                                    (match.endedAt ?? match.startedAt).formatted(
                                        dateFormatter
                                    )
                                )
                                .font(.headline)
                                
                                MatchHistoryMatchDurationDetailView(
                                    match: match
                                )
                                
                                MatchHistoryMatchDetailTextView(match: match)
                            }
                        }
                    }
                    .padding(
                        EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
                    )
                    .swipeActions {
                        Button(role: .destructive) {
                            matchesContext.delete(match)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.carousel)
            .navigationTitle("Match history")
        }
    }
}

struct MatchHistoryMatchDurationDetailView: View {
    var match: Match
    
    private var startedAt: Date { match.startedAt }
    private var endedAt: Date { match.endedAt ?? match.startedAt }
    
    var body: some View {
        Text(startedAt...endedAt)
            .foregroundStyle(.secondary)
    }
}

struct MatchHistoryMatchDetailTextView: View {
    var match: Match
    
    var body: some View {
        if match.isMultiSet {
            Text(
                "\((match.orderedSets).map { "\($0.gamesUs)-\($0.gamesThem)" }.joined(separator: ", "))"
            )
            .font(.caption)
            .foregroundColor(.secondary)
        } else {
            Text(
                "\((match.latestSet?.orderedGames ?? []).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))"
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MatchHistoryListView()
        .environment(NavigationManager())
        .modelContainer(previewContainer)
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: Match.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        return container
    } catch {
        fatalError("Could not load preview container: \(error)")
    }
}()
