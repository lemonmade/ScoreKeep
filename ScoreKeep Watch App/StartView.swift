//
//  ContentView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import HealthKit
import SwiftUI

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    private let gameNavigation = GameNavigationManager()
    
    var body: some View {
        List {
            StartGameNavigationLinkView(name: "Indoor volleyball")
            
            StartGameRulesCreateLinkView()
        }
        .navigationBarTitle("ScoreKeep")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StartGameHistoryLinkView()
            }
        }
        .listStyle(.carousel)
        .onAppear {
            workoutManager.requestAuthorization()
        }
        .environment(gameNavigation)
    }
}

struct StartGameNavigationLinkView: View {
    var name: String
    @Environment(GameNavigationManager.self) private var gameNavigation
    
    var body: some View {
        @Bindable var gameNavigation = gameNavigation
        
        NavigationLink(isActive: $gameNavigation.isActive) {
            GameView()
                .environment(gameNavigation)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "figure.volleyball")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.headline)
                    Text("Best-of-5, first to 25")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            
        }
        .padding(
            EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
        )
        .tint(.green)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 20)
                .fill(.green.opacity(0.2))
        )
    }
}

struct StartGameHistoryLinkView: View {
    var body: some View {
        NavigationLink() {
            GameHistoryView()
        } label: {
            Image(systemName: "calendar")
        }
        .accessibilityLabel("Finished games")
    }
}

struct StartGameRulesCreateLinkView: View {
    var body: some View {
        NavigationLink {
            GameRulesCreateView()
        } label: {
            Text("New game")
                .frame(maxWidth: .infinity)
        }
    }
}


#Preview {
    StartView()
        .environmentObject(WorkoutManager())
}
