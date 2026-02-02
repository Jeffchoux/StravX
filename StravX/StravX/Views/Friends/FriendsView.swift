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
    @State private var friendManager: FriendManager?
    @State private var selectedTab = 0
    @State private var friends: [User] = []
    @State private var pendingRequests: [User] = []
    @State private var available: [User] = []
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Amis (\(friends.count))").tag(0)
                    if !pendingRequests.isEmpty {
                        Text("Demandes (\(pendingRequests.count))").tag(1)
                    } else {
                        Text("Demandes").tag(1)
                    }
                    Text("Découvrir").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    friendsList
                        .tag(0)

                    requestsList
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

    // MARK: - Friends List

    private var friendsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredFriends.isEmpty {
                    emptyState(
                        icon: "person.2.fill",
                        title: "Aucun ami",
                        message: "Envoyez des demandes d'amis dans l'onglet Découvrir"
                    )
                } else {
                    ForEach(filteredFriends) { user in
                        FriendRow(user: user, friendManager: friendManager)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Requests List

    private var requestsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if filteredRequests.isEmpty {
                    emptyState(
                        icon: "person.badge.plus.fill",
                        title: "Aucune demande",
                        message: "Les demandes d'amis apparaîtront ici"
                    )
                } else {
                    ForEach(filteredRequests) { user in
                        FriendRequestRow(user: user, friendManager: friendManager!) {
                            loadData()
                        }
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
                        message: searchText.isEmpty ? "Tous les utilisateurs sont déjà amis" : "Essayez une autre recherche"
                    )
                } else {
                    ForEach(filteredAvailable) { user in
                        DiscoverUserRow(user: user, friendManager: friendManager!) {
                            loadData()
                        }
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
        if friendManager == nil {
            friendManager = FriendManager(modelContext: modelContext)
        }
    }

    private func loadData() {
        guard let manager = friendManager else { return }
        manager.loadFriends()
        friends = manager.friends
        pendingRequests = manager.pendingRequests
        available = manager.getAvailableUsers()
    }

    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredRequests: [User] {
        if searchText.isEmpty {
            return pendingRequests
        }
        return pendingRequests.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredAvailable: [User] {
        if searchText.isEmpty {
            return available
        }
        return available.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let user: User
    var friendManager: FriendManager?

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

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let user: User
    let friendManager: FriendManager
    let onUpdate: () -> Void

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
                Text(user.username)
                    .font(.headline)

                Text("Lvl \(user.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Accept button
            Button {
                if friendManager.acceptFriendRequest(from: user.id.uuidString) {
                    onUpdate()
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            // Decline button
            Button {
                if friendManager.declineFriendRequest(from: user.id.uuidString) {
                    onUpdate()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Discover User Row

struct DiscoverUserRow: View {
    let user: User
    let friendManager: FriendManager
    let onUpdate: () -> Void

    @State private var requestSent = false

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

            // Add friend button
            Button {
                if friendManager.sendFriendRequest(to: user.id.uuidString) {
                    requestSent = true
                    onUpdate()
                }
            } label: {
                if requestSent || friendManager.hasSentRequest(to: user.id.uuidString) {
                    Text("Demande envoyée")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .cornerRadius(20)
                } else {
                    Image(systemName: "person.badge.plus.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .buttonStyle(.plain)
            .disabled(requestSent || friendManager.hasSentRequest(to: user.id.uuidString))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            requestSent = friendManager.hasSentRequest(to: user.id.uuidString)
        }
    }
}

#Preview {
    FriendsView()
        .modelContainer(for: [User.self, Activity.self], inMemory: true)
}
