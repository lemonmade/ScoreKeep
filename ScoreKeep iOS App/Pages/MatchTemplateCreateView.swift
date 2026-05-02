//
//  MatchTemplateCreateView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-01-29.
//

import ScoreKeepCore
import SwiftUI

struct MatchTemplateCreateView: View {
    var template: ScoreKeepMatchTemplate?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var sport: ScoreKeepSport
    @State private var environment: ScoreKeepActivityEnvironment
    @State private var color: ScoreKeepMatchColor
    
    @State private var isMultiSet: Bool
    
    @State private var setsWinAt: Int
    @State private var setsPlayItOut: Bool

    @State private var gamesWinAt: Int
    @State private var gamesPlayItOut: Bool
    
    @State private var gameScoringWinScore: Int
    @State private var gameScoringMaximumScore: Int
    @State private var gameScoringWinBy: Int
    
    @State private var hasWarmup: Bool

    @State private var startWorkout: Bool

    @State private var participants: [ScoreKeepMatchParticipant]
    @State private var editingParticipant: ScoreKeepMatchParticipant?

    init(template: ScoreKeepMatchTemplate? = nil) {
        self.template = template
        let sport = template?.sport ?? .volleyball
        self.sport = sport
        self.name = template?.name ?? sport.label
        self.environment = template?.environment ?? .indoor
        self.color = template?.color ?? .green
        self.participants = template?.participants ?? ScoreKeepMatchTemplate.defaultParticipants
        
        let setsWinAt = template?.rules.winAt ?? 1
        let gameScoringWinScore = template?.rules.setRules.gameRules.winAt ?? 25
        let gameScoringWinBy = template?.rules.setRules.gameRules.winBy ?? 2
        
        self.setsWinAt = setsWinAt
        self.isMultiSet = setsWinAt > 1
        self.setsPlayItOut = template?.rules.winBehavior == .keepPlaying
        self.gamesWinAt = template?.rules.setRules.winAt ?? 3
        self.gamesPlayItOut = template?.rules.setRules.winBehavior == .keepPlaying
        self.gameScoringWinScore = gameScoringWinScore
        self.gameScoringWinBy = gameScoringWinBy
        self.gameScoringMaximumScore = template?.rules.setRules.gameRules.maximum ?? (gameScoringWinScore + gameScoringWinBy)
        
        self.hasWarmup = template?.warmup != .none
        self.startWorkout = template?.startWorkout ?? true
    }
    
