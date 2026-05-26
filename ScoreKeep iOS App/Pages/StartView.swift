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

    @State private var activeMatch: ScoreKeepMatch?
    @State private var showingTemplateCreator = false
    @State private var showingSettings = false
    @State private var showingDebug = false
    @State private var templateToEdit: ScoreKeepMatchTemplate?

    private let defaultTemplates: [ScoreKeepMatchTemplate] = createDefaultTemplates()

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
                                onEdit: { template in templateToEdit = template },
                                onCreate: { showingTemplateCreator = true }
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Start")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            if DebugMode.isEnabled { showingDebug = true }
                        }
                    )
                }
            }
            .sheet(item: $activeMatch) { match in
                ActiveMatchView()
                    .environment(match)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showingTemplateCreator) {
                MatchTemplateCreateView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingDebug) {
                DebugSheetView()
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
    var onCreate: (() -> Void)? = nil

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

            if let onCreate {
                CreateTemplateCardView(onCreate: onCreate)
            }
        }
        .padding(.horizontal)
    }
}

/// Fixed height shared by template cards and the create card so every cell in
/// the grid is exactly the same size regardless of how much text a template
/// has (aspect-ratio sizing let content stretch some cards taller than others).
private let templateCardHeight: CGFloat = 152

struct TemplateCardView: View {
    var template: ScoreKeepMatchTemplate
    var onStart: () -> Void
    var onEdit: () -> Void

    var body: some View {
        Button {
            onStart()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer(minLength: 0)

                Image(systemName: template.sport.figureIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .fontWeight(.bold)
                    .foregroundStyle(template.color.iconForegroundStyle)

                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(template.sport.label)
                    Text("•")
                    Text(template.environment == .indoor ? "Indoor" : "Outdoor")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 6, leading: 16, bottom: 16, trailing: 16))
            .frame(height: templateCardHeight)
            .background(template.color.backgroundFillStyle)
            .cornerRadius(20)
            .overlay(alignment: .topTrailing) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(template.color.color.opacity(0.7))
                        .padding(9)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.trailing, 8)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CreateTemplateCardView: View {
    var onCreate: () -> Void

    var body: some View {
        Button(action: onCreate) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                Text("New Template")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: templateCardHeight)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        Color.primary.opacity(0.18),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                    )
            )
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

#Preview {
    StartView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
        .environment(AppNavigation())
}
