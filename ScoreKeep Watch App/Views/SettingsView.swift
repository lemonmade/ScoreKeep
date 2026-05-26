//
//  SettingsView.swift
//  ScoreKeep Watch App
//

import ScoreKeepUI
import SwiftUI

struct SettingsView: View {
    @AppStorage(ScoreDisplayStyle.storageKey)
    private var rawScoreStyle: String = ScoreDisplayStyle.default.rawValue

    private var scoreStyleBinding: Binding<ScoreDisplayStyle> {
        Binding(
            get: { ScoreDisplayStyle(rawValue: rawScoreStyle) ?? .default },
            set: { rawScoreStyle = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Score Display", selection: scoreStyleBinding) {
                    ForEach(ScoreDisplayStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.navigationLink)

                ScoreDisplayStylePreviewView(style: scoreStyleBinding.wrappedValue)
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
            } header: {
                Text("Appearance")
            }
        }
        .navigationTitle("Settings")
    }
}

private struct ScoreDisplayStylePreviewView: View {
    let style: ScoreDisplayStyle

    @State private var sampleValue: Int = 0
    @State private var task: Task<Void, Never>?

    private var label: String { "\(sampleValue)" }
    private var color: Color { ScoreKeepBrand.iconPurple }

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            GameScoreNumberView(
                label: label,
                transitionValue: Double(sampleValue),
                color: color,
                styleOverride: style
            )
            .foregroundStyle(color)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .id(style)
        .onAppear { startCycle() }
        .onDisappear { task?.cancel() }
        .onChange(of: style) { _, _ in
            sampleValue = 0
            startCycle()
        }
    }

    private func startCycle() {
        task?.cancel()
        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(900))
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation { sampleValue = (sampleValue + 1) % 22 }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
