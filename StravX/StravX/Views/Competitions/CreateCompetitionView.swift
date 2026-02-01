//
//  CreateCompetitionView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct CreateCompetitionView: View {
    @Environment(\.dismiss) private var dismiss
    let teamManager: TeamManager

    @State private var competitionName = ""
    @State private var selectedType: CompetitionType = .individual
    @State private var selectedMetric: CompetitionMetric = .distance
    @State private var selectedDuration: DurationType = .week
    @State private var customDays = 7
    @State private var showingSuccess = false

    enum DurationType: String, CaseIterable {
        case day = "1 jour"
        case week = "1 semaine"
        case month = "1 mois"
        case infinite = "Infinie"
        case custom = "Personnalisé"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section {
                    TextField("Ex: Défi du mois", text: $competitionName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Nom de la compétition")
                }

                // Type Section
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach([CompetitionType.individual, CompetitionType.team], id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Type de compétition")
                } footer: {
                    Text(selectedType == .individual
                        ? "Chaque participant concourt individuellement"
                        : "Les participants sont regroupés en équipes")
                }

                // Metric Section
                Section {
                    Picker("Métrique", selection: $selectedMetric) {
                        ForEach([CompetitionMetric.distance, CompetitionMetric.activities, CompetitionMetric.territories, CompetitionMetric.xp], id: \.self) { metric in
                            Text(metric.displayName).tag(metric)
                        }
                    }
                } header: {
                    Text("Métrique de victoire")
                } footer: {
                    Text(metricFooter)
                }

                // Duration Section
                Section {
                    Picker("Durée", selection: $selectedDuration) {
                        ForEach(DurationType.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }

                    if selectedDuration == .custom {
                        Stepper("Durée: \(customDays) jour\(customDays > 1 ? "s" : "")", value: $customDays, in: 1...365)
                    }
                } header: {
                    Text("Durée de la compétition")
                } footer: {
                    Text(selectedDuration == .infinite
                        ? "La compétition n'a pas de date de fin"
                        : "La compétition se terminera automatiquement")
                }

                // Preview Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundColor(.blue)
                            Text(selectedType.displayName)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.orange)
                            Text("Métrique: \(selectedMetric.displayName)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.green)
                            Text("Durée: \(durationText)")
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Aperçu")
                }
            }
            .navigationTitle("Nouvelle Compétition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Créer") {
                        createCompetition()
                    }
                    .disabled(competitionName.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .alert("Compétition Créée !", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("La compétition '\(competitionName)' a été créée avec succès !")
            }
        }
    }

    // MARK: - Computed Properties

    private var metricFooter: String {
        switch selectedMetric {
        case .distance:
            return "Gagnant: celui qui parcourt la plus grande distance"
        case .activities:
            return "Gagnant: celui qui complète le plus d'activités"
        case .territories:
            return "Gagnant: celui qui capture le plus de zones"
        case .xp:
            return "Gagnant: celui qui gagne le plus d'XP"
        }
    }

    private var durationText: String {
        switch selectedDuration {
        case .day:
            return "1 jour"
        case .week:
            return "1 semaine (7 jours)"
        case .month:
            return "1 mois (30 jours)"
        case .infinite:
            return "Infinie"
        case .custom:
            return "\(customDays) jour\(customDays > 1 ? "s" : "")"
        }
    }

    private var competitionDuration: CompetitionDuration {
        switch selectedDuration {
        case .day:
            return .limited(days: 1)
        case .week:
            return .limited(days: 7)
        case .month:
            return .limited(days: 30)
        case .infinite:
            return .infinite
        case .custom:
            return .limited(days: customDays)
        }
    }

    // MARK: - Actions

    private func createCompetition() {
        guard !competitionName.isEmpty else { return }

        if let _ = teamManager.createCompetition(
            name: competitionName,
            type: selectedType,
            metric: selectedMetric,
            duration: competitionDuration
        ) {
            showingSuccess = true
        }
    }
}

#Preview {
    CreateCompetitionView(teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext))
}
