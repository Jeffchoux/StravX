//
//  TeamDetailView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI

struct TeamDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let team: Team
    let teamManager: TeamManager

    @State private var members: [(id: String, username: String, stats: (distance: Double, activities: Int))] = []
    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var selectedMetric: CompetitionMetric = .distance
    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false

    private var isCreator: Bool {
        guard let currentUser = teamManager.getCurrentUser() else { return false }
        return team.creatorID == currentUser.id.uuidString
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                headerCard

                // Share Section
                shareSection

                // Leaderboard
                leaderboardSection

                // Members List
                membersSection

                // Actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadData()
        }
        .alert("Quitter la team ?", isPresented: $showingLeaveAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Quitter", role: .destructive) {
                leaveTeam()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir quitter '\(team.name)' ?")
        }
        .alert("Supprimer la team ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                deleteTeam()
            }
        } message: {
            Text("Cette action est irréversible. Tous les membres seront retirés de la team.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(team: team)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(.blue)
                        Text(team.code)
                            .font(.title3)
                            .fontWeight(.bold)
                    }

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

                Image(systemName: "person.3.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Divider()

            // Stats Grid
            HStack(spacing: 20) {
                TeamStatBox(
                    icon: "person.fill",
                    value: "\(team.memberCount)",
                    label: "Membres",
                    color: .blue
                )

                TeamStatBox(
                    icon: "map.fill",
                    value: String(format: "%.1f", team.totalDistance / 1000),
                    label: "km",
                    color: .green
                )

                TeamStatBox(
                    icon: "figure.run",
                    value: "\(team.totalActivities)",
                    label: "Activités",
                    color: .orange
                )

                TeamStatBox(
                    icon: "flag.fill",
                    value: "\(team.totalTerritories)",
                    label: "Zones",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Share Section

    private var shareSection: some View {
        Button {
            showingShareSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title3)
                Text("Partager le code d'invitation")
                    .font(.headline)
            }
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
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Classement")
                .font(.title2)
                .fontWeight(.bold)

            // Metric Selector
            Picker("Métrique", selection: $selectedMetric) {
                Text("Distance").tag(CompetitionMetric.distance)
                Text("Activités").tag(CompetitionMetric.activities)
                Text("Zones").tag(CompetitionMetric.territories)
                Text("XP").tag(CompetitionMetric.xp)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedMetric) { _, _ in
                updateLeaderboard()
            }

            // Leaderboard
            VStack(spacing: 12) {
                ForEach(leaderboard) { entry in
                    LeaderboardRow(entry: entry, metric: selectedMetric)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Membres (\(members.count))")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(members, id: \.id) { member in
                    MemberRow(member: member, isCreator: member.id == team.creatorID)
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
            if isCreator {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Supprimer la team", systemImage: "trash.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            } else {
                Button(role: .destructive) {
                    showingLeaveAlert = true
                } label: {
                    Label("Quitter la team", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadData() {
        members = teamManager.getTeamMembers(team)
        updateLeaderboard()
    }

    private func updateLeaderboard() {
        leaderboard = teamManager.getTeamLeaderboard(team, metric: selectedMetric)
    }

    private func leaveTeam() {
        if teamManager.leaveTeam(team) {
            dismiss()
        }
    }

    private func deleteTeam() {
        if teamManager.deleteTeam(team) {
            dismiss()
        }
    }
}

// MARK: - Team Stat Box

struct TeamStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let metric: CompetitionMetric

    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            Text("\(entry.rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(rankColor)
                .clipShape(Circle())

            // Name
            Text(entry.name)
                .font(.body)
                .fontWeight(.medium)

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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
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

// MARK: - Member Row

struct MemberRow: View {
    let member: (id: String, username: String, stats: (distance: Double, activities: Int))
    let isCreator: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.username)
                        .font(.body)
                        .fontWeight(.medium)

                    if isCreator {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                HStack(spacing: 12) {
                    Label(String(format: "%.1f km", member.stats.distance / 1000), systemImage: "map.fill")
                    Label("\(member.stats.activities)", systemImage: "figure.run")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Share Sheet

struct ShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let team: Team

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    Text("Inviter des amis")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Partagez le code d'invitation pour que vos amis puissent rejoindre votre team.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Code Display
                VStack(spacing: 8) {
                    Text("Code d'invitation")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(team.code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Share Buttons
                VStack(spacing: 12) {
                    // WhatsApp Share Button
                    Button {
                        ShareHelper.shareTeamToWhatsApp(team: team)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.bubble.left.fill")
                                .font(.title3)
                            Text("Partager sur WhatsApp")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }

                    // Standard Share Button
                    Button {
                        shareTeamCode()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.title3)
                            Text("Partager autrement")
                                .font(.headline)
                        }
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Partager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func shareTeamCode() {
        let message = """
        Rejoins ma team StravX ! 🏃‍♂️

        Team : \(team.name)
        Code : \(team.code)

        Télécharge StravX et utilise ce code pour nous rejoindre !
        """

        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Pour iPad - éviter crash
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(
            team: Team(name: "Team Rocket", creatorID: "test-user-id"),
            teamManager: TeamManager(modelContext: PreviewContainer.shared.modelContext)
        )
    }
}
