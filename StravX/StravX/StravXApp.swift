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
                // Support Custom URL Schemes (stravx://)
                .onOpenURL { url in
                    print("📱 [StravXApp] onOpenURL: \(url.absoluteString)")
                    let deepLink = deepLinkHandler.handleURL(url)
                    if deepLink != .none {
                        deepLinkHandler.activateDeepLink(deepLink)
                    }
                }
                // Support Universal Links (https://)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    guard let url = userActivity.webpageURL else {
                        print("⚠️ [StravXApp] No webpage URL in user activity")
                        return
                    }
                    print("🌐 [StravXApp] Universal Link: \(url.absoluteString)")
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
    @AppStorage("pendingTeamCode") private var pendingTeamCode: String?
    @AppStorage("pendingCompetitionID") private var pendingCompetitionID: String?
    @Environment(\.modelContext) private var modelContext
    @Environment(DeepLinkHandler.self) private var deepLinkHandler

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
        .onChange(of: deepLinkHandler.activeDeepLink) { _, newValue in
            handlePendingDeepLink(newValue)
        }
        .onChange(of: hasCompletedOnboarding) { oldValue, newValue in
            // Quand l'onboarding est terminé, traiter le deep link en attente
            if newValue && !oldValue {
                processPendingDeepLink()
            }
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

    private func handlePendingDeepLink(_ deepLink: DeepLink) {
        guard deepLink != .none else { return }

        print("🔗 [RootView] Received deep link: \(deepLink)")

        // Si l'onboarding n'est pas terminé, sauvegarder le deep link pour plus tard
        if !hasCompletedOnboarding {
            print("⏳ [RootView] Onboarding not completed, saving deep link for later")
            switch deepLink {
            case .joinTeam(let code):
                pendingTeamCode = code
                print("💾 [RootView] Saved pending team code: \(code)")
            case .joinCompetition(let id):
                pendingCompetitionID = id
                print("💾 [RootView] Saved pending competition ID: \(id)")
            case .none:
                break
            }
        }
        // Sinon, ContentView va le gérer automatiquement
    }

    private func processPendingDeepLink() {
        print("🎯 [RootView] Onboarding completed, checking for pending deep links")

        // Attendre un peu que ContentView soit prêt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let teamCode = pendingTeamCode {
                print("✅ [RootView] Processing pending team code: \(teamCode)")
                deepLinkHandler.activateDeepLink(.joinTeam(code: teamCode))
                pendingTeamCode = nil
            } else if let competitionID = pendingCompetitionID {
                print("✅ [RootView] Processing pending competition ID: \(competitionID)")
                deepLinkHandler.activateDeepLink(.joinCompetition(id: competitionID))
                pendingCompetitionID = nil
            } else {
                print("ℹ️ [RootView] No pending deep links to process")
            }
        }
    }
}
