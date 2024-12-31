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
                    NavigationLink {
                        Text(match.id.storeIdentifier ?? "Unknown")
                    } label: {
                        VStack(alignment: .leading) {
                            GameMatchSummaryView(match: match)
                                .font(.headline)
                            Text(
                                (match.endedAt ?? match.startedAt).description
                            )
                                .font(.caption2)
                        }
                    }
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
        }
    }
}

struct GameMatchSummaryView: View {
    var match: Match

    var body: some View {
        Text("\((match.latestSet?.games ?? []).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))")
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
