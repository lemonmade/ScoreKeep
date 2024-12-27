//
//  GameMainView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct MatchMainView: View {
    var body: some View {
        TabView {
            GameScoreKeepView()
            
            MatchActivityMetricsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    MatchMainView()
}
