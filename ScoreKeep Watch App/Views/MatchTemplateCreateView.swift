//
//  MatchTemplateCreateView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI
import ScoreKeepCore

struct MatchTemplateCreateView: View {
    var template: ScoreKeepMatchTemplate? = nil

    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var navigation

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

    @State private var navigationTitle: String

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
        self.navigationTitle = template == nil ? "New match" : template!.name

        let warmup = template?.warmup ?? .none
        self.hasWarmup = warmup != .none

        self.startWorkout = template?.startWorkout ?? true
    }

    private let maximumBasicScore = 50

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)

                Picker("Sport", selection: $sport) {
                    Label("Tennis", systemImage: "tennisball.fill")
                        .tag(ScoreKeepSport.tennis)

                    Label("Squash", systemImage: "circle.fill")
                        .tag(ScoreKeepSport.squash)

                    Label("Ultimate", systemImage: "circle.circle.fill")
                        .tag(ScoreKeepSport.ultimate)

                    Label("Volleyball", systemImage: "volleyball.fill")
                        .tag(ScoreKeepSport.volleyball)
                }

                MatchTemplateColorPickerView(selected: $color)
                    .listRowBackground(EmptyView())

                Picker("Environment", selection: $environment) {
                    Text("Indoor").tag(ScoreKeepActivityEnvironment.indoor)
                    Text("Outdoor").tag(ScoreKeepActivityEnvironment.outdoor)
                }
                .pickerStyle(.navigationLink)
            }

            Section(header: Text("Participants")) {
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
                VStack {
                    Text("Win at")

                    Stepper(value: $gameScoringWinScore, in: 1...maximumBasicScore, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinScore)")
                        }
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
                .padding([.top, .bottom], 8)

                VStack {
                    Text("Win by")

                    Stepper(value: $gameScoringWinBy, in: 1...10, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinBy)")
                        }
                            .fontWeight(.bold)
                            .font(.title2)
                            .monospacedDigit()
                    }
                    .onChange(of: gameScoringWinBy) {
                        if gameScoringWinBy == 1, gameScoringWinScore != gameScoringMaximumScore {
                            gameScoringMaximumScore = gameScoringWinScore
                        }
                    }
                }
                .padding([.top, .bottom], 8)

                if gameScoringWinBy > 1 {
                    VStack {
                        Text("Max score")

                        Stepper(value: $gameScoringMaximumScore, in: (gameScoringWinScore + gameScoringWinBy - 1)...(maximumBasicScore + gameScoringWinBy - 1), step: 1) {
                            HStack(spacing: 0) {
                                Text("\(gameScoringMaximumScore)")
                            }
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
                    .padding([.top, .bottom], 8)
                }
            }

            Section(header: Text("Games")) {
                VStack {
                    Text("First to")
                    Stepper(value: $gamesWinAt, in: 1...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gamesWinAt)")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    }
                }
                .padding([.top, .bottom], 8)

                Picker("After win", selection: $gamesPlayItOut) {
                    Text("End set").tag(false)
                    Text("Play it out").tag(true)
                }
                .pickerStyle(.navigationLink)
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
                    VStack {
                        Text("First to")
                        Stepper(value: $setsWinAt, in: 2...50, step: 1) {
                            HStack(spacing: 0) {
                                Text("\(setsWinAt)")
                            }
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                        }
                    }
                    .padding([.top, .bottom], 8)

                    Picker("After win", selection: $setsPlayItOut) {
                        Text("End match").tag(false)
                        Text("Play it out").tag(true)
                    }
                    .pickerStyle(.navigationLink)
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
                    if let template {
                        save(template: template)

                        navigation
                            .navigate(
                                to: NavigationLocation
                                    .ActiveMatch(template: template)
                            )
                    } else {
                        let template = ScoreKeepMatchTemplate(
                            sport,
                            name: name,
                            color: color,
                            environment: environment,
                            rules: asRules(),
                            warmup: asWarmupRule(),
                            startWorkout: startWorkout,
                            participants: participants
                        )

                        context.insert(template)
                        // TODO
                        try? context.save()
                        navigation
                            .navigate(
                                to: NavigationLocation
                                    .ActiveMatch(template: template)
                            )
                    }
                } label: {
                    Text("Start")
                }
                .buttonStyle(.bordered)
                .listRowBackground(EmptyView())
                .tint(.green)

                if let template {
                    Button {
                        save(template: template)
                        navigation.pop()
                    } label: {
                        Text("Save")
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(EmptyView())
                }

                if template?.lastUsedAt != nil {
                    Button {
                        context.delete(template!)
                        // TODO
                        try? context.save()
                        navigation.pop()
                    } label: {
                        Text("Delete")
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(EmptyView())
                    .tint(.red)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .sheet(item: $editingParticipant) { participant in
            MatchTemplateParticipantEditView(participant: participant) { updated in
                if let index = participants.firstIndex(where: { $0.team == updated.team }) {
                    participants[index] = updated
                }
            }
        }
    }

    private func asRules() -> ScoreKeepMatchRules {
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

    private func save(template: ScoreKeepMatchTemplate) {
        let newRules = asRules()

        if template.name != name {
            template.name = name
        }

        if template.sport != sport {
            template.sport = sport
        }

        if template.color != color {
            template.color = color
        }

        if template.rules != newRules {
            template.rules = newRules
        }

        if template.startWorkout != startWorkout {
            template.startWorkout = startWorkout
        }

        let warmup = asWarmupRule()
        if template.warmup != warmup {
            template.warmup = warmup
        }

        if template.participants != participants {
            template.participants = participants
        }

        if template.id.storeIdentifier != nil {
            context.insert(template)
        }

        // TODO
        if template.hasChanges {
            try? context.save()
        }
    }
}

struct ParticipantRowView: View {
    let participant: ScoreKeepMatchParticipant

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(participant.resolvedColor.color)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(participant.resolvedName)
                Text(participant.resolvedShortLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
        Form {
            Section {
                TextField(initial.team.defaultLabel(size: initial.size), text: $name)
                TextField(derivedShortPlaceholder, text: $shortLabel)
                    .onChange(of: shortLabel) {
                        if shortLabel.count > 4 {
                            shortLabel = String(shortLabel.prefix(4))
                        }
                    }
            }

            Section(header: Text("Color")) {
                ParticipantColorPickerView(selected: $color)
                    .listRowBackground(EmptyView())
            }

            Section {
                Button {
                    var updated = initial
                    let trimmedName = name.trimmingCharacters(in: .whitespaces)
                    let trimmedShort = shortLabel.trimmingCharacters(in: .whitespaces)
                    updated.name = trimmedName.isEmpty ? nil : trimmedName
                    updated.shortLabel = trimmedShort.isEmpty ? nil : trimmedShort
                    updated.color = color
                    onSave(updated)
                    dismiss()
                } label: {
                    Text("Done")
                }
                .buttonStyle(.bordered)
                .listRowBackground(EmptyView())
                .tint(.green)
            }
        }
    }
}

struct ParticipantColorPickerView: View {
    @Binding var selected: ScoreKeepTeamColor
    @State private var showingSheet: Bool = false
    @State private var showingColors: [ScoreKeepTeamColor]

    init(selected: Binding<ScoreKeepTeamColor>) {
        self._selected = selected

        let firstThree = ScoreKeepTeamColor.allCases.prefix(3)
        self.showingColors = firstThree.contains(selected.wrappedValue)
            ? Array(firstThree)
            : [selected.wrappedValue] + firstThree.prefix(2)
    }

    var body: some View {
        Grid(horizontalSpacing: 8) {
            GridRow {
                ForEach(showingColors, id: \.self) { teamColor in
                    Button {
                        selected = teamColor
                    } label: {
                        ZStack {
                            Color(teamColor.color.opacity(0.6))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(.circle)

                            if selected == teamColor {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(teamColor.color, lineWidth: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
                }

                Button {
                    showingSheet = true
                } label: {
                    ZStack {
                        Color(.darkGray)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(.circle)
                            .opacity(0.5)

                        Image(systemName: "ellipsis")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .sheet(isPresented: $showingSheet) {
                    ParticipantColorPickerSheetView(selected: $selected)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
            }
        }
        .onChange(of: selected) {
            if showingColors.contains(selected) { return }
            self.showingColors = [selected] + self.showingColors.prefix(2)
        }
    }
}

struct ParticipantColorPickerSheetView: View {
    @Binding var selected: ScoreKeepTeamColor

    var body: some View {
        ScrollView {
            LazyVGrid(columns: .init(repeating: GridItem(.flexible()), count: 4)) {
                ForEach(ScoreKeepTeamColor.allCases, id: \.self) { teamColor in
                    Button {
                        selected = teamColor
                    } label: {
                        ZStack {
                            Color(teamColor.color.opacity(0.6))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(.circle)

                            if selected == teamColor {
                                Image(systemName: "checkmark")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(teamColor.color, lineWidth: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(3)
                }
            }
        }
    }
}

struct MatchTemplateColorPickerView: View {
    var selected: Binding<ScoreKeepMatchColor>
    @State private var showingSheet: Bool = false
    @State private var showingColors: [ScoreKeepMatchColor]

    init(selected: Binding<ScoreKeepMatchColor>) {
        self.selected = selected

        let firstThreeColors = ScoreKeepMatchColor.allCases.prefix(3)

        self.showingColors = firstThreeColors.contains(selected.wrappedValue) ? Array(firstThreeColors) : [selected.wrappedValue] + firstThreeColors.prefix(2)
    }

    var body: some View {
        Grid(horizontalSpacing: 8) {
            GridRow {
                ForEach(showingColors, id: \.self) { matchColor in
                    Button {
                        selected.wrappedValue = matchColor
                    } label: {
                        ZStack {
                            Color(matchColor.color.opacity(0.6))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(.circle)

                            if selected.wrappedValue == matchColor {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(matchColor.color, lineWidth: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)

                }

                Button {
                    showingSheet = true
                } label: {
                    ZStack {
                        Color(.darkGray)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(.circle)
                            .opacity(0.5)

                        Image(systemName: "ellipsis")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .sheet(isPresented: $showingSheet) {
                    MatchTemplateColorPickerSheetView(selected: selected)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
            }
        }
        .onChange(of: selected.wrappedValue) {
            if showingColors.contains(selected.wrappedValue) { return }

            self.showingColors = [selected.wrappedValue] + self.showingColors.prefix(2)
        }
    }
}

struct MatchTemplateColorPickerSheetView: View {
    var selected: Binding<ScoreKeepMatchColor>

    var body: some View {
        ScrollView {
            LazyVGrid(columns: .init(repeating: GridItem(.flexible()), count: 4)) {
                ForEach(ScoreKeepMatchColor.allCases, id: \.self) { matchColor in
                    Button {
                        selected.wrappedValue = matchColor
                    } label: {
                        ZStack {
                            Color(matchColor.color.opacity(0.6))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(.circle)

                            if selected.wrappedValue == matchColor {
                                Image(systemName: "checkmark")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(matchColor.color, lineWidth: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(3)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        MatchTemplateCreateView()
            .environment(NavigationManager())
            .environment(
                ScoreKeepMatch(
                    .volleyball,
                    rules: ScoreKeepMatchRules(
                        winAt: 5,
                        setRules: ScoreKeepSetRules(
                            winAt: 6,
                            gameRules: ScoreKeepGameRules(
                                winAt: 25,
                                winBy: 2
                            )
                        )
                    )
                )
            )
    }
}
