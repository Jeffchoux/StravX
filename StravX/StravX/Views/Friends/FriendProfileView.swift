//
//  FriendProfileView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct FriendProfileView: View {
    let userID: String
    let followingManager: FollowingManager

    @State private var stats: UserStats?
    @State private var recentActivities: [Activity] = []
    @State private var isFollowing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let stats = stats {
                    // Header
                    headerSection(stats: stats)

                    // Stats Cards
                    statsSection(stats: stats)

                    // Recent Activities
                    activitiesSection
                } else {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    toggleFollow()
                } label: {
                    Text(isFollowing ? "Ne plus suivre" : "Suivre")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .refreshable {
            loadData()
        }
    }

    // MARK: - Header Section

    private func headerSection(stats: UserStats) -> some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(colorFromString(stats.color).opacity(0.2))
                    .frame(width: 100, height: 100)

                Text(stats.username.prefix(2).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(colorFromString(stats.color))
            }

            // Username and level
            VStack(spacing: 8) {
                Text(stats.username)
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 8) {
                    Text("Niveau \(stats.level)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(colorFromString(stats.color))
                        .cornerRadius(20)

                    Text(stats.rankTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Followers/Following
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(stats.followerCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(stats.followingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Stats Section

    private func statsSection(stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiques")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                // Distance
                FriendStatRow(
                    icon: "figure.run",
                    title: "Distance totale",
                    value: String(format: "%.1f km", stats.totalDistanceKm),
                    color: .blue
                )

                // Activities
                FriendStatRow(
                    icon: "list.bullet",
                    title: "Activités",
                    value: "\(stats.totalActivities)",
                    color: .green
                )

                // Territories
                FriendStatRow(
                    icon: "map.fill",
                    title: "Territoires possédés",
                    value: "\(stats.territoriesOwned)",
                    color: .orange
                )

                // Total captures
                FriendStatRow(
                    icon: "flag.fill",
                    title: "Captures totales",
                    value: "\(stats.territoriesCaptured)",
                    color: .purple
                )

                // Current streak
                FriendStatRow(
                    icon: "flame.fill",
                    title: "Série actuelle",
                    value: "\(stats.currentStreak) jours",
                    color: .red
                )

                // Longest streak
                FriendStatRow(
                    icon: "trophy.fill",
                    title: "Meilleure série",
                    value: "\(stats.longestStreak) jours",
                    color: .yellow
                )

                // Badges
                FriendStatRow(
                    icon: "star.fill",
                    title: "Badges",
                    value: "\(stats.badgeCount)",
                    color: .pink
                )

                // XP
                FriendStatRow(
                    icon: "sparkles",
                    title: "XP total",
                    value: "\(stats.totalXP)",
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Activities Section

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activités récentes")
                .font(.title2)
                .fontWeight(.bold)

            if recentActivities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("Aucune activité récente")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentActivities) { activity in
                        FriendActivityRow(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func loadData() {
        stats = followingManager.getUserStats(userID: userID)
        recentActivities = followingManager.getRecentActivities(userID: userID, limit: 10)
        isFollowing = followingManager.isFollowing(userID: userID)
    }

    private func toggleFollow() {
        if isFollowing {
            _ = followingManager.unfollow(userID: userID)
            isFollowing = false
        } else {
            _ = followingManager.follow(userID: userID)
            isFollowing = true
        }
        // Reload to update follower count
        loadData()
    }

    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

// MARK: - Friend Stat Row

struct FriendStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Friend Activity Row

struct FriendActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.typeColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.typeIcon)
                    .font(.headline)
                    .foregroundColor(activity.typeColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.capitalized)
                    .font(.headline)

                Text(activity.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f km", activity.distanceKm))
                    .font(.subheadline)
                    .fontWeight(.medium)

                if activity.territoriesCaptured > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                        Text("\(activity.territoriesCaptured)")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Activity.self, configurations: config)
    let context = container.mainContext

    return NavigationStack {
        FriendProfileView(
            userID: UUID().uuidString,
            followingManager: FollowingManager(modelContext: context)
        )
    }
}
