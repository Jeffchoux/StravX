//
//  CreateTeamView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct CreateTeamView: View {
    @Environment(\.dismiss) private var dismiss
    let teamManager: TeamManager

    @State private var teamName = ""
    @State private var showingSuccess = false
    @State private var createdTeam: Team?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "person.3.fill")
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
                    Text("Nom de la team")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("Ex: Team Rocket", text: $teamName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            createTeam()
                        }

                    Text("Choisissez un nom sympa pour votre équipe ! Vous recevrez un code unique à partager avec vos amis.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Create Button
                Button {
                    createTeam()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Créer la team")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: teamName.isEmpty ? [.gray] : [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(teamName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Créer une Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert("Team Créée !", isPresented: $showingSuccess) {
                Button("Partager le code") {
                    shareTeamCode()
                }
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let team = createdTeam {
                    Text("Votre team '\(team.name)' a été créée avec succès !\n\nCode d'invitation : \(team.code)\n\nPartagez ce code avec vos amis pour qu'ils puissent rejoindre votre team.")
                }
            }
        }
    }

    // MARK: - Actions

    private func createTeam() {
        guard !teamName.isEmpty else { return }

        if let team = teamManager.createTeam(name: teamName) {
            createdTeam = team
            showingSuccess = true
        }
    }

    private func shareTeamCode() {
        guard let team = createdTeam else { return }

        let message = """
        Rejoins ma team StravX ! 🏃‍♂️

        Team : \(team.name)
        Code : \(team.code)

        Télécharge StravX et utilise ce code pour nous rejoindre !
        """

        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        dismiss()
    }
}

#Preview {
    CreateTeamView(teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext))
}

// MARK: - Preview Container

class PreviewContainer {
    static let shared = PreviewContainer()

    let modelContext: ModelContext

    private init() {
        let schema = Schema([
            User.self,
            Team.self,
            Competition.self,
            Activity.self,
            Territory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = container.mainContext
    }
}