    private let maximumBasicScore = 50

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)

                    Picker("Sport", selection: $sport) {
                        ForEach(ScoreKeepSport.allCases, id: \.self) { sport in
                            Label {
                                Text(sport.label)
                            } icon: {
                                Image(systemName: sport.figureIcon)
                            }
                            .tag(sport)
                        }
                    }

                    Picker("Environment", selection: $environment) {
                        Text("Indoor").tag(ScoreKeepActivityEnvironment.indoor)
                        Text("Outdoor").tag(ScoreKeepActivityEnvironment.outdoor)
                    }

                    MatchTemplateColorPickerView(selected: $color)
                }

                Section("Participants") {
                    ForEach(participants) { participant in
                        Button {
                            editingParticipant = participant
                        } label: {
                            ParticipantRowView(participant: participant)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(header: Text("Points")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Win at")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Stepper(value: $gameScoringWinScore, in: 1...maximumBasicScore, step: 1) {
                            Text("\(gameScoringWinScore)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        .onChange(of: gameScoringWinScore) {
                            let impliedMaximum = gameScoringWinScore + gameScoringWinBy - 1
                            
                            if impliedMaximum > gameScoringMaximumScore {
                                gameScoringMaximumScore = impliedMaximum
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Win by")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Stepper(value: $gameScoringWinBy, in: 1...10, step: 1) {
                            Text("\(gameScoringWinBy)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        .onChange(of: gameScoringWinBy) {
                            if gameScoringWinBy == 1, gameScoringWinScore != gameScoringMaximumScore {
                                gameScoringMaximumScore = gameScoringWinScore
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if gameScoringWinBy > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max score")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Stepper(value: $gameScoringMaximumScore, in: (gameScoringWinScore + gameScoringWinBy - 1)...(maximumBasicScore + gameScoringWinBy - 1), step: 1) {
                                Text("\(gameScoringMaximumScore)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                            .onChange(of: gameScoringMaximumScore) {
                                let impliedWinScore = gameScoringMaximumScore - gameScoringWinBy + 1

                                if impliedWinScore < gameScoringWinScore {
                                    gameScoringWinScore = impliedWinScore
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Games")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First to")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Stepper(value: $gamesWinAt, in: 1...50, step: 1) {
                            Text("\(gamesWinAt)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Picker("After win", selection: $gamesPlayItOut) {
                        Text("End set").tag(false)
                        Text("Play it out").tag(true)
                    }
                }
                
                Section(header: Text("Sets")) {
                    Toggle(isOn: $isMultiSet) {
                        Text("Multiple sets")
                    }
                    .onChange(of: isMultiSet) {
                        if isMultiSet {
                            if setsWinAt <= 1 { setsWinAt = 2 }
                        } else {
                            if setsWinAt > 1 { setsWinAt = 1 }
                        }
                    }
                    
                    if setsWinAt > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First to")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Stepper(value: $setsWinAt, in: 2...50, step: 1) {
                                Text("\(setsWinAt)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Picker("After win", selection: $setsPlayItOut) {
                            Text("End match").tag(false)
                            Text("Play it out").tag(true)
                        }
                    }
                }
                
                Section(header: Text("Warmup")) {
                    Toggle(isOn: $hasWarmup) {
                        Text("Warmup before match")
                    }
                }
                
                Section(header: Text("Workout")) {
                    Toggle(isOn: $startWorkout) {
                        Text("Start workout")
                    }
                }

                Section {
                    Button {
                        saveAndStart()
                    } label: {
                        Text("Start Match")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.green)
                    
                    if template != nil {
                        Button {
                            saveAndDismiss()
                        } label: {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }

                    if let template, template.lastUsedAt != nil {
                        Button(role: .destructive) {
                            context.delete(template)
                            try? context.save()
                            dismiss()
                        } label: {
                            Text("Delete Template")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingParticipant) { participant in
                MatchTemplateParticipantEditView(participant: participant) { updated in
                    if let index = participants.firstIndex(where: { $0.team == updated.team }) {
                        participants[index] = updated
                    }
                }
            }
        }
    }

    private func asScoringRules() -> ScoreKeepMatchRules {
        return ScoreKeepMatchRules(
            winAt: setsWinAt,
            winBy: 1,
            maximum: setsWinAt,
            winBehavior: setsPlayItOut ? .keepPlaying : .end,
            setRules: ScoreKeepSetRules(
                winAt: gamesWinAt,
                winBy: 1,
                maximum: gamesWinAt,
                winBehavior: gamesPlayItOut ? .keepPlaying : .end,
                gameRules: ScoreKeepGameRules(
                    winAt: gameScoringWinScore,
                    winBy: gameScoringWinBy,
                    maximum: gameScoringMaximumScore
                )
            )
        )
    }
    
    private func asWarmupRule() -> ScoreKeepWarmupRule {
        return hasWarmup ? .open : .none
    }
    
    private func saveAndDismiss() {
        if let template {
            // Update existing template
            template.name = name
            template.sport = sport
            template.environment = environment
            template.color = color
            template.rules = asScoringRules()
            template.warmup = asWarmupRule()
            template.startWorkout = startWorkout
            template.participants = participants

            if template.hasChanges {
                try? context.save()
            }
        } else {
            // Create new template
            let newTemplate = ScoreKeepMatchTemplate(
                sport,
                name: name,
                color: color,
                environment: environment,
                rules: asScoringRules(),
                warmup: asWarmupRule(),
                startWorkout: startWorkout,
                participants: participants
            )
            context.insert(newTemplate)
            try? context.save()
        }

        dismiss()
    }

    private func saveAndStart() {
        let templateToUse: ScoreKeepMatchTemplate

        if let template {
            // Update existing template
            template.name = name
            template.sport = sport
            template.environment = environment
            template.color = color
            template.rules = asScoringRules()
            template.warmup = asWarmupRule()
            template.startWorkout = startWorkout
            template.participants = participants
            templateToUse = template

            if template.id.storeIdentifier == nil {
                context.insert(template)
            }
        } else {
            // Create new template
            let newTemplate = ScoreKeepMatchTemplate(
                sport,
                name: name,
                color: color,
                environment: environment,
                rules: asScoringRules(),
                warmup: asWarmupRule(),
                startWorkout: startWorkout,
                participants: participants
            )
            context.insert(newTemplate)
            templateToUse = newTemplate
        }
        
        try? context.save()
        
        // Start a new match from this template
        let match = templateToUse.createMatch()
        context.insert(match)
        
        // Start warmup or first game
        if hasWarmup {
            match.startWarmup()
        } else {
            match.startGame()
        }
        
        try? context.save()
        
        // TODO: Navigate to ActiveMatchView with this match
        // For now, just dismiss
        dismiss()
    }
}

struct ParticipantRowView: View {
    let participant: ScoreKeepMatchParticipant

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(participant.resolvedColor.color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.resolvedName)
                    .foregroundStyle(.primary)
                Text(participant.resolvedShortLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

struct MatchTemplateParticipantEditView: View {
    let initial: ScoreKeepMatchParticipant
    let onSave: (ScoreKeepMatchParticipant) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var shortLabel: String
    @State private var color: ScoreKeepTeamColor

    init(
        participant: ScoreKeepMatchParticipant,
        onSave: @escaping (ScoreKeepMatchParticipant) -> Void
    ) {
        self.initial = participant
        self.onSave = onSave
        _name = State(initialValue: participant.name ?? "")
        _shortLabel = State(initialValue: participant.shortLabel ?? "")
        _color = State(initialValue: participant.resolvedColor)
    }

    private var derivedShortPlaceholder: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let source = trimmed.isEmpty ? initial.team.defaultLabel(size: initial.size) : trimmed
        return ScoreKeepMatchParticipant.deriveShortLabel(from: source)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField(initial.team.defaultLabel(size: initial.size), text: $name)
                    TextField(
                        "Short label (max 4)",
                        text: $shortLabel,
                        prompt: Text(derivedShortPlaceholder)
                    )
                    .onChange(of: shortLabel) {
                        if shortLabel.count > 4 {
                            shortLabel = String(shortLabel.prefix(4))
                        }
                    }
                    .textInputAutocapitalization(.characters)
                }

                Section("Color") {
                    ParticipantColorPickerView(selected: $color)
                }
            }
            .navigationTitle("Edit Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var updated = initial
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        let trimmedShort = shortLabel.trimmingCharacters(in: .whitespaces)
                        updated.name = trimmedName.isEmpty ? nil : trimmedName
                        updated.shortLabel = trimmedShort.isEmpty ? nil : trimmedShort
                        updated.color = color
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ParticipantColorPickerView: View {
    @Binding var selected: ScoreKeepTeamColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ScoreKeepTeamColor.allCases, id: \.self) { teamColor in
                    Button {
                        selected = teamColor
                    } label: {
                        ZStack {
                            Circle()
                                .fill(teamColor.color.opacity(0.6))
                                .frame(width: 44, height: 44)

                            if selected == teamColor {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Circle()
                                    .strokeBorder(teamColor.color, lineWidth: 3)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct MatchTemplateColorPickerView: View {
    @Binding var selected: ScoreKeepMatchColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ScoreKeepMatchColor.allCases, id: \.self) { matchColor in
                    Button {
                        selected = matchColor
                    } label: {
                        ZStack {
                            Circle()
                                .fill(matchColor.color.opacity(0.6))
                                .frame(width: 44, height: 44)

                            if selected == matchColor {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Circle()
                                    .strokeBorder(matchColor.color, lineWidth: 3)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    MatchTemplateCreateView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
}
