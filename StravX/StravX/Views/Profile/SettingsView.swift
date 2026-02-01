//
//  SettingsView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var showingDeleteConfirmation = false
    @State private var allowFollowers = true
    @State private var publicProfile = true
    @Query private var activities: [Activity]
    @Query private var users: [User]

    var body: some View {
        NavigationStack {
            List {
                Section("Apparence") {
                    Picker("Mode", selection: $appearanceMode) {
                        Label("Automatique", systemImage: "circle.lefthalf.filled")
                            .tag("auto")
                        Label("Clair", systemImage: "sun.max.fill")
                            .tag("light")
                        Label("Sombre", systemImage: "moon.fill")
                            .tag("dark")
                    }
                    .pickerStyle(.menu)
                }

                Section("Unités") {
                    Picker("Distance", selection: $distanceUnit) {
                        Text("Kilomètres").tag("km")
                        Text("Miles").tag("mi")
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Zones attaquées", systemImage: "bell.fill")
                    }

                    if notificationsEnabled {
                        Text("Recevez une notification quand vos zones sont attaquées")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Confidentialité") {
                    Toggle(isOn: $publicProfile) {
                        Label("Profil public", systemImage: "eye.fill")
                    }
                    .onChange(of: publicProfile) { _, newValue in
                        updateUserPrivacy()
                    }

                    Toggle(isOn: $allowFollowers) {
                        Label("Autoriser les followers", systemImage: "person.badge.plus.fill")
                    }
                    .onChange(of: allowFollowers) { _, newValue in
                        updateUserPrivacy()
                    }

                    if !allowFollowers {
                        Text("Les autres utilisateurs ne pourront pas suivre vos exploits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Informations") {
                    Link(destination: URL(string: "https://jeffchoux.github.io/StravX/privacy-policy.html")!) {
                        HStack {
                            Label("Politique de confidentialité", systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://jeffchoux.github.io/StravX/privacy-policy.html")!) {
                        HStack {
                            Label("Conditions d'utilisation", systemImage: "doc.text.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Support") {
                    Link(destination: URL(string: "mailto:contact@stravx.dev")!) {
                        HStack {
                            Label("Nous contacter", systemImage: "envelope.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Données") {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Label("Supprimer toutes les données", systemImage: "trash.fill")
                                .foregroundColor(.red)
                            Spacer()
                            Text("\(activities.count) activités")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("StravX")
                                .font(.headline)

                            Text("Votre compagnon sportif")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("© 2026 StravX. Tous droits réservés.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
            .alert("Supprimer toutes les données ?", isPresented: $showingDeleteConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    // Supprimer toutes les activités
                    for activity in activities {
                        modelContext.delete(activity)
                    }
                    do {
                        try modelContext.save()
                    } catch {
                        print("Erreur lors de la suppression: \(error)")
                    }
                }
            } message: {
                Text("Cette action est irréversible. Toutes vos activités seront définitivement supprimées.")
            }
            .onAppear {
                loadPrivacySettings()
            }
        }
    }

    // MARK: - Privacy Functions

    private func loadPrivacySettings() {
        if let user = users.first {
            allowFollowers = user.allowFollowers
            publicProfile = user.publicProfile
        }
    }

    private func updateUserPrivacy() {
        guard let user = users.first else { return }
        user.allowFollowers = allowFollowers
        user.publicProfile = publicProfile

        do {
            try modelContext.save()
            print("✅ Privacy settings updated")
        } catch {
            print("❌ Failed to update privacy settings: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
