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
    @Environment(\.modelContext) private var modelContext
    let teamManager: TeamManager

    @State private var competitionName = ""
    @State private var selectedType: CompetitionType = .individual
    @State private var selectedMetric: CompetitionMetric = .distance
    @State private var selectedDuration: DurationType = .week
    @State private var customDays = 7
    @State private var showingSuccess = false
    @State private var showingFriendSelection = false
    @State private var selectedFriends: Set<String> = []
    @State private var friendManager: FriendManager?

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

                // Invite Friends Section
                Section {
                    Button {
                        showingFriendSelection = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)

                            if selectedFriends.isEmpty {
                                Text("Inviter des amis")
                                    .foregroundColor(.primary)
                            } else {
                                Text("\(selectedFriends.count) ami\(selectedFriends.count > 1 ? "s" : "") sélectionné\(selectedFriends.count > 1 ? "s" : "")")
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Participants (optionnel)")
                } footer: {
                    Text("Les amis sélectionnés seront automatiquement ajoutés à la compétition")
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

                        if !selectedFriends.isEmpty {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.purple)
                                Text("Participants: \(selectedFriends.count + 1)") // +1 pour le créateur
                                    .fontWeight(.medium)
                            }
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
            .sheet(isPresented: $showingFriendSelection) {
                FriendSelectionView(selectedFriends: $selectedFriends, friendManager: friendManager)
            }
            .onAppear {
                if friendManager == nil {
                    friendManager = FriendManager(modelContext: modelContext)
                    friendManager?.loadFriends()
                }
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

        if let competition = teamManager.createCompetition(
            name: competitionName,
            type: selectedType,
            metric: selectedMetric,
            duration: competitionDuration
        ) {
            // Ajouter les amis sélectionnés
            for friendID in selectedFriends {
                _ = competition.addParticipant(friendID)
            }

            // Sauvegarder les modifications
            if !selectedFriends.isEmpty {
                try? modelContext.save()
            }

            showingSuccess = true
        }
    }
}

// MARK: - Friend Selection View

struct FriendSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFriends: Set<String>
    let friendManager: FriendManager?

    var body: some View {
        NavigationStack {
            Group {
                if let friendManager = friendManager, !friendManager.friends.isEmpty {
                    List {
                        ForEach(friendManager.friends) { friend in
                            Button {
                                toggleSelection(friend.id.uuidString)
                            } label: {
                                HStack {
                                    // Avatar
                                    ZStack {
                                        Circle()
                                            .fill(friend.color.opacity(0.2))
                                            .frame(width: 40, height: 40)

                                        Text(friend.username.prefix(2).uppercased())
                                            .font(.subheadline)
                                            .foregroundColor(friend.color)
                                    }

                                    // Name
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.username)
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        Text("Lvl \(friend.level)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // Checkmark
                                    if selectedFriends.contains(friend.id.uuidString) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("Aucun ami")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Ajoutez des amis pour les inviter à vos compétitions")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Inviter des amis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Valider") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func toggleSelection(_ friendID: String) {
        if selectedFriends.contains(friendID) {
            selectedFriends.remove(friendID)
        } else {
            selectedFriends.insert(friendID)
        }
    }
}

#Preview {
    CreateCompetitionView(teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext))
}
