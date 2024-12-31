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
    
    private let dateFormatter = Date.FormatStyle(date: .abbreviated, time: .none)
    
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
                    NavigationLink(value: NavigationLocation.MatchHistoryDetail(match: match)) {
                        HStack(alignment: .top, spacing: 8) {
                            MatchHistoryMatchOverallScoreView(match: match)

                            VStack(alignment: .leading) {
                                Text(
                                    (match.endedAt ?? match.startedAt).formatted(dateFormatter)
                                )
                                    .font(.headline)
                                
                                MatchHistoryMatchDurationDetailView(match: match)
                                
                                MatchHistoryMatchDetailTextView(match: match)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
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
    
    private let matchDateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm"
        return formatter
    }()
    
    var body: some View {
        Text(
            "\(matchDateFormatter.string(from: match.startedAt))-\(matchDateFormatter.string(from: (match.endedAt ?? match.startedAt)))"
        )
    }
}

struct MatchHistoryMatchDetailTextView: View {
    var match: Match
    
    var body: some View {
        if match.isMultiSet {
            Text("\((match.sets).map { "\($0.gamesUs)-\($0.gamesThem)" }.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Text("\((match.latestSet?.games ?? []).map { "\($0.scoreUs)-\($0.scoreThem)" }.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MatchHistoryMatchOverallScoreView: View {
    var match: Match
    
    var body: some View {
        if match.isMultiSet {
            MatchHistoryMatchOverallScoreCardView(us: match.setsUs, them: match.setsThem, winner: match.winner)
        } else {
            MatchHistoryMatchOverallScoreCardView(us: match.latestSet?.gamesUs ?? 0, them: match.latestSet?.gamesThem ?? 0, winner: match.latestSet?.winner)
        }
    }
}

struct MatchHistoryMatchOverallScoreCardView: View {
    var us: Int
    var them: Int
    var winner: MatchTeam?
    
    private let cornerRadius: CGFloat = 8
    private let innerPadding: CGFloat = 4
    private let outerPadding: CGFloat = 16
    
    var body: some View {
        Grid(verticalSpacing: 0) {
            GridRow {
                    Text("\(us)")
                        .fontWeight(winner == .us ? .bold : .regular)
                        .foregroundColor(.blue)
                        .padding(EdgeInsets(top: innerPadding, leading: outerPadding, bottom: innerPadding, trailing: outerPadding))
            }
            .background {
                UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: cornerRadius, bottomLeading: winner == .us ? 4 : 0, bottomTrailing: winner == .us ? 4 : 0, topTrailing: cornerRadius))
                    .fill(.blue.opacity(0.25))
                    .stroke(.blue, style: StrokeStyle(lineWidth: winner == .us ? 2 : 0))
            }
            
            
            GridRow {
                Text("\(them)")
                    .fontWeight(winner == .them ? .bold : .regular)
                    .foregroundColor(.red)
                    .padding(EdgeInsets(top: innerPadding, leading: outerPadding, bottom: innerPadding, trailing: outerPadding))
            }
            
            .background {
                UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: winner == .them ? 4 : 0, bottomLeading: cornerRadius, bottomTrailing: cornerRadius, topTrailing: winner == .them ? 4 : 0))
                    .fill(.red.opacity(0.25))
                    .stroke(.red, style: StrokeStyle(lineWidth: winner == .them ? 2 : 0))
            }
        }
        .monospacedDigit()
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
