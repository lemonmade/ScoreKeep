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

    var body: some View {
        TabView {
            MatchHistoryDetailSummaryView(match: match)

            ForEach(match.sets) { set in
                ForEach(set.games) { game in
                    MatchHistoryDetailGameView(game: game)
                }
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

struct MatchHistoryDetailSummaryView: View {
    @Environment(NavigationManager.self) private var navigation

    var match: ScoreKeepMatch

    private let web = ScoreKeepWeb()

    @State private var shareURL: URL?
    @State private var isSharing = false
    @State private var isPresentingShare = false
    @State private var shareError: Error?

    /// Show the per-set/per-game table only when it actually adds context
    /// beyond the headline score. For a single-game match it's redundant,
    /// and for a single-set match in summary mode (long format like
    /// "first to N games") the table just reprints the same games-won
    /// number the header would.
    private var showsScoreTable: Bool {
        let isMultiGameOrMore = match.isMultiSet || (match.latestSet?.isMultiGame ?? false)
        guard isMultiGameOrMore else { return false }

        if !match.isMultiSet {
            // Single-set, multi-game: the table only shows per-game columns
            // (richer than the header) when the set has a small fixed maximum
            // game count. Otherwise it falls back to a games-won summary that
            // duplicates the header.
            let maxGames = match.rules.setRules.maximumGameCount ?? 0
            return maxGames >= 2 && maxGames <= 5
        }

        return true
    }

    private var matchColor: ScoreKeepMatchColor {
        match.template?.color ?? .neutral
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    MatchScoreboardHeaderView(
                        match: match,
                        summaryStyle: .matchOutcome,
                        size: .compact
                    )

                    if showsScoreTable {
                        MatchScoreboardTableView(match: match, size: .compact)
                            .padding(.top, 2)
                    }
                }

                detailsBox
                    .padding(.top, 14)

                HStack(spacing: 8) {
                    shareActionButton
                    againActionButton
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $isPresentingShare) {
            if let shareURL {
                ShareLink(item: shareURL) {
                    Label("Share Match", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    @ViewBuilder
    private var detailsBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(match.label)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 1) {
                MatchHistoryDetailDateView(match: match)
                MatchHistoryDetailDurationView(match: match)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Reserve trailing space so the corner tag never forces text to wrap
        // around it.
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 38))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .overlay(alignment: .bottomTrailing) {
            // Mirror the template-card treatment: a subdued/semi-transparent
            // background tinted with the match color, and the icon itself
            // rendered in the full vibrant tint.
            Image(systemName: match.sport.figureIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(matchColor.iconForegroundStyle)
                .frame(width: 26, height: 26)
                .background(Circle().fill(matchColor.backgroundFillStyle))
                .padding(6)
        }
    }

    // MARK: Actions

    @ViewBuilder
    private var shareActionButton: some View {
        let icon = shareError != nil ? "arrow.clockwise" : "square.and.arrow.up"
        let label: String =
            isSharing
                ? "Sharing…"
                : (shareError != nil ? "Retry" : "Share")

        neutralActionButton(
            icon: icon,
            label: label,
            isLoading: isSharing,
            isEnabled: !isSharing,
            action: handleShareTapped
        )
    }

    @ViewBuilder
    private var againActionButton: some View {
        neutralActionButton(
            icon: "play.fill",
            label: "Again",
            isLoading: false,
            isEnabled: match.template != nil,
            action: handleAgainTapped
        )
    }

    @ViewBuilder
    private func neutralActionButton(
        icon: String,
        label: String,
        isLoading: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let textColor: Color = isEnabled ? .primary : Color.white.opacity(0.5)

        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Capsule().fill(.primary.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func handleShareTapped() {
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
    }

    private func handleAgainTapped() {
        guard let template = match.template else { return }
        navigation.navigate(to: NavigationLocation.ActiveMatch(template: template))
    }
}
