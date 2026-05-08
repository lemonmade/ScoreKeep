import ScoreKeepCore
import SwiftData
import SwiftUI

public struct DebugSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var resultMessage: ResultMessage?

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("iCloud") {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete all data from iCloud", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Debug")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete all match data?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) {
                    performDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes all matches, sets, games, warmups, and templates from this device and iCloud.")
            }
            .alert(
                resultMessage?.title ?? "",
                isPresented: Binding(
                    get: { resultMessage != nil },
                    set: { if !$0 { resultMessage = nil } }
                ),
                presenting: resultMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message.body)
            }
        }
    }

    private func performDelete() {
        do {
            try DebugMode.deleteAllData(modelContext: modelContext)
            resultMessage = ResultMessage(
                title: "Deleted",
                body: "All data has been removed locally and queued for iCloud sync."
            )
        } catch {
            resultMessage = ResultMessage(
                title: "Delete failed",
                body: error.localizedDescription
            )
        }
    }

    private struct ResultMessage: Identifiable {
        let id = UUID()
        let title: String
        let body: String
    }
}
