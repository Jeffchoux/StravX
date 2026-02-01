//
//  FriendsView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct FriendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var followingManager: FollowingManager?
    @State private var selectedTab = 0
    @State private var following: [User] = []
    @State private var followers: [User] = []
    @State private var available: [User] = []
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Following (\(following.count))").tag(0)
                    Text("Followers (\(followers.count))").tag(1)
                    Text("Découvrir").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    followingList
                        .tag(0)

                    followersList
                        .tag(1)

                    discoverList
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Amis")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupManager()
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
        .searchable(text: $searchText, prompt: "Rechercher un utilisateur")
    }

    // MARK: - Following List

    private var followingList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredFollowing.isEmpty {
                    emptyState(
                        icon: "person.2.fill",
                        title: "Aucune personne suivie",
                        message: "Découvrez des athlètes à suivre dans l'onglet Découvrir"
                    )
                } else {
                    ForEach(filteredFollowing) { user in
                        NavigationLink {
                            FriendProfileView(
                                userID: user.id.uuidString,
                                followingManager: followingManager!
                            )
                        } label: {
                            UserRow(user: user, showFollowButton: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Followers List

    private var followersList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredFollowers.isEmpty {
                    emptyState(
                        icon: "person.badge.plus.fill",
                        title: "Aucun follower",
                        message: "Partagez votre profil pour que d'autres vous suivent"
                    )
                } else {
                    ForEach(filteredFollowers) { user in
                        NavigationLink {
                            FriendProfileView(
                                userID: user.id.uuidString,
                                followingManager: followingManager!
                            )
                        } label: {
                            UserRow(
                                user: user,
                                showFollowButton: true,
                                followingManager: followingManager
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Discover List

    private var discoverList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredAvailable.isEmpty {
                    emptyState(
                        icon: "magnifyingglass",
                        title: "Aucun utilisateur trouvé",
                        message: searchText.isEmpty ? "Tous les utilisateurs sont déjà suivis" : "Essayez une autre recherche"
                    )
                } else {
                    ForEach(filteredAvailable) { user in
                        UserRow(
                            user: user,
                            showFollowButton: true,
                            followingManager: followingManager
                        )
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func setupManager() {
        if followingManager == nil {
            followingManager = FollowingManager(modelContext: modelContext)
        }
    }

    private func loadData() {
        guard let manager = followingManager else { return }
        following = manager.getFollowing()
        followers = manager.getFollowers()
        available = manager.getAvailableUsers()
    }

    private var filteredFollowing: [User] {
        if searchText.isEmpty {
            return following
        }
        return following.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredFollowers: [User] {
        if searchText.isEmpty {
            return followers
        }
        return followers.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredAvailable: [User] {
        if searchText.isEmpty {
            return available
        }
        return available.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: User
    var showFollowButton: Bool = false
    var followingManager: FollowingManager?

    @State private var isFollowing = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(user.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(user.username.prefix(2).uppercased())
                    .font(.headline)
                    .foregroundColor(user.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.username)
                        .font(.headline)

                    // Level badge
                    Text("Lvl \(user.level)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(user.color)
                        .cornerRadius(8)
                }

                HStack(spacing: 12) {
                    Label("\(user.territoriesOwned)", systemImage: "map.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(String(format: "%.0f km", user.totalDistanceKm), systemImage: "figure.run")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Follow button
            if showFollowButton, let manager = followingManager {
                Button {
                    toggleFollow(manager: manager)
                } label: {
                    Text(isFollowing ? "Suivi" : "Suivre")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            if let manager = followingManager {
                isFollowing = manager.isFollowing(userID: user.id.uuidString)
            }
        }
    }

    private func toggleFollow(manager: FollowingManager) {
        if isFollowing {
            _ = manager.unfollow(userID: user.id.uuidString)
            isFollowing = false
        } else {
            _ = manager.follow(userID: user.id.uuidString)
            isFollowing = true
        }
    }
}

#Preview {
    FriendsView()
        .modelContainer(for: [User.self, Activity.self], inMemory: true)
}
