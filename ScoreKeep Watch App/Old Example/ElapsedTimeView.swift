//
//  ElapsedTimeView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI

struct ElapsedTimeView: View {
    var elapsedTime: TimeInterval = 0
    var showSubseconds: Bool = true

    @State private var timeFormatter = ElapsedTimeFormatter()

    var body: some View {
        Text(
            NSNumber(value: elapsedTime),
            formatter: timeFormatter
        )
        .fontWeight(.semibold)
        .onChange(of: showSubseconds) {
            timeFormatter.showSubseconds = $0
        }
    }
}

class ElapsedTimeFormatter: Formatter {
    let componentsFormatter: DateComponentsFormatter = {
       let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var showSubseconds = true
    
    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else { return nil }

        guard let formattedString = componentsFormatter.string(from: time) else { return nil }
        
        if showSubseconds {
            let hundredths = Int(time.truncatingRemainder(dividingBy: 1) * 100)
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            return String(format: "%@%@%0.2d", formattedString, decimalSeparator, hundredths)
        }
        
        return formattedString
    }
}

#Preview {
    ElapsedTimeView(elapsedTime: 3 * 60 + 15.24, showSubseconds: true)
}