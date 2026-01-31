//
//  OnboardingView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0
    @State private var username = ""
    @State private var selectedTeam: TeamColor = .blue

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Bienvenue
            welcomePage.tag(0)

            // Page 2: Choix de pseudo
            usernamePage.tag(1)

            // Page 3: Choix d'équipe
            teamSelectionPage.tag(2)

            // Page 4: Comment jouer
            howToPlayPage.tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "map.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 16) {
                Text("Bienvenue sur StravX")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Transforme chaque course en conquête territoriale !")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                withAnimation {
                    currentPage = 1
                }
            } label: {
                Text("Commencer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Username Page

    private var usernamePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("Choisis ton pseudo")
                    .font(.title)
                    .fontWeight(.bold)

                TextField("Pseudo", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)
                    .textInputAutocapitalization(.words)
            }

            Spacer()

            Button {
                if !username.isEmpty {
                    withAnimation {
                        currentPage = 2
                    }
                }
            } label: {
                Text("Suivant")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(username.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(username.isEmpty)
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Team Selection Page

    private var teamSelectionPage: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Rejoins une équipe")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choisis ta couleur et domine la ville !")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                TeamCard(team: .red, isSelected: selectedTeam == .red) {
                    selectedTeam = .red
                }

                TeamCard(team: .blue, isSelected: selectedTeam == .blue) {
                    selectedTeam = .blue
                }

                TeamCard(team: .green, isSelected: selectedTeam == .green) {
                    selectedTeam = .green
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation {
                    currentPage = 3
                }
            } label: {
                Text("Suivant")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - How To Play Page

    private var howToPlayPage: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Text("Comment jouer ?")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 16) {
                    HowToItem(icon: "figure.run", text: "Démarre une activité et bouge")
                    HowToItem(icon: "map.fill", text: "Capture les zones que tu traverses")
                    HowToItem(icon: "star.fill", text: "Gagne de l'XP et monte de niveau")
                    HowToItem(icon: "flag.fill", text: "Défends tes territoires contre les adversaires")
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            Button {
                createUserAndFinish()
            } label: {
                Text("C'est parti !")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Actions

    private func createUserAndFinish() {
        // Créer l'utilisateur
        let user = User(
            username: username.isEmpty ? "Joueur" : username,
            teamColor: selectedTeam
        )

        modelContext.insert(user)
        try? modelContext.save()

        // Marquer l'onboarding comme terminé
        hasCompletedOnboarding = true

        dismiss()
    }
}

// MARK: - Supporting Views

struct TeamCard: View {
    let team: TeamColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(team.color)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(team.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Rejoindre l'équipe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(team.color)
                }
            }
            .padding()
            .background(isSelected ? team.color.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? team.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct HowToItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            Text(text)
                .font(.body)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .modelContainer(for: [User.self], inMemory: true)
}
