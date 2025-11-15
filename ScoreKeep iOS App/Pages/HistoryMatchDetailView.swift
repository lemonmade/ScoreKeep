//
//  HistoryMatchDetailView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-03.
//

import SwiftUI
import ScoreKeepCore
import ScoreKeepUI

struct HistoryMatchDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var match: Match
    
    private let web = ScoreKeepWeb()
    
    @State private var shareURL: URL?
    @State private var isPresentingShare = false
    @State private var shareError: Error?
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        MatchHistoryDetailDateView(match: match)
                        
                        MatchHistoryDetailDurationView(match: match)
                    }

                    MatchSummaryScoreTableView(match: match)
                }
                .listStyle(.plain)
                .listRowInsets(.none)
                .listRowBackground(Color.clear)
            }
            
            ForEach(match.sets) { set in
                Section {
                    ForEach(set.games) { game in
                        HistoryMatchDetailGameView(match: match, game: game)
                    }
                } header: {
                    if match.isMultiSet {
                        Text("Set \(set.number)")
                    }
                }
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle(match.label)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            do {
                                let response = try await web.share(match: match)
                                shareURL = response.url
                                print("Share response: \(response.url.absoluteString)")
                                isPresentingShare = true
                            } catch {
                                shareError = error
                                print("Share error: \(shareError?.localizedDescription ?? "")")
                                // Optional: show an alert
                            }
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        context.delete(match)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $isPresentingShare) {
            if let shareURL {
                ActivityView(activityItems: [shareURL])
                    .ignoresSafeArea()
            } else {
                // Safety fallback if URL disappeared
                Text("Nothing to share")
            }
        }
    }
}

struct HistoryMatchDetailGameView: View {
    var match: Match
    var game: MatchGame
    
    var body: some View {
        DisclosureGroup {
            VStack {
                MatchGameChartView(game: game)
                    .padding(16)
                    .background(.secondary.opacity(0.05))
                    .cornerRadius(8)
            }
        } label: {
            HStack(spacing: 12) {
                MatchTotalScoreSummaryView(game: game)
                
                VStack(alignment: .leading) {
                    Text("Game \(game.number)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let endedAt = game.endedAt {
                        Text(game.startedAt...endedAt)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                MatchGameChartSparklineView(game: game)
            }
        }
    }
}

