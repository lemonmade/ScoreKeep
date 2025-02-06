//
//  ActiveMatchActivityView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct ActiveMatchActivityViewWithData: View {
    @Environment(Match.self) var match
    @Environment(WorkoutManager.self) var workoutManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            TimelineView(.periodic(from: match.startedAt, by: 0.1)) { context in
                Text(context.date, format: .stopwatch(startingAt: match.startedAt, maxPrecision: .seconds(1)))
                    .foregroundStyle(.yellow)
            }
            .border(.red)
            
            HStack(alignment: .center) {
                if let workout = workoutManager.workout {
                    Text(workout.activeEnergy.value, format: .number.precision(.fractionLength(0)))
                } else {
                    Text("--")
                }
                Text("Active \nCal")
                    .font(.title3.uppercaseSmallCaps())
                    .fontWeight(.medium)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(0)
                    .fixedSize()
                    .clipped()
            }
            .border(.red)
            
            HStack {
                if let heartRate = workoutManager.workout?.heartRate {
                    Text(heartRate, format: .number.precision(.fractionLength(0)))
                        .border(.red)
                } else {
                    Text("--")
                        .lineSpacing(0)
                        .border(.red)
                }
                
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .border(.red)
            }
            
            Text(workoutManager.workout?.distance ?? Measurement<UnitLength>(value: 0, unit: .meters), format: .measurement(width: .abbreviated, usage: .road))
                .border(.red)
        }
       
        .font(.system(size: 36, weight: .semibold, design: .rounded).monospacedDigit().lowercaseSmallCaps())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .ignoresSafeArea(edges: .bottom)
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
