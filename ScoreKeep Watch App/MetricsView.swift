//
//  SessionPagingView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selection: Tab = .metrics

    enum Tab {
        case controls, metrics, nowPlaying
    }

    var body: some View {
        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date())) { context in
            VStack(alignment: .leading) {
                ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime ?? 0, showSubseconds: context.cadence == .live)
                    .foregroundColor(Color.yellow)
                    .fontWeight(.semibold)
                Text(
                    Measurement(value: workoutManager.activeEnergy, unit: UnitEnergy.kilocalories)
                        .formatted(
                            .measurement(
                                width: .abbreviated,
                                usage: .workout,
                                numberFormatStyle: .number
                            )
                        )
                )
                Text(
                    workoutManager.heartRate.formatted(.number) + " bpm"
                )
                Text(
                    Measurement(
                        value: workoutManager.distance,
                        unit: UnitLength.meters
                    ).formatted(
                        .measurement(width: .abbreviated, usage: .road)
                    )
                )
            }
            .font(
                .system(.title, design: .rounded)
                .monospacedDigit()
                .lowercaseSmallCaps()
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
        }
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    
    init(from startDate: Date) {
        self.startDate = startDate
    }
    
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(from: self.startDate, by: mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
                .entries(from: startDate, mode: mode)
    }
}

#Preview {
    MetricsView()
}
