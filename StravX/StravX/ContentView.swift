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
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""
    @State private var showingErrorMessage = false
    @State private var errorMessage = ""

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
        .overlay(alignment: .top) {
            if showingSuccessMessage {
                SuccessToast(message: successMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
        .overlay(alignment: .top) {
            if showingErrorMessage {
                ErrorToast(message: errorMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showingErrorMessage = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ deepLink: DeepLink) {
        guard deepLink != .none else { return }

        print("🎯 [ContentView] Handling deep link: \(deepLink)")

        // Rejoindre automatiquement SANS demander confirmation
        let teamManager = TeamManager(modelContext: modelContext)

        switch deepLink {
        case .joinTeam(let code):
            print("🏃 [ContentView] Auto-joining team with code: \(code)")
            selectedTab = 4 // Switch to Teams tab

            let result = teamManager.joinTeam(code: code)

            if result.success {
                AppLogger.info("\(AppLogger.success) Team joined automatically via deep link", category: AppLogger.team)
                withAnimation {
                    successMessage = "✅ Vous avez rejoint la team!"
                    showingSuccessMessage = true
                }
            } else {
                AppLogger.warning("\(AppLogger.failure) Failed to join team: \(result.message)", category: AppLogger.team)
                withAnimation {
                    errorMessage = "❌ \(result.message)"
                    showingErrorMessage = true
                }
            }

        case .joinCompetition(let id):
            print("🏆 [ContentView] Auto-joining competition with id: \(id)")
            selectedTab = 4 // Switch to Teams tab

            withAnimation {
                successMessage = "✅ Vous avez rejoint la compétition!"
                showingSuccessMessage = true
            }

            AppLogger.info("Competition join: \(id)", category: AppLogger.ui)

        case .none:
            break
        }

        // Clear deep link after processing
        deepLinkHandler.clearDeepLink()
    }
}

// MARK: - Toast Components

struct SuccessToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding(.horizontal)
            .padding(.top, 50)
    }
}

struct ErrorToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding(.horizontal)
            .padding(.top, 50)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Activity.self], inMemory: true)
}
