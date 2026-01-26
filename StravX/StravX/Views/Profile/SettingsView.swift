//
//  SettingsView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

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
        }
    }
}

#Preview {
    SettingsView()
}
