//
//  CompetitionsView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct CompetitionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var teamManager: TeamManager?
    @State private var showingCreateCompetition = false
    @State private var selectedFilter: CompetitionFilter = .active

    enum CompetitionFilter: String, CaseIterable {
        case active = "En cours"
        case all = "Toutes"
        case ended = "Terminées"
    }

    var filteredCompetitions: [Competition] {
        guard let competitions = teamManager?.myCompetitions else { return [] }

        switch selectedFilter {
        case .active:
            return competitions.filter { $0.isActive && !$0.hasEnded }
        case .all:
            return competitions
        case .ended:
            return competitions.filter { $0.hasEnded }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let teamManager = teamManager {
                    if filteredCompetitions.isEmpty {
                        emptyStateView
                    } else {
                        competitionListView
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Compétitions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateCompetition = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingCreateCompetition) {
                if let teamManager = teamManager {
                    CreateCompetitionView(teamManager: teamManager)
                }
            }
            .onAppear {
                if teamManager == nil {
                    teamManager = TeamManager(modelContext: modelContext)
                }
                teamManager?.loadMyCompetitions()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Aucune Compétition")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Créez une compétition et défiez vos amis !")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showingCreateCompetition = true
            } label: {
                Label("Créer une compétition", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Competition List

    private var competitionListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filter Picker
                Picker("Filtre", selection: $selectedFilter) {
                    ForEach(CompetitionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Competition Cards
                ForEach(filteredCompetitions, id: \.id) { competition in
                    NavigationLink(destination: CompetitionDetailView(competition: competition, teamManager: teamManager!)) {
                        CompetitionCard(competition: competition, teamManager: teamManager!)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - Competition Card

struct CompetitionCard: View {
    let competition: Competition
    let teamManager: TeamManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(competition.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Label(competition.type.displayName, systemImage: competition.type.icon)
                        Text("•")
                        Label(competition.metric.displayName, systemImage: "chart.bar.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                statusBadge
            }

            // Progress Bar (if limited duration)
            if let days = competition.daysRemaining {
                VStack(spacing: 4) {
                    ProgressView(value: competition.progressPercentage, total: 1.0)
                        .tint(.orange)

                    HStack {
                        Text("\(days) jour\(days > 1 ? "s" : "") restant\(days > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(competition.endDate!, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("\(competition.participantCount)/\(competition.maxParticipants)")
                        .font(.headline)
                }
                .foregroundColor(.blue)

                if let currentUser = teamManager.getCurrentUser() {
                    let leaderboard = teamManager.getTeamLeaderboard(Team(name: "temp", creatorID: currentUser.id.uuidString), metric: competition.metric)
                    if let userEntry = leaderboard.first(where: { $0.id == currentUser.id.uuidString }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                            Text("Position: \(userEntry.rank)")
                                .font(.headline)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(competition.hasEnded ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .opacity(competition.hasEnded ? 0.6 : 1.0)
    }

    private var statusBadge: some View {
        Group {
            if competition.hasEnded {
                Text("Terminée")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .cornerRadius(8)
            } else if competition.isActive {
                Text("En cours")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    CompetitionsView()
        .modelContainer(for: [Competition.self, User.self, Team.self], inMemory: true)
}
