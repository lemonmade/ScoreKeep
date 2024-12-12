//
//  ControlsView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var scoreKeeper: GameScoreKeeper
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    ForEach(scoreKeeper.sets) { (set) in
                        SetScoreView(set: set)
                    }
                }
                    .frame(maxWidth: .infinity)
                
                StartNewSetButton()
                    .environmentObject(scoreKeeper.latestSet)
                
                HStack {
                    VStack {
                        Button {
                            workoutManager.endWorkout()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .tint(Color.red)
                        .font(.title2)
                        Text("End")
                    }
                    VStack {
                        Button {
                            workoutManager.togglePause()
                        } label: {
                            Image(systemName: workoutManager.running ? "pause" : "play")
                        }
                        .tint(Color.yellow)
                        .font(.title2)
                        Text(workoutManager.running ? "Pause" : "Resume")
                    }
                }
            }
        }
    }
}

struct StartNewSetButton: View {
    @EnvironmentObject var scoreKeeper: GameScoreKeeper
    @EnvironmentObject var set: GameSet
    
    var body: some View {
        Button {
            scoreKeeper.startNewSet()
        } label: {
            Text("Start Set \(set.number + 1)").frame(maxWidth: .infinity)
        }
            .disabled((set.team0Score + set.team1Score) == 0)
            .foregroundStyle((set.team0Score + set.team1Score) == 0 ? .secondary : .primary)
    }
}

struct SetScoreView: View {
    @StateObject var set: GameSet
    
    var body: some View {
        Text("Set \(set.number), \(set.team0Score) - \(set.team1Score)")
    }
}

#Preview {
    ControlsView()
        .environmentObject(WorkoutManager())
        .environmentObject(GameScoreKeeper())
}
