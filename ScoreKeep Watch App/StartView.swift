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
        List(selection: $workoutManager.selectedWorkout) {
            ForEach(workoutTypes) { workoutType in
                NavigationLink {
                    SessionPagingView()
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Image(systemName: "figure.volleyball")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                        Text(workoutType.name)
                            .font(.headline)
                        Text("Best-of-5, first to 25")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                }
                .padding(
                        EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
                    )
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.green.opacity(0.2))
                )
            }
            NavigationLink {
                GameTemplateCreateView()
            } label: {
                Text("New game rules")
                    .frame(maxWidth: .infinity)
            }
            NavigationLink {
                GameHistoryView()
            } label: {
                Text("Game history")
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.carousel)
        .navigationBarTitle("ScoreKeep")
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
            return "Indoor volleyball"
        default:
            return ""
        }
    }
}

#Preview {
    StartView()
        .environmentObject(WorkoutManager())
}
