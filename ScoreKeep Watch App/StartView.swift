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
    
    var workoutTypes: [HKWorkoutActivityType] = [.volleyball]

    var body: some View {
        List(workoutTypes) { workoutType in
            NavigationLink(
                workoutType.name,
                destination: SessionPagingView(),
                tag: workoutType,
                selection: $workoutManager.selectedWorkout
            ).padding(
                EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
            )
        }
        .listStyle(.carousel)
        .navigationBarTitle("Workouts")
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}

extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }

    var name: String {
        switch self {
        case .volleyball:
            return "Volleyball"
        default:
            return ""
        }
    }
}

#Preview {
    StartView()
}
