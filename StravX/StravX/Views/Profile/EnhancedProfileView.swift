//
//  EnhancedProfileView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct EnhancedProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var territoryManager: TerritoryManager?
    @State private var user: User?
    @State private var showingSettings = false
    @State private var showingBadges = false
    @State private var showingQuests = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec niveau et XP
                    levelHeader

                    // Barre de progression XP
                    xpProgressBar

                    // Stats rapides
                    quickStats

                    // Social / Friends
                    socialSection

                    // Badges (3 derniers)
                    recentBadges

                    // Quêtes quotidiennes
                    dailyQuests

                    //Stats détaillées
                    detailedStats
                }
                .padding(.vertical)
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingBadges) {
                BadgesView(user: user)
            }
            .sheet(isPresented: $showingQuests) {
                QuestsView(user: user)
            }
            .onAppear {
                loadData()
            }
        }
    }

    // MARK: - Level Header

    private var levelHeader: some View {
        VStack(spacing: 16) {
            // Avatar avec niveau
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [user?.color ?? .blue, (user?.color ?? .blue).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)

                    Text("Niv. \(user?.level ?? 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }

            // Nom et titre
            VStack(spacing: 4) {
                Text(user?.username ?? "Joueur")
                    .font(.title)
                    .fontWeight(.bold)

                Text(user?.rankTitle ?? "Explorateur")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - XP Progress Bar

    private var xpProgressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("XP")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let user = user {
                    let progress = user.levelProgress
                    Text("\(progress.currentLevelXP) / \(progress.neededForNext)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ProgressView(value: user?.levelProgress.progress ?? 0, total: 1.0)
                .tint(user?.color ?? .blue)

            Text("Total: \(user?.totalXP ?? 0) XP")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats Rapides")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickStatCard(
                    icon: "map.fill",
                    title: "Territoires",
                    value: "\(user?.territoriesOwned ?? 0)",
                    color: .blue
                )

                QuickStatCard(
                    icon: "flame.fill",
                    title: "Série",
                    value: "\(user?.currentStreak ?? 0) jours",
                    color: .orange
                )

                QuickStatCard(
                    icon: "location.fill",
                    title: "Distance",
                    value: String(format: "%.1f km", user?.totalDistanceKm ?? 0),
                    color: .green
                )

                QuickStatCard(
                    icon: "figure.run",
                    title: "Activités",
                    value: "\(user?.totalActivities ?? 0)",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Social Section

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social")
                .font(.headline)
                .padding(.horizontal)

            NavigationLink {
                FriendsView()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amis")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Text("\(user?.followingCount ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 4) {
                                Text("\(user?.followerCount ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Recent Badges

    private var recentBadges: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(.headline)

                Spacer()

                Button("Voir tout") {
                    showingBadges = true
                }
                .font(.caption)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(user?.badges.prefix(5) ?? [], id: \.id) { badge in
                        BadgeCard(badge: badge)
                    }

                    if (user?.badges.count ?? 0) == 0 {
                        Text("Aucun badge encore...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Daily Quests

    private var dailyQuests: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quêtes Quotidiennes")
                    .font(.headline)

                Spacer()

                Button("Détails") {
                    showingQuests = true
                }
                .font(.caption)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(user?.quests.filter { !$0.isExpired }.prefix(3) ?? [], id: \.id) { quest in
                    QuestCard(quest: quest)
                }

                if (user?.quests.filter { !$0.isExpired }.count ?? 0) == 0 {
                    Text("Aucune quête aujourd'hui")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Detailed Stats

    private var detailedStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques Détaillées")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                StatRow(icon: "trophy.fill", title: "Territoires Capturés", value: "\(user?.territoriesCaptured ?? 0)")
                StatRow(icon: "shield.fill", title: "Territoires Défendus", value: "\(user?.territoriesDefended ?? 0)")
                StatRow(icon: "xmark.circle.fill", title: "Territoires Perdus", value: "\(user?.territoriesLost ?? 0)")
                StatRow(icon: "speedometer", title: "Vitesse Max", value: String(format: "%.1f km/h", user?.fastestSpeed ?? 0))
                StatRow(icon: "calendar", title: "Série Record", value: "\(user?.longestStreak ?? 0) jours")
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        if territoryManager == nil {
            territoryManager = TerritoryManager(modelContext: modelContext)
        }
        user = territoryManager?.getUser()
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BadgeCard: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.type.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: badge.type.icon)
                    .font(.title2)
                    .foregroundColor(badge.type.color)
            }

            Text(badge.type.title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
    }
}

struct QuestCard: View {
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(quest.isCompleted ? .green : .gray)

                Text(quest.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("+\(quest.xpReward) XP")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            ProgressView(value: quest.progress, total: 1.0)
                .tint(.blue)

            Text("\(quest.currentValue) / \(quest.targetValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Detail Views

struct BadgesView: View {
    let user: User?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(user?.badges ?? [], id: \.id) { badge in
                        BadgeDetailCard(badge: badge)
                    }
                }
                .padding()
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BadgeDetailCard: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(badge.type.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: badge.type.icon)
                    .font(.largeTitle)
                    .foregroundColor(badge.type.color)
            }

            Text(badge.type.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(badge.unlockedAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct QuestsView: View {
    let user: User?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(user?.quests.filter { !$0.isExpired } ?? [], id: \.id) { quest in
                        QuestDetailCard(quest: quest)
                    }
                }
                .padding()
            }
            .navigationTitle("Quêtes")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct QuestDetailCard: View {
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.title2)
                    .foregroundColor(quest.isCompleted ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)

                    Text(quest.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            ProgressView(value: quest.progress, total: 1.0)
                .tint(quest.isCompleted ? .green : .orange)

            HStack {
                Text("\(quest.currentValue) / \(quest.targetValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label("\(quest.xpReward) XP", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text("Expire: \(quest.expiresAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(quest.isCompleted ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    EnhancedProfileView()
        .modelContainer(for: [User.self], inMemory: true)
}
