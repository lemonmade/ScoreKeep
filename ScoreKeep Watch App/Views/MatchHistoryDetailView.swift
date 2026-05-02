//
//  MatchHistoryDetailView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-31.
//

import Foundation
import SwiftUI
import Charts
import ScoreKeepCore
import ScoreKeepUI

struct MatchHistoryDetailView: View {
    var match: ScoreKeepMatch

    private let web = ScoreKeepWeb()

    @State private var shareURL: URL?
    @State private var isSharing = false
    @State private var isPresentingShare = false
    @State private var shareError: Error?

    var body: some View {
        TabView {
            VStack {
                MatchHistorySummaryView(match: match)

                Button {
                    guard !isSharing else { return }
                    isSharing = true
                    shareError = nil
                    Task {
                        do {
                            let response = try await web.share(match: match)
                            shareURL = response.url
                            isPresentingShare = true
                        } catch {
                            shareError = error
                        }
                        isSharing = false
                    }
                } label: {
                    Label(
                        shareError != nil ? "Retry Share" : "Share",
                        systemImage: "square.and.arrow.up"
                    )
                    .opacity(isSharing ? 0 : 1)
                    .overlay {
                        if isSharing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSharing)
            }
            .sheet(isPresented: $isPresentingShare) {
                if let shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share Match", systemImage: "square.and.arrow.up")
                    }
                }
            }

            ForEach(match.sets) { set in
                ForEach(set.games) { game in
                    MatchHistoryDetailGameView(game: game)
                }
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

struct MatchHistoryDetailMatchView: View {
    var match: ScoreKeepMatch

    private let dateFormatter = Date.FormatStyle(
        date: .abbreviated,
        time: .none
    )

    private let dateRangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        return formatter
    }()

    private var endDate: Date {
        match.endedAt ?? match.startedAt
    }

    private var dateRange: ClosedRange<Date> {
        match.startedAt...endDate
    }

    private var summary: String {
        let dateRange = self.dateRange
        return "\(dateFormatter.format(endDate))\n\(dateRangeFormatter.string(from: dateRange.lowerBound, to: dateRange.upperBound))\n\(match.scoreSummaryString ?? "")"
    }

    var body: some View {
        ScrollView {
            VStack {
                MatchSummaryScoreTableView(match: match)
                    .padding()

                Text(endDate, format: dateFormatter)
                    .font(.headline)

                Text(dateRange)
                    .foregroundStyle(.secondary)

                ShareLink(item: summary) {
                    Label("Summary", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}
