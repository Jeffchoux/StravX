//
//  ContentView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(DeepLinkHandler.self) private var deepLinkHandler
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 1
    @State private var showingDeepLinkAlert = false
    @State private var deepLinkMessage = ""
    @State private var teamCodeToJoin: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label("Carte", systemImage: "map")
                }
                .tag(0)

            ActivityView()
                .tabItem {
                    Label("Activité", systemImage: "figure.run")
                }
                .tag(1)

            ConquestView()
                .tabItem {
                    Label("Territoires", systemImage: "flag.fill")
                }
                .tag(2)

            FriendsView()
                .tabItem {
                    Label("Amis", systemImage: "person.2.fill")
                }
                .tag(3)

            TeamsView()
                .tabItem {
                    Label("Teams", systemImage: "person.3.fill")
                }
                .tag(4)

            EnhancedProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
                .tag(5)
        }
        .accentColor(.orange)
        .onChange(of: deepLinkHandler.activeDeepLink) { _, newValue in
            handleDeepLink(newValue)
        }
        .alert("Rejoindre via lien", isPresented: $showingDeepLinkAlert) {
            Button("Annuler", role: .cancel) {
                deepLinkHandler.clearDeepLink()
            }
            Button("Rejoindre") {
                processDeepLink()
            }
        } message: {
            Text(deepLinkMessage)
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .joinTeam(let code):
            teamCodeToJoin = code
            deepLinkMessage = "Voulez-vous rejoindre la team avec le code \(code) ?"
            showingDeepLinkAlert = true
            selectedTab = 4 // Switch to Teams tab

        case .joinCompetition(_):
            deepLinkMessage = "Voulez-vous rejoindre la compétition ?"
            showingDeepLinkAlert = true
            selectedTab = 4 // Switch to Teams tab

        case .none:
            break
        }
    }

    private func processDeepLink() {
        let teamManager = TeamManager(modelContext: modelContext)

        switch deepLinkHandler.activeDeepLink {
        case .joinTeam(let code):
            let result = teamManager.joinTeam(code: code)
            if result.success {
                AppLogger.info("\(AppLogger.success) Team joined via deep link", category: AppLogger.team)
            } else {
                AppLogger.warning("\(AppLogger.failure) Failed to join team: \(result.message)", category: AppLogger.team)
            }

        case .joinCompetition(_):
            // Handle competition join
            AppLogger.info("Competition join not yet implemented", category: AppLogger.ui)

        case .none:
            break
        }

        deepLinkHandler.clearDeepLink()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Activity.self], inMemory: true)
}
