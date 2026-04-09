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

    init(template: ScoreKeepMatchTemplate? = nil) {
        self.template = template
        let sport = template?.sport ?? .volleyball
        self.sport = sport
        self.name = template?.name ?? sport.label
        self.environment = template?.environment ?? .indoor
        self.color = template?.color ?? .green
        
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
                startWorkout: startWorkout
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
                startWorkout: startWorkout
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
