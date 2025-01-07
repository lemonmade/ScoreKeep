//
//  CreateMatchTemplateView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-17.
//

import SwiftUI

struct CreateMatchTemplateView: View {
    var template: MatchTemplate? = nil

    @Environment(\.modelContext) private var context
    @Environment(NavigationManager.self) private var navigation
    
    @State private var name: String
    @State private var environment: MatchEnvironment
    @State private var color: MatchTemplateColor
    
    @State private var setsWinAt: Int

    @State private var gamesWinAt: Int
    @State private var gamesPlayItOut: Bool
    
    @State private var gameScoringWinScore: Int
    @State private var gameScoringMaximumScore: Int
    @State private var gameScoringWinBy: Int
    
    @State private var startWorkout: Bool
    
    @State private var navigationTitle: String
    
    init(template: MatchTemplate? = nil) {
        self.template = template
        self.name = template?.name ?? "Volleyball"
        self.environment = template?.environment ?? .indoor
        self.color = template?.color ?? .green
        self.setsWinAt = template?.scoring.setsWinAt ?? 1
        self.gamesWinAt = template?.scoring.setScoring.gamesWinAt ?? 3
        self.gamesPlayItOut = template?.scoring.setScoring.playItOut ?? false
        self.gameScoringWinScore = template?.scoring.setScoring.gameScoring.winScore ?? 25
        self.gameScoringMaximumScore = template?.scoring.setScoring.gameScoring.maximumScore ?? 27
        self.gameScoringWinBy = template?.scoring.setScoring.gameScoring.winBy ?? 2
        self.navigationTitle = template == nil ? "New match" : template!.name
        self.startWorkout = template?.startWorkout ?? true
    }
    
    private var isMultiSet: Bool {
        return setsWinAt > 1
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                
                MatchTemplateColorPickerView(selected: $color)
                    .listRowBackground(EmptyView())
//                    .listRowInsets(EdgeInsets())
                
                Picker("Environment", selection: $environment) {
                    Text("Indoor").tag(MatchEnvironment.indoor)
                    Text("Outdoor").tag(MatchEnvironment.outdoor)
                }
                .pickerStyle(.navigationLink)
                
            }

            Section(header: Text("Games")) {
                VStack {
                    Text("Win at")
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
            }
                
            Section(header: Text("Points")) {
                VStack {
                    Text("Win at")
                    
                    Stepper(value: $gameScoringWinScore, in: 1...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinScore)")
                        }
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .onChange(of: gameScoringWinScore) {
                        if gameScoringWinScore > gameScoringMaximumScore {
                            gameScoringMaximumScore = gameScoringWinScore
                        }
                    }
                }
                .padding([.top, .bottom], 8)
                
                VStack {
                    Text("Max score")

                    Stepper(value: $gameScoringMaximumScore, in: gameScoringWinScore...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringMaximumScore)")
                        }
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .onChange(of: gameScoringMaximumScore) {
                        if gameScoringWinScore > gameScoringMaximumScore {
                            gameScoringWinScore = gameScoringMaximumScore
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
                }
                .padding([.top, .bottom], 8)
            }
            
            Section(header: Text("Workout")) {
                Toggle(isOn: $startWorkout) {
                    Text("Start workout")
                }
            }
            
            Section {
                Button {
                    let newScoringRules = MatchScoringRules(
                        setsWinAt: setsWinAt,
                        playItOut: false,
                        setScoring: MatchSetScoringRules(
                            gamesWinAt: gamesWinAt,
                            gamesMaximum: (gamesWinAt * 2) - 1,
                            playItOut: gamesPlayItOut,
                            gameScoring: MatchGameScoringRules(
                                winScore: gameScoringWinScore,
                                maximumScore: gameScoringMaximumScore,
                                winBy: gameScoringWinBy
                            )
                        )
                    )
                
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
                            scoring: newScoringRules
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
                
                if template != nil {
                    Button {
                        save(template: template!)
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
    
    private func save(template: MatchTemplate) {
        let newScoringRules = MatchScoringRules(
            setsWinAt: setsWinAt,
            setsMaximum: (setsWinAt * 2) - 1,
            playItOut: false,
            setScoring: MatchSetScoringRules(
                gamesWinAt: gamesWinAt,
                gamesMaximum: (gamesWinAt * 2) - 1,
                playItOut: gamesPlayItOut,
                gameScoring: MatchGameScoringRules(
                    winScore: gameScoringWinScore,
                    maximumScore: gameScoringMaximumScore,
                    winBy: gameScoringWinBy
                )
            )
        )
        
        if template.name != name {
            template.name = name
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
        CreateMatchTemplateView()
            .environment(NavigationManager())
    }
}
