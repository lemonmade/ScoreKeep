import SwiftUI
import SwiftData
import ScoreKeepCore

struct CreateMatchView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sportscourt")
                    .font(.system(size: 48))
                Text("Create a Match")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Start setting up a new match. Configure teams, scoring, and more.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button {
                    // TODO: Implement creation flow
                } label: {
                    Label("Start", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Create")
        }
    }
}

#Preview {
    CreateMatchView()
        .modelContainer(MatchModelContainer().testModelContainer())
}
