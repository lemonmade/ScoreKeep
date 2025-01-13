//
//  ActiveMatchActivityView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct ActiveMatchActivityViewWithData: View {
    @Environment(WorkoutManager.self) var workoutManager
    
    var body: some View {
        VStack {
            VStack {
                Text("Heart rate")
                Text(workoutManager.workout?.heartRate == nil ? "-" : workoutManager.workout!.heartRate!.description)
            }
            
            VStack {
                Text("Average heart rate")
                Text(workoutManager.workout?.averageHeartRate == nil ? "-" : workoutManager.workout!.averageHeartRate!.description)
            }
            
            VStack {
                Text("Active energy")
                Text(workoutManager.workout?.activeEnergy == nil ? "-" : workoutManager.workout!.activeEnergy!.description)
            }
            
            VStack {
                Text("Distance")
                Text(workoutManager.workout?.distance == nil ? "-" : workoutManager.workout!.distance!.description)
            }
        }
        .scenePadding()
    }
}

struct ActiveMatchActivityViewEmptyState: View {
    var body: some View {
        Text("No workout was started for this match")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .scenePadding()
    }
}

struct ActiveMatchActivityView: View {
    @Environment(WorkoutManager.self) var workoutManager: WorkoutManager
    
    var body: some View {
        if workoutManager.workout == nil {
            ActiveMatchActivityViewEmptyState()
        } else {
            ActiveMatchActivityViewWithData()
        }
    }
}

#Preview {
    ActiveMatchActivityView()
        .environment(WorkoutManager())
}
