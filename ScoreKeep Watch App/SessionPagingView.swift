//
//  SessionPagingView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selection: Tab = .metrics
    
    enum Tab {
        case controls, metrics, nowPlaying
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            MetricsView().tag(Tab.metrics)
            NowPlayingView().tag(Tab.nowPlaying)
        }
        .navigationTitle(workoutManager.selectedWorkout?.name ?? "")
        .navigationBarHidden(selection == .nowPlaying)
        .onChange(of: workoutManager.running) { _ in displayMetricsView() }
    }
    
    private func displayMetricsView() {
        withAnimation {
            selection = .metrics
        }
    }
}

#Preview {
    SessionPagingView()
}
