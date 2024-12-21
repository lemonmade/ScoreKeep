//
//  GameControlsView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct GameControlsView: View {
    var body: some View {
        ScrollView {
            HStack {
                GameControlsEndGameView()

                GameControlsPauseGameView()
            }
        }
    }
}

struct GameControlsEndGameView: View {
    @Environment(GameNavigationManager.self) private var gameNavigation
    
    var body: some View {
        VStack {
            Button {
                gameNavigation.end()
            } label: {
                Image(systemName: "xmark")
            }
            .tint(.red)
            .font(.title2)

            Text("End")
        }
    }
}

struct GameControlsPauseGameView: View {
    var body: some View {
        VStack {
            Button {
                print("Pausing game...")
            } label: {
                Image(systemName: "pause")
            }
            .tint(.yellow)
            .font(.title2)
            .disabled(true)

            Text("Pause")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    GameControlsView()
}
