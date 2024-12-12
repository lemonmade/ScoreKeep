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
    @State private var selection: Tab = .scoring
    @StateObject private var scoreKeeper = GameScoreKeeper()
    
    enum Tab {
        case controls, metrics, nowPlaying, scoring
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
//            MetricsView().tag(Tab.metrics)
            TabView {
                GameScoreView()
                MetricsView()
            }
                .tabViewStyle(.verticalPage)
                .tag(Tab.scoring)
//                .navigationTitle("Set 1")
//                .navigationBarTitleDisplayMode(.inline)
            NowPlayingView().tag(Tab.nowPlaying)
        }
//        .navigationTitle(workoutManager.selectedWorkout?.name ?? "")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(selection == .nowPlaying)
//        .onChange(of: workoutManager.running) { _ in displayMetricsView() }
        .environmentObject(scoreKeeper)
    }
    
    private func displayScoringView() {
        withAnimation {
            selection = .scoring
        }
    }
    
    private func displayMetricsView() {
        withAnimation {
            selection = .metrics
        }
    }
}

#Preview {
    SessionPagingView()
        .environmentObject(WorkoutManager())
}
