//
//  StravXApp.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct StravXApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Activity.self, Territory.self, User.self])
    }
}

/// Vue racine qui gère l'affichage de l'onboarding ou du contenu principal
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .onAppear {
            // Vérifier si un utilisateur existe déjà (pour les mises à jour)
            checkExistingUser()
        }
    }

    private func checkExistingUser() {
        let descriptor = FetchDescriptor<User>()
        if let users = try? modelContext.fetch(descriptor), !users.isEmpty {
            // Un utilisateur existe déjà, skip l'onboarding
            hasCompletedOnboarding = true
        }
    }
}
