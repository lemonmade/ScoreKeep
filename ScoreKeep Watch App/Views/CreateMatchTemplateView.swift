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
    }
    
    private var isMultiSet: Bool {
        return setsWinAt > 1
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField("Name", text: $name)
                
                MatchTemplateColorPickerView(selected: $color)

                Picker("Environment", selection: $environment) {
                    Text("Indoor").tag(MatchEnvironment.indoor)
                    Text("Outdoor").tag(MatchEnvironment.outdoor)
                }
                .pickerStyle(.navigationLink)
                
                Divider()
                
                VStack {
                    Text("Games to win")
                    
                    Stepper(value: $gamesWinAt, in: 1...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gamesWinAt)").fontWeight(.bold)
                            Text(" games")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                }
                
                Picker("After win", selection: $gamesPlayItOut) {
                    Text("Play it out").tag(true)
                    Text("End \(isMultiSet ? "set" : "match")").tag(false)
                }
                .pickerStyle(.navigationLink)
                
                Divider()
                
                Text("Game scoring")
                    .font(.headline)
                
                VStack {
                    Text("Win at")
                    
                    Stepper(value: $gameScoringWinScore, in: 1...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinScore)").fontWeight(.bold)
                            Text(" points")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                    .onChange(of: gameScoringWinScore) {
                        if gameScoringWinScore > gameScoringMaximumScore {
                            gameScoringMaximumScore = gameScoringWinScore
                        }
                    }
                }
                
                VStack {
                    Text("Maximum score")

                    Stepper(value: $gameScoringMaximumScore, in: gameScoringWinScore...50, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringMaximumScore)").fontWeight(.bold)
                            Text(" points")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                    .onChange(of: gameScoringMaximumScore) {
                        if gameScoringWinScore > gameScoringMaximumScore {
                            gameScoringWinScore = gameScoringMaximumScore
                        }
                    }
                }
                
                VStack {
                    Text("Win by")

                    Stepper(value: $gameScoringWinBy, in: 1...10, step: 1) {
                        HStack(spacing: 0) {
                            Text("\(gameScoringWinBy)").fontWeight(.bold)
                            Text(" points")
                        }
                            .font(.title3)
                            .monospacedDigit()
                    }
                }
                
                VStack {
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
                            
                            navigation.navigate(to: NavigationLocation.ActiveMatch(template: template))
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
                            navigation.navigate(to: NavigationLocation.ActiveMatch(template: template))
                        }
                    } label: {
                        Text("Start")
                    }
                    .tint(.green)
                    
                    if template != nil {
                        Button {
                            save(template: template!)
                            navigation.pop()
                        } label: {
                            Text("Save")
                        }
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
                        .tint(.red)
                    }
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
        Grid(horizontalSpacing: 0) {
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
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(matchColor.color, lineWidth: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(6)
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
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(.plain)
                .padding(6)
                .sheet(isPresented: $showingSheet) {
                    MatchTemplateColorPickerSheetView(selected: selected)
                }
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
    CreateMatchTemplateView()
        .environment(NavigationManager())
}
