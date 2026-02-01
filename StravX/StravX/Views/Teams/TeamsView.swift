//
//  TeamsView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct TeamsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var teamManager: TeamManager?
    @State private var showingCreateTeam = false
    @State private var showingJoinTeam = false

    var body: some View {
        NavigationStack {
            Group {
                if let teamManager = teamManager {
                    if teamManager.myTeams.isEmpty {
                        emptyStateView
                    } else {
                        teamListView(teamManager: teamManager)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Mes Teams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingCreateTeam = true
                        } label: {
                            Label("Créer une team", systemImage: "plus.circle.fill")
                        }

                        Button {
                            showingJoinTeam = true
                        } label: {
                            Label("Rejoindre avec un code", systemImage: "number.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTeam) {
                if let teamManager = teamManager {
                    CreateTeamView(teamManager: teamManager)
                }
            }
            .sheet(isPresented: $showingJoinTeam) {
                if let teamManager = teamManager {
                    JoinTeamView(teamManager: teamManager)
                }
            }
            .onAppear {
                if teamManager == nil {
                    teamManager = TeamManager(modelContext: modelContext)
                }
                teamManager?.loadMyTeams()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Aucune Team")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Créez votre première team ou rejoignez celle d'un ami !")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 16) {
                Button {
                    showingCreateTeam = true
                } label: {
                    Label("Créer une team", systemImage: "plus.circle.fill")
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

                Button {
                    showingJoinTeam = true
                } label: {
                    Label("Rejoindre avec un code", systemImage: "number.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }

                NavigationLink(destination: CompetitionsView()) {
                    Label("Voir les compétitions", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Team List

    private func teamListView(teamManager: TeamManager) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Competitions Button
                NavigationLink(destination: CompetitionsView()) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .frame(width: 50, height: 50)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Compétitions")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Défiez vos amis et votre team !")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                // Teams List
                ForEach(teamManager.myTeams, id: \.id) { team in
                    NavigationLink(destination: TeamDetailView(team: team, teamManager: teamManager)) {
                        TeamCard(team: team, teamManager: teamManager)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - Team Card

struct TeamCard: View {
    let team: Team
    let teamManager: TeamManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    HStack(spacing: 4) {
                        Image(systemName: "number.circle.fill")
                            .font(.caption)
                        Text(team.code)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            // Stats
            HStack(spacing: 20) {
                StatItem(
                    icon: "person.fill",
                    value: "\(team.memberCount)/\(team.maxMembers)",
                    label: "Membres"
                )

                StatItem(
                    icon: "map.fill",
                    value: String(format: "%.1f", team.totalDistance / 1000),
                    label: "km"
                )

                StatItem(
                    icon: "figure.run",
                    value: "\(team.totalActivities)",
                    label: "Activités"
                )
            }

            // Creator badge
            if let currentUser = teamManager.getCurrentUser(),
               team.creatorID == currentUser.id.uuidString {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text("Créateur")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            .foregroundColor(.blue)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TeamsView()
        .modelContainer(for: [Team.self, User.self], inMemory: true)
}
