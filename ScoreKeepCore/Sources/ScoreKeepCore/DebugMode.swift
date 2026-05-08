import Foundation
import SwiftData

public enum DebugMode {
    public static var isEnabled: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }

    private static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    @MainActor
    public static func deleteAllData(modelContext: ModelContext) throws {
        try modelContext.delete(model: ScoreKeepMatch.self)
        try modelContext.delete(model: ScoreKeepSet.self)
        try modelContext.delete(model: ScoreKeepGame.self)
        try modelContext.delete(model: ScoreKeepWarmup.self)
        try modelContext.delete(model: ScoreKeepMatchTemplate.self)
        try modelContext.save()
    }
}
