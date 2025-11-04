import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Match.endedAt, order: .reverse) private var matches: [Match]

    var body: some View {
        NavigationView {
            List {
                ForEach(matches) { match in
                    NavigationLink {
                        HistoryMatchDetailView(match: match)
                    } label: {
                        MatchHistorySummaryView(match: match)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(MatchModelContainer().testModelContainer())
}
