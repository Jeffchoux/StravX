//
//  FriendManager.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@Observable
class FriendManager {
    // MARK: - Properties

    private var modelContext: ModelContext
    private var currentUser: User?

    // Cache
    var friends: [User] = []
    var pendingRequests: [User] = [] // Demandes reçues
    var sentRequests: [User] = [] // Demandes envoyées

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentUser()
    }

    // MARK: - User Management

    private func loadCurrentUser() {
        let descriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(descriptor)) ?? []
        currentUser = users.first
    }

    func getCurrentUser() -> User? {
        return currentUser
    }

    // MARK: - Friend Management

    /// Envoie une demande d'ami
    func sendFriendRequest(to userID: String) -> Bool {
        guard let currentUser = currentUser else { return false }
        guard let targetUser = fetchUser(by: userID) else { return false }

        // Vérifier qu'ils ne sont pas déjà amis
        if currentUser.friends.contains(userID) {
            print("⚠️ Already friends")
            return false
        }

        // Vérifier qu'il n'y a pas déjà une demande en attente
        if targetUser.friendRequestsData != nil {
            let requests = targetUser.friendRequests
            if requests.contains(currentUser.id.uuidString) {
                print("⚠️ Friend request already sent")
                return false
            }
        }

        // Ajouter la demande aux demandes reçues du destinataire
        var requests = targetUser.friendRequests
        requests.append(currentUser.id.uuidString)
        targetUser.friendRequests = requests

        do {
            try modelContext.save()
            print("✅ Friend request sent to \(targetUser.username)")
            loadFriends()
            return true
        } catch {
            print("❌ Error sending friend request: \(error)")
            return false
        }
    }

    /// Accepte une demande d'ami
    func acceptFriendRequest(from userID: String) -> Bool {
        guard let currentUser = currentUser else { return false }
        guard let requester = fetchUser(by: userID) else { return false }

        // Retirer la demande de la liste des demandes reçues
        var requests = currentUser.friendRequests
        if let index = requests.firstIndex(of: userID) {
            requests.remove(at: index)
            currentUser.friendRequests = requests
        } else {
            print("⚠️ No friend request from this user")
            return false
        }

        // Ajouter aux amis (bidirectionnel)
        var myFriends = currentUser.friends
        myFriends.append(userID)
        currentUser.friends = myFriends

        var theirFriends = requester.friends
        theirFriends.append(currentUser.id.uuidString)
        requester.friends = theirFriends

        do {
            try modelContext.save()
            print("✅ Friend request accepted from \(requester.username)")
            loadFriends()
            return true
        } catch {
            print("❌ Error accepting friend request: \(error)")
            return false
        }
    }

    /// Refuse une demande d'ami
    func declineFriendRequest(from userID: String) -> Bool {
        guard let currentUser = currentUser else { return false }

        var requests = currentUser.friendRequests
        if let index = requests.firstIndex(of: userID) {
            requests.remove(at: index)
            currentUser.friendRequests = requests

            do {
                try modelContext.save()
                print("✅ Friend request declined")
                loadFriends()
                return true
            } catch {
                print("❌ Error declining friend request: \(error)")
                return false
            }
        }

        return false
    }

    /// Retire un ami
    func removeFriend(_ userID: String) -> Bool {
        guard let currentUser = currentUser else { return false }
        guard let friend = fetchUser(by: userID) else { return false }

        // Retirer des deux côtés
        var myFriends = currentUser.friends
        if let index = myFriends.firstIndex(of: userID) {
            myFriends.remove(at: index)
            currentUser.friends = myFriends
        }

        var theirFriends = friend.friends
        if let index = theirFriends.firstIndex(of: currentUser.id.uuidString) {
            theirFriends.remove(at: index)
            friend.friends = theirFriends
        }

        do {
            try modelContext.save()
            print("✅ Friend removed: \(friend.username)")
            loadFriends()
            return true
        } catch {
            print("❌ Error removing friend: \(error)")
            return false
        }
    }

    /// Charge les amis de l'utilisateur
    func loadFriends() {
        guard let user = currentUser else {
            friends = []
            pendingRequests = []
            sentRequests = []
            return
        }

        // Charger les amis
        friends = user.friends.compactMap { fetchUser(by: $0) }

        // Charger les demandes reçues
        pendingRequests = user.friendRequests.compactMap { fetchUser(by: $0) }

        // Charger les demandes envoyées
        let allUsers = getAllUsers()
        sentRequests = allUsers.filter { otherUser in
            otherUser.friendRequests.contains(user.id.uuidString)
        }
    }

    /// Vérifie si un utilisateur est ami
    func isFriend(userID: String) -> Bool {
        guard let user = currentUser else { return false }
        return user.friends.contains(userID)
    }

    /// Vérifie si une demande a été envoyée
    func hasSentRequest(to userID: String) -> Bool {
        guard let targetUser = fetchUser(by: userID) else { return false }
        guard let currentUser = currentUser else { return false }
        return targetUser.friendRequests.contains(currentUser.id.uuidString)
    }

    /// Vérifie si une demande a été reçue
    func hasReceivedRequest(from userID: String) -> Bool {
        guard let user = currentUser else { return false }
        return user.friendRequests.contains(userID)
    }

    /// Récupère les utilisateurs disponibles (ni amis, ni demandes en cours)
    func getAvailableUsers() -> [User] {
        guard let currentUser = currentUser else { return [] }

        let allUsers = getAllUsers()

        return allUsers.filter { user in
            // Exclure l'utilisateur courant
            guard user.id != currentUser.id else { return false }

            // Exclure les amis
            guard !currentUser.friends.contains(user.id.uuidString) else { return false }

            // Exclure les demandes reçues
            guard !currentUser.friendRequests.contains(user.id.uuidString) else { return false }

            // Exclure les demandes envoyées
            guard !user.friendRequests.contains(currentUser.id.uuidString) else { return false }

            return true
        }
    }

    // MARK: - Helper Functions

    /// Récupère un utilisateur par son ID
    private func fetchUser(by id: String) -> User? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id == uuid
            }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Récupère tous les utilisateurs
    private func getAllUsers() -> [User] {
        let descriptor = FetchDescriptor<User>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
