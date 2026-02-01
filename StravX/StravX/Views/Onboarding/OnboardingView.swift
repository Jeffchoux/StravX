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

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Bienvenue
            welcomePage.tag(0)

            // Page 2: Choix de pseudo
            usernamePage.tag(1)

            // Page 3: Comment jouer
            howToPlayPage.tag(2)
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
            username: username.isEmpty ? "Joueur" : username
        )

        modelContext.insert(user)
        try? modelContext.save()

        // Marquer l'onboarding comme terminé
        hasCompletedOnboarding = true

        dismiss()
    }
}

// MARK: - Supporting Views

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
