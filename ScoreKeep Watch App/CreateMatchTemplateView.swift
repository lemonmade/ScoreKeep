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
    
    
    @State private var name = "Volleyball"
    @State private var environment: MatchEnvironment = .indoor
    @State private var color: MatchTemplateColor = .green
    
    @State private var setsWinAt = 1

    @State private var gamesWinAt = 3
    @State private var gamesPlayItOut = false
    
    @State private var gameScoringWinScore = 25
    @State private var gameScoringMaximumScore = 27
    @State private var gameScoringWinBy = 1
    
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
                        if template.color != color {
                            template.color = color
                        }
                        
                        if template.scoring != newScoringRules {
                            template.scoring = newScoringRules
                        }
                        
                        // TODO?
                        if template.hasChanges {
                            try? context.save()
                        }
                        
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
        .navigationTitle("New match")
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
                            Color(matchColor.color)
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(.circle)
                            
                            if selected.wrappedValue == matchColor {
                                Image(systemName: "checkmark")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(matchColor.color, lineWidth: 2)
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
                            .opacity(0.75)
                        
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
                            Color(matchColor.color)
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(.circle)
                            
                            if selected.wrappedValue == matchColor {
                                Image(systemName: "checkmark")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.bold)
                                Circle()
                                    .inset(by: -3)
                                    .stroke(matchColor.color, lineWidth: 2)
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
