//
//  MatchTemplateCreateView.swift
//  ScoreKeep iOS App
//
//  Created by Chris Sauve on 2025-01-29.
//

import ScoreKeepCore
import SwiftUI

struct MatchTemplateCreateView: View {
    var template: ScoreKeepMatchTemplate?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var sport: ScoreKeepSport
    @State private var environment: ScoreKeepActivityEnvironment
    @State private var color: ScoreKeepMatchColor

    init(template: ScoreKeepMatchTemplate? = nil) {
        self.template = template
        let sport = template?.sport ?? .volleyball
        self.sport = sport
        self.name = template?.name ?? sport.label
        self.environment = template?.environment ?? .indoor
        self.color = template?.color ?? .green
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)

                    Picker("Sport", selection: $sport) {
                        ForEach(ScoreKeepSport.allCases, id: \.self) { sport in
                            Label {
                                Text(sport.label)
                            } icon: {
                                Image(systemName: sport.figureIcon)
                            }
                            .tag(sport)
                        }
                    }

                    Picker("Environment", selection: $environment) {
                        Text("Indoor").tag(ScoreKeepActivityEnvironment.indoor)
                        Text("Outdoor").tag(ScoreKeepActivityEnvironment.outdoor)
                    }

                    MatchTemplateColorPickerView(selected: $color)
                }

                Section {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Text(template == nil ? "Create Template" : "Save Changes")
                            .frame(maxWidth: .infinity)
                    }

                    if let template, template.lastUsedAt != nil {
                        Button(role: .destructive) {
                            context.delete(template)
                            try? context.save()
                            dismiss()
                        } label: {
                            Text("Delete Template")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveAndDismiss() {
        if let template {
            // Update existing template
            template.name = name
            template.sport = sport
            template.environment = environment
            template.color = color

            if template.hasChanges {
                try? context.save()
            }
        } else {
            // Create new template
            let newTemplate = ScoreKeepMatchTemplate(
                sport,
                name: name,
                color: color,
                environment: environment
            )
            context.insert(newTemplate)
            try? context.save()
        }

        dismiss()
    }
}

struct MatchTemplateColorPickerView: View {
    @Binding var selected: ScoreKeepMatchColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ScoreKeepMatchColor.allCases, id: \.self) { matchColor in
                    Button {
                        selected = matchColor
                    } label: {
                        ZStack {
                            Circle()
                                .fill(matchColor.color.opacity(0.6))
                                .frame(width: 44, height: 44)

                            if selected == matchColor {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Circle()
                                    .strokeBorder(matchColor.color, lineWidth: 3)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    MatchTemplateCreateView()
        .modelContainer(ScoreKeepModelContainer().testModelContainer())
}
