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
    @State private var deepLinkHandler = DeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(deepLinkHandler)
                .onOpenURL { url in
                    let deepLink = deepLinkHandler.handleURL(url)
                    if deepLink != .none {
                        deepLinkHandler.activateDeepLink(deepLink)
                    }
                }
        }
        .modelContainer(for: [Activity.self, Territory.self, User.self, Team.self, Competition.self])
    }
}

/// Vue racine qui gère l'affichage de l'onboarding ou du contenu principal
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(colorScheme)
        .onAppear {
            // Vérifier si un utilisateur existe déjà (pour les mises à jour)
            checkExistingUser()
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil // Auto
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
