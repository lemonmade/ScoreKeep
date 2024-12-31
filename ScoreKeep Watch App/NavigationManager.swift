//
//  GameNavigationManager.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-19.
//

import Foundation
import SwiftUI

protocol NavigationLocationProtocol : Hashable {}

struct NavigationLocation {
    struct TemplateCreate: NavigationLocationProtocol {
        var template: MatchTemplate? = nil
    }
    
    struct MatchHistoryDetail: NavigationLocationProtocol {
        var match: Match
    }

    struct MatchHistory: NavigationLocationProtocol {}
    struct ActiveMatch: NavigationLocationProtocol {
        var template: MatchTemplate
        
        enum Tab {
            case main
            case controls
            case nowPlaying
        }
    }
}

@Observable
class NavigationManager {
    var path = NavigationPath()
    var activeMatchTab: NavigationLocation.ActiveMatch.Tab = .main
    
    func navigate<V>(to location: V, replace: Bool = false) where V : NavigationLocationProtocol {
        if replace {
            path.removeLast()
        }

        path.append(location)
    }
    
    func pop(count: Int = 1) {
        path.removeLast([count, path.count].min()!)
    }
}
