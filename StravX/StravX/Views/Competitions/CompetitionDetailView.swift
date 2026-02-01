//
//  CompetitionDetailView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct CompetitionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let competition: Competition
    let teamManager: TeamManager

    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var showingJoinAlert = false
    @State private var showingLeaveAlert = false
    @State private var refreshTrigger = false

    private var isParticipant: Bool {
        guard let currentUser = teamManager.getCurrentUser() else { return false }
        return competition.participantIDs.contains(currentUser.id.uuidString)
    }

    private var isCreator: Bool {
        guard let currentUser = teamManager.getCurrentUser() else { return false }
        return competition.creatorID == currentUser.id.uuidString
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard

                // Leaderboard
                leaderboardSection

                // Actions
                if !competition.hasEnded {
                    actionsSection
                }
            }
            .padding()
        }
        .navigationTitle(competition.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadLeaderboard()
        }
        .refreshable {
            loadLeaderboard()
        }
        .alert("Rejoindre la compétition ?", isPresented: $showingJoinAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Rejoindre") {
                joinCompetition()
            }
        } message: {
            Text("Voulez-vous participer à '\(competition.name)' ?")
        }
        .alert("Quitter la compétition ?", isPresented: $showingLeaveAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Quitter", role: .destructive) {
                leaveCompetition()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir quitter cette compétition ?")
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Status and Info
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Label(competition.type.displayName, systemImage: competition.type.icon)
                        Text("•")
                        Label(competition.metric.displayName, systemImage: "chart.bar.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if isCreator {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("Créateur")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                    }
                }

                Spacer()

                statusBadge
            }

            Divider()

            // Duration Info
            if let days = competition.daysRemaining {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Temps restant")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(days) jour\(days > 1 ? "s" : "")")
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Fin le")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(competition.endDate!, style: .date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    ProgressView(value: competition.progressPercentage, total: 1.0)
                        .tint(.orange)
                }
            } else {
                HStack {
                    Image(systemName: "infinity")
                        .foregroundColor(.blue)
                    Text("Durée illimitée")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            Divider()

            // Participants
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(competition.participantCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Participants")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isParticipant, let currentUser = teamManager.getCurrentUser(),
                   let myEntry = leaderboard.first(where: { $0.id == currentUser.id.uuidString }) {
                    HStack(spacing: 8) {
                        Image(systemName: rankIcon(myEntry.rank))
                            .foregroundColor(rankColor(myEntry.rank))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Position #\(myEntry.rank)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(String(format: "%.1f \(competition.metric.unit)", myEntry.score))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var statusBadge: some View {
        Group {
            if competition.hasEnded {
                Text("Terminée")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray)
                    .cornerRadius(8)
            } else if competition.isActive {
                Text("En cours")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Classement")
                .font(.title2)
                .fontWeight(.bold)

            if leaderboard.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("Aucun participant pour le moment")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                        CompetitionLeaderboardRow(
                            entry: entry,
                            metric: competition.metric,
                            isCurrentUser: entry.id == teamManager.getCurrentUser()?.id.uuidString
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if isParticipant && !isCreator {
                Button(role: .destructive) {
                    showingLeaveAlert = true
                } label: {
                    Label("Quitter la compétition", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            } else if !isParticipant && competition.canJoin {
                Button {
                    showingJoinAlert = true
                } label: {
                    Label("Rejoindre la compétition", systemImage: "person.badge.plus.fill")
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
            } else if competition.isFull {
                Label("Compétition complète", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Functions

    private func rankIcon(_ rank: Int) -> String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "number.circle.fill"
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }

    // MARK: - Actions

    private func loadLeaderboard() {
        // Create a temporary team with all participants to get leaderboard
        let tempTeam = Team(name: "temp", creatorID: competition.creatorID)

        // Set the participants
        tempTeam.memberIDs = competition.participantIDs

        leaderboard = teamManager.getTeamLeaderboard(tempTeam, metric: competition.metric)
    }

    private func joinCompetition() {
        guard let currentUser = teamManager.getCurrentUser() else { return }

        if competition.addParticipant(currentUser.id.uuidString) {
            try? modelContext.save()
            loadLeaderboard()
        }
    }

    private func leaveCompetition() {
        guard let currentUser = teamManager.getCurrentUser() else { return }

        if competition.removeParticipant(currentUser.id.uuidString) {
            try? modelContext.save()
            loadLeaderboard()
            dismiss()
        }
    }
}

// MARK: - Competition Leaderboard Row

struct CompetitionLeaderboardRow: View {
    let entry: LeaderboardEntry
    let metric: CompetitionMetric
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)

                if entry.rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.headline)
                        .foregroundColor(.white)
                } else {
                    Text("\(entry.rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if isCurrentUser {
                        Text("(Vous)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Text(metric.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text(scoreText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)

                Text(metric.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.05) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }

    private var rankIcon: String {
        switch entry.rank {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    private var scoreText: String {
        switch metric {
        case .distance:
            return String(format: "%.1f", entry.score)
        default:
            return String(format: "%.0f", entry.score)
        }
    }
}

#Preview {
    NavigationStack {
        CompetitionDetailView(
            competition: Competition(
                name: "Défi du mois",
                creatorID: "test-user",
                type: .individual,
                metric: .distance,
                duration: .limited(days: 30)
            ),
            teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext)
        )
    }
}
