//
//  GameHistoryView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI
import SwiftData

struct GameHistoryView: View {
    @Query(sort: \Match.startedAt, order: .reverse) private var matches: [Match]
    @Environment(\.modelContext) private var matchesContext
    
    var body: some View {
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

struct GameMatchSummaryView: View {
    var match: Match

    var body: some View {
        Text("\((match.latestSet?.games ?? []).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))")
    }
}

#Preview {
    GameHistoryView()
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
