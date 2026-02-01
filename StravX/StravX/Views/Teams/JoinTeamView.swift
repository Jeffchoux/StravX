//
//  JoinTeamView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI

struct JoinTeamView: View {
    @Environment(\.dismiss) private var dismiss
    let teamManager: TeamManager

    @State private var teamCode = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var joinedSuccessfully = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)

                // Form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code d'invitation")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("STRVX-XXXX", text: $teamCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.join)
                        .onSubmit {
                            joinTeam()
                        }
                        .onChange(of: teamCode) { _, newValue in
                            // Format automatique
                            teamCode = newValue.uppercased()
                        }

                    Text("Entrez le code que votre ami vous a partagé pour rejoindre sa team.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Format hint
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("Format : STRVX-XXXX (ex: STRVX-A3B9)")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Join Button
                Button {
                    joinTeam()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.title3)
                        Text("Rejoindre")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: isValidCode ? [.blue, .purple] : [.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(!isValidCode)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Rejoindre une Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    if joinedSuccessfully {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var isValidCode: Bool {
        let pattern = "^STRVX-[A-Z0-9]{4}$"
        return teamCode.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Actions

    private func joinTeam() {
        guard isValidCode else {
            alertTitle = "Code invalide"
            alertMessage = "Le code doit être au format STRVX-XXXX"
            joinedSuccessfully = false
            showingAlert = true
            return
        }

        let result = teamManager.joinTeam(code: teamCode)

        if result.success {
            alertTitle = "Bienvenue !"
            alertMessage = result.message
            joinedSuccessfully = true
        } else {
            alertTitle = "Erreur"
            alertMessage = result.message
            joinedSuccessfully = false
        }

        showingAlert = true
    }
}

#Preview {
    JoinTeamView(teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext))
}
