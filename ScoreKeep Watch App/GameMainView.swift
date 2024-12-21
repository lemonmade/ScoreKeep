//
//  GameMainView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-18.
//

import SwiftUI

struct GameMainView: View {
    var body: some View {
        TabView {
            GameScoreKeepView()
            
            GameActivityMetricsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    GameMainView()
}
