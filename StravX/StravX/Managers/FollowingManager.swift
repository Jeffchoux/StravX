//
//  FollowingManager.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData

@Observable
class FollowingManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - User Retrieval

    func getCurrentUser() -> User? {
        let descriptor = FetchDescriptor<User>()
        if let users = try? modelContext.fetch(descriptor), let user = users.first {
            return user
        }
        return nil
    }

    func getUser(byID id: String) -> User? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == uuid
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func getAllUsers() -> [User] {
        let descriptor = FetchDescriptor<User>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Follow Actions

    /// Suivre un utilisateur
    func follow(userID: String) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }
        guard let targetUser = getUser(byID: userID) else { return false }

        // Ne pas se suivre soi-même
        guard currentUser.id.uuidString != userID else { return false }

        // Vérifier que le user accepte les followers
        guard targetUser.allowFollowers else { return false }

        // Vérifier qu'on ne suit pas déjà
        guard !currentUser.followingIDs.contains(userID) else { return false }

        // Ajouter à ma liste de following
        var following = currentUser.followingIDs
        following.append(userID)
        currentUser.followingIDs = following

        // Ajouter à sa liste de followers
        var followers = targetUser.followerIDs
        followers.append(currentUser.id.uuidString)
        targetUser.followerIDs = followers

        // Sauvegarder
        try? modelContext.save()

        return true
    }

    /// Ne plus suivre un utilisateur
    func unfollow(userID: String) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }
        guard let targetUser = getUser(byID: userID) else { return false }

        // Retirer de ma liste de following
        var following = currentUser.followingIDs
        following.removeAll { $0 == userID }
        currentUser.followingIDs = following

        // Retirer de sa liste de followers
        var followers = targetUser.followerIDs
        followers.removeAll { $0 == currentUser.id.uuidString }
        targetUser.followerIDs = followers

        // Sauvegarder
        try? modelContext.save()

        return true
    }

    /// Vérifier si on suit un utilisateur
    func isFollowing(userID: String) -> Bool {
        guard let currentUser = getCurrentUser() else { return false }
        return currentUser.followingIDs.contains(userID)
    }

    // MARK: - Lists

    /// Récupérer tous les utilisateurs qu'on suit
    func getFollowing() -> [User] {
        guard let currentUser = getCurrentUser() else { return [] }
        return currentUser.followingIDs.compactMap { getUser(byID: $0) }
    }

    /// Récupérer tous nos followers
    func getFollowers() -> [User] {
        guard let currentUser = getCurrentUser() else { return [] }
        return currentUser.followerIDs.compactMap { getUser(byID: $0) }
    }

    /// Récupérer tous les utilisateurs disponibles (pour découverte)
    func getAvailableUsers() -> [User] {
        guard let currentUser = getCurrentUser() else { return [] }
        let allUsers = getAllUsers()

        // Exclure soi-même et ceux qu'on suit déjà
        return allUsers.filter { user in
            user.id.uuidString != currentUser.id.uuidString &&
            !currentUser.followingIDs.contains(user.id.uuidString) &&
            user.allowFollowers
        }
    }

    // MARK: - Statistics

    /// Récupérer les statistiques d'un utilisateur pour l'affichage
    func getUserStats(userID: String) -> UserStats? {
        guard let user = getUser(byID: userID) else { return nil }

        return UserStats(
            id: user.id.uuidString,
            username: user.username,
            level: user.level,
            rankTitle: user.rankTitle,
            totalXP: user.totalXP,
            totalDistanceKm: user.totalDistanceKm,
            totalActivities: user.totalActivities,
            territoriesOwned: user.territoriesOwned,
            territoriesCaptured: user.territoriesCaptured,
            currentStreak: user.currentStreak,
            longestStreak: user.longestStreak,
            badgeCount: user.badges.count,
            followerCount: user.followerCount,
            followingCount: user.followingCount,
            color: user.personalColor
        )
    }

    /// Récupérer les activités récentes d'un utilisateur
    func getRecentActivities(userID: String, limit: Int = 10) -> [Activity] {
        guard let uuid = UUID(uuidString: userID) else { return [] }

        var descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate<Activity> { activity in
                activity.userID == uuid
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Récupérer le feed d'activités des personnes qu'on suit
    func getFollowingFeed(limit: Int = 20) -> [Activity] {
        guard let currentUser = getCurrentUser() else { return [] }

        let followingUUIDs = currentUser.followingIDs.compactMap { UUID(uuidString: $0) }

        var descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate<Activity> { activity in
                followingUUIDs.contains(activity.userID)
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - UserStats Structure

struct UserStats: Identifiable {
    let id: String
    let username: String
    let level: Int
    let rankTitle: String
    let totalXP: Int
    let totalDistanceKm: Double
    let totalActivities: Int
    let territoriesOwned: Int
    let territoriesCaptured: Int
    let currentStreak: Int
    let longestStreak: Int
    let badgeCount: Int
    let followerCount: Int
    let followingCount: Int
    let color: String
}
