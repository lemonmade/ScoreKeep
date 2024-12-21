//
//  SummaryView.swift
//  ScoreKeep Watch App
//
//  Created by Chris Sauve on 2024-12-10.
//

import SwiftUI

struct SummaryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                SummaryMetricView(title: "Total Time", value: durationFormatter.string(from: 30 * 60 + 15) ?? "")
                    .accentColor(Color.yellow)
                SummaryMetricView(title: "Total Distance", value: Measurement(value: 1625, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road)))
                    .accentColor(Color.green)
                SummaryMetricView(title: "Avg. Heart Rate", value: 143.formatted(.number.precision(.fractionLength(0))))
                    .accentColor(Color.red)
                Button("Done") {
                    dismiss()
                }
            }
            .scenePadding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String
    
    var body: some View {
        Text(title)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
            .foregroundColor(.accentColor)
        Divider()
    }
}

#Preview {
    SummaryView()
}
