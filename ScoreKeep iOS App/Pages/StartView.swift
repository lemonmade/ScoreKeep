//
//  StartView.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-11-16.
//

import ScoreKeepCore
import ScoreKeepUI
import SwiftData
import SwiftUI

struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ScoreKeepMatchTemplate.lastUsedAt, order: .reverse) private var templates:
        [ScoreKeepMatchTemplate]
    @Query(sort: \ScoreKeepMatch.endedAt, order: .reverse) private var matches: [ScoreKeepMatch]

    @State private var activeMatch: ScoreKeepMatch?
    @State private var showingTemplateCreator = false
    @State private var templateToEdit: ScoreKeepMatchTemplate?

    private let defaultTemplates: [ScoreKeepMatchTemplate] = createDefaultTemplates()

    private var maxRecentMatches: Int {
        return min(5, matches.count)
    }

    private var unusedDefaultTemplates: [ScoreKeepMatchTemplate] {
        return defaultTemplates.filter { defaultTemplate in
            !templates.contains { $0.name == defaultTemplate.name }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User-created and used templates
                    if !templates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Templates")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            TemplateGridView(
                                templates: templates,
                                onStart: { template in startNewMatch(from: template) },
                                onEdit: { template in templateToEdit = template }
                            )
                        }
                    }

                    // Default templates that haven't been used
                    if !unusedDefaultTemplates.isEmpty || true {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Start new match")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            TemplateGridView(
                                templates: unusedDefaultTemplates,
                                onStart: { template in startNewMatch(from: template) },
                                onEdit: { template in templateToEdit = template }
                            )

                            Button {
                                showingTemplateCreator = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Custom Template")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Recent matches
                    if !matches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            RecentMatchHeaderView(
                                moreLinkVisibility: matches.count > maxRecentMatches ? .visible : .hidden
                            )
                            .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(matches[0..<maxRecentMatches]) { match in
                                    NavigationLink {
                                        MatchHistoryDetailView(match: match)
                                    } label: {
                                        MatchHistorySummaryView(match: match)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Start")
            .sheet(item: $activeMatch) { match in
                ActiveMatchView()
                    .environment(match)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showingTemplateCreator) {
                MatchTemplateCreateView()
            }
            .sheet(item: $templateToEdit) { template in
                MatchTemplateCreateView(template: template)
            }
        }
    }

    private func startNewMatch(from template: ScoreKeepMatchTemplate) {
        let match = template.createMatch()
        context.insert(match)

        // Start warmup or first game
        if template.warmup != .none {
            match.startWarmup()
        } else {
            match.startGame()
        }

        // Save context
        try? context.save()

        // Navigate to active match view
        activeMatch = match
    }
}

struct TemplateGridView: View {
    var templates: [ScoreKeepMatchTemplate]
    var onStart: (ScoreKeepMatchTemplate) -> Void
    var onEdit: (ScoreKeepMatchTemplate) -> Void

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(templates) { template in
                TemplateCardView(
                    template: template,
                    onStart: { onStart(template) },
                    onEdit: { onEdit(template) }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct TemplateCardView: View {
    var template: ScoreKeepMatchTemplate
    var onStart: () -> Void
    var onEdit: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        // Calculate luminance to determine if we should use light or dark text
        let color = template.color.color
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate relative luminance
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        // Use white text for dark colors, black text for light colors
        return luminance > 0.5 ? Color.black : Color.white
    }

    var body: some View {
        Button {
            onStart()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer()
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(textColor.opacity(0.8))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(textColor.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Image(systemName: template.sport.figureIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)

                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(template.sport.label)
                    Text("•")
                    Text(template.environment == .indoor ? "Indoor" : "Outdoor")
                }
                .font(.caption)
                .foregroundStyle(textColor.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .aspectRatio(1, contentMode: .fit)
            .background(template.color.color)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

private func createDefaultTemplates() -> [ScoreKeepMatchTemplate] {
    let volleyball = ScoreKeepMatchTemplate(
        .volleyball,
        name: "Indoor volleyball",
        color: .green,
        environment: .indoor,
    )
    let tennis = ScoreKeepMatchTemplate(
        .tennis,
        name: "Tennis",
        color: .yellow,
        environment: .outdoor,
    )
    let pickleball = ScoreKeepMatchTemplate(
        .pickleball,
        name: "Pickleball",
        color: .green,
        environment: .outdoor,
    )
    let squash = ScoreKeepMatchTemplate(
        .squash,
        name: "Squash",
        color: .pink,
        environment: .indoor,
    )
    let ultimate = ScoreKeepMatchTemplate(
        .ultimate,
        name: "Ultimate frisbee",
        color: .purple,
        environment: .outdoor,
    )

    return [volleyball, tennis, ultimate, squash, pickleball]
}

struct RecentMatchHeaderView: View {
    @Environment(AppNavigation.self) private var navigation

    var moreLinkVisibility: Visibility = .visible

    var body: some View {
        HStack(spacing: 12) {
            Text("Recent matches")
                .foregroundStyle(.primary)

            if moreLinkVisibility != .hidden {
                Button {
                    navigation.tab = .history
                } label: {
                    HStack(spacing: 4) {
                        Text("More")
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
    }
}

#Preview {
    StartView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
        .environment(AppNavigation())
}
