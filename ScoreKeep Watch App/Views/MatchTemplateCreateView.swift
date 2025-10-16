//
//  MatchTemplateCreateView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI

struct MatchTemplateCreateView: View {
    var template: MatchTemplate? = nil

    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var navigation
    
    @State private var name: String
    @State private var sport: MatchSport
    @State private var environment: MatchEnvironment
    @State private var color: MatchTemplateColor
    
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
    
    @State private var navigationTitle: String
    
    init(template: MatchTemplate? = nil) {
        self.template = template
        self.name = template?.name ?? "Volleyball"
        self.sport = template?.sport ?? .volleyball
        self.environment = template?.environment ?? .indoor
        self.color = template?.color ?? .green
        
        let setsWinAt = template?.scoring.winAt ?? 1
        let gameScoringWinScore = template?.scoring.setScoring.gameScoring.winAt ?? 25
        let gameScoringWinBy = template?.scoring.setScoring.gameScoring.winBy ?? 2
        
        self.setsWinAt = setsWinAt
        self.isMultiSet = setsWinAt > 1
        self.setsPlayItOut = template?.scoring.playItOut ?? false
        self.gamesWinAt = template?.scoring.setScoring.winAt ?? 3
        self.gamesPlayItOut = template?.scoring.setScoring.playItOut ?? false
        self.gameScoringWinScore = gameScoringWinScore
        self.gameScoringWinBy = gameScoringWinBy
        self.gameScoringMaximumScore = template?.scoring.setScoring.gameScoring.maximum ?? (gameScoringWinScore + gameScoringWinBy)
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
                    Label("Squash", systemImage: "circle.fill")
                        .tag(MatchSport.squash)

                    Label("Ultimate", systemImage: "circle.circle.fill")
                        .tag(MatchSport.ultimate)

                    Label("Volleyball", systemImage: "volleyball.fill")
                        .tag(MatchSport.volleyball)
                }
                
                MatchTemplateColorPickerView(selected: $color)
                    .listRowBackground(EmptyView())
                
                Picker("Environment", selection: $environment) {
                    Text("Indoor").tag(MatchEnvironment.indoor)
                    Text("Outdoor").tag(MatchEnvironment.outdoor)
                }
                .pickerStyle(.navigationLink)
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
                        let template = MatchTemplate(
                            .volleyball,
                            name: name,
                            color: color,
                            environment: environment,
                            scoring: asScoringRules(),
                            warmup: asWarmupRules(),
                            startWorkout: startWorkout
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
    }
    
    private func asScoringRules() -> MatchScoringRules {
        return MatchScoringRules(
            winAt: setsWinAt,
            winBy: 1,
            maximum: setsWinAt,
            playItOut: setsPlayItOut,
            setScoring: MatchSetScoringRules(
                winAt: gamesWinAt,
                winBy: 1,
                maximum: gamesWinAt,
                playItOut: gamesPlayItOut,
                gameScoring: MatchGameScoringRules(
                    winAt: gameScoringWinScore,
                    winBy: gameScoringWinBy,
                    maximum: gameScoringMaximumScore
                )
            )
        )
    }
    
    private func asWarmupRules() -> MatchWarmupRules {
        return hasWarmup ? .open : .none
    }
    
    private func save(template: MatchTemplate) {
        let newScoringRules = asScoringRules()
        
        if template.name != name {
            template.name = name
        }
        
        if template.sport != sport {
            template.sport = sport
        }
        
        if template.color != color {
            template.color = color
        }
        
        if template.scoring != newScoringRules {
            template.scoring = newScoringRules
        }
        
        if template.startWorkout != startWorkout {
            template.startWorkout = startWorkout
        }
        
        let warmup = asWarmupRules()
        if template.warmup != warmup {
            template.warmup = warmup
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

struct MatchTemplateColorPickerView: View {
    var selected: Binding<MatchTemplateColor>
    @State private var showingSheet: Bool = false
    @State private var showingColors: [MatchTemplateColor]
    
    init(selected: Binding<MatchTemplateColor>) {
        self.selected = selected
        
        let firstThreeColors = MatchTemplateColor.allCases.prefix(3)
        
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
    var selected: Binding<MatchTemplateColor>
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: .init(repeating: GridItem(.flexible()), count: 4)) {
                ForEach(MatchTemplateColor.allCases, id: \.self) { matchColor in
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
                Match(
                    .volleyball,
                    scoring: MatchScoringRules(
                        winAt: 5,
                        setScoring: MatchSetScoringRules(
                            winAt: 6,
                            gameScoring: MatchGameScoringRules(
                                winAt: 25,
                                winBy: 2
                            )
                        )
                    )
                )
            )
    }
}
