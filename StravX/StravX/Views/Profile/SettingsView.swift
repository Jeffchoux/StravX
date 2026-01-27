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
    @State private var showingDeleteConfirmation = false
    @Query private var activities: [Activity]

    var body: some View {
        NavigationStack {
            List {
                Section("Unités") {
                    Picker("Distance", selection: $distanceUnit) {
                        Text("Kilomètres").tag("km")
                        Text("Miles").tag("mi")
                    }
                }

                Section("Informations") {
                    Link(destination: URL(string: "https://github.com/stravx/privacy")!) {
                        HStack {
                            Label("Politique de confidentialité", systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/stravx/terms")!) {
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
                    Link(destination: URL(string: "mailto:support@stravx.app")!) {
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
        }
    }
}

#Preview {
    SettingsView()
}
