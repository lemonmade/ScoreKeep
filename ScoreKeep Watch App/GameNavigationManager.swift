//
//  GameNavigationManager.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-19.
//

import Foundation
import SwiftUI

enum GameNavigationTab {
    case controls, main, nowPlaying
}

@Observable
class GameNavigationManager {
    var tab: GameNavigationTab = .main
    var isActive = false
    
    func end() {
        print("Ending game...")
        isActive = false
    }
}
