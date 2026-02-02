//
//  JoinCompetitionView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct JoinCompetitionView: View {
    @Environment(\.dismiss) private var dismiss
    let teamManager: TeamManager

    @State private var code = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var joinedCompetition: Competition?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "trophy.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    Text("Rejoindre une compétition")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Entre le code de la compétition pour la rejoindre")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Code Input
                VStack(spacing: 12) {
                    Text("Code de la compétition")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("COMP-XXXX", text: $code)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 40)

                // Join Button
                Button {
                    joinCompetition()
                } label: {
                    Label("Rejoindre", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            code.isEmpty ?
                            AnyShapeStyle(Color.gray) :
                            AnyShapeStyle(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        )
                        .cornerRadius(12)
                }
                .disabled(code.isEmpty)
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Rejoindre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                if joinedCompetition != nil {
                    Button("Voir la compétition") {
                        dismiss()
                    }
                    Button("OK") {
                        dismiss()
                    }
                } else {
                    Button("OK") { }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func joinCompetition() {
        let result = teamManager.joinCompetition(code: code.uppercased())

        alertTitle = result.success ? "Succès !" : "Erreur"
        alertMessage = result.message
        joinedCompetition = result.competition
        showingAlert = true
    }
}

#Preview {
    JoinCompetitionView(teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext))
}
