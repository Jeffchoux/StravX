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

            TeamsView()
                .tabItem {
                    Label("Teams", systemImage: "person.3.fill")
                }
                .tag(3)

            EnhancedProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
                .tag(4)
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
            selectedTab = 3 // Switch to Teams tab

        case .joinCompetition(let id):
            deepLinkMessage = "Voulez-vous rejoindre la compétition ?"
            showingDeepLinkAlert = true
            selectedTab = 3 // Switch to Teams tab

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
                print("✅ Team joined via deep link")
            } else {
                print("❌ Failed to join team: \(result.message)")
            }

        case .joinCompetition(let id):
            // Handle competition join
            print("📲 Competition join not yet implemented")

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
