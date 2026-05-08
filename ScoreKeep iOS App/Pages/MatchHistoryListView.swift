import SwiftUI
import SwiftData
import ScoreKeepCore
import ScoreKeepUI

struct MatchHistoryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ScoreKeepMatch.endedAt, order: .reverse) private var matches: [ScoreKeepMatch]

    private let web = ScoreKeepWeb()

    @State private var shareURL: URL?
    @State private var isPresentingShare = false
    @State private var shareError: Error?

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "No matches yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Finished matches will appear here.")
                    )
                } else {
                    List {
                        ForEach(matches) { match in
                            NavigationLink {
                                MatchHistoryDetailView(match: match)
                            } label: {
                                MatchHistorySummaryView(match: match)
                            }
                            .swipeActions {
                                Button {
                                    Task {
                                        do {
                                            let response = try await web.share(match: match)
                                            shareURL = response.url
                                            isPresentingShare = true
                                        } catch {
                                            shareError = error
                                            print("Share error: \(shareError?.localizedDescription ?? "")")
                                        }
                                    }
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Button(role: .destructive) {
                                    context.delete(match)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(isPresented: $isPresentingShare) {
                if let shareURL {
                    ActivityView(activityItems: [shareURL])
                        .ignoresSafeArea()
                } else {
                    Text("Nothing to share")
                }
            }
        }
    }
}

// A tiny UIKit wrapper for the native share sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

#Preview {
    MatchHistoryListView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
}
