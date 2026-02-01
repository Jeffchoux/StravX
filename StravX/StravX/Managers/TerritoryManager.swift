//
//  TerritoryManager.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftData
import Observation

@Observable
class TerritoryManager {
    // MARK: - Properties

    private var modelContext: ModelContext
    private var currentUser: User?
    private var notificationManager: NotificationManager?

    // Cache des territoires visibles
    var visibleTerritories: [Territory] = []
    var lastUpdateLocation: CLLocationCoordinate2D?

    // Tracking de la session actuelle
    var visitedTilesThisSession: Set<String> = []
    var capturedThisSession: Int = 0
    var xpGainedThisSession: Int = 0

    // Notifications
    var pendingCaptureNotifications: [String] = [] // Messages de capture
    var pendingLevelUp: Bool = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateUser()
        notificationManager = NotificationManager(modelContext: modelContext)
        notificationManager?.registerNotificationCategories()
    }

    // MARK: - User Management

    private func loadOrCreateUser() {
        let descriptor = FetchDescriptor<User>()
        let users = (try? modelContext.fetch(descriptor)) ?? []

        if let existingUser = users.first {
            currentUser = existingUser
            print("🟢 User loaded: \(existingUser.username)")
        } else {
            // Créer un nouvel utilisateur
            let newUser = User(username: "Player")
            modelContext.insert(newUser)
            try? modelContext.save()
            currentUser = newUser
            print("🟢 New user created: \(newUser.username)")
        }
    }

    func getUser() -> User? {
        return currentUser
    }

    func updateUsername(_ newName: String) {
        currentUser?.username = newName
        try? modelContext.save()
    }

    // MARK: - Territory Loading

    /// Charge les territoires autour d'une position
    func loadTerritoriesAround(_ coordinate: CLLocationCoordinate2D, radius: Double = 1000) {
        // Obtenir toutes les tiles dans le rayon
        let tiles = GeoTile.tilesAround(coordinate: coordinate, radius: radius)

        var territories: [Territory] = []

        for tile in tiles {
            // Chercher si ce territoire existe déjà
            if let existing = fetchTerritory(tileID: tile.tileID) {
                territories.append(existing)
            } else {
                // Créer un nouveau territoire neutre
                let newTerritory = Territory(tile: tile)
                modelContext.insert(newTerritory)
                territories.append(newTerritory)
            }
        }

        try? modelContext.save()
        visibleTerritories = territories
        lastUpdateLocation = coordinate

        print("📍 Loaded \(territories.count) territories around location")
    }

    /// Récupère un territoire par son tileID
    private func fetchTerritory(tileID: String) -> Territory? {
        let descriptor = FetchDescriptor<Territory>(
            predicate: #Predicate { territory in
                territory.tileID == tileID
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Récupère tous les territoires possédés par l'utilisateur
    func getOwnedTerritories() -> [Territory] {
        guard let currentUserID = currentUser?.id.uuidString else { return [] }

        let descriptor = FetchDescriptor<Territory>(
            predicate: #Predicate { territory in
                territory.ownerID == currentUserID
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Récupère les territoires en danger (faible force)
    func getEndangeredTerritories() -> [Territory] {
        guard currentUser != nil else { return [] }

        let owned = getOwnedTerritories()
        return owned.filter { $0.strengthPoints < 30 }
    }

    // MARK: - Passage Detection

    /// Vérifie le passage dans un territoire pendant une activité
    func checkPassage(at coordinate: CLLocationCoordinate2D) {
        guard let user = currentUser else { return }

        // Obtenir la tile actuelle
        let tile = GeoTile.from(coordinate: coordinate)

        // Vérifier si on a déjà visité cette tile dans cette session
        if visitedTilesThisSession.contains(tile.tileID) {
            return // Déjà traité
        }

        // Marquer comme visité
        visitedTilesThisSession.insert(tile.tileID)

        // Récupérer ou créer le territoire
        var territory: Territory
        if let existing = fetchTerritory(tileID: tile.tileID) {
            territory = existing
        } else {
            territory = Territory(tile: tile)
            modelContext.insert(territory)
        }

        // Déterminer l'action selon la propriété
        let userID = user.id.uuidString

        if territory.isNeutral {
            // Capture d'une zone neutre
            captureTerritory(territory, by: user)
            pendingCaptureNotifications.append("🎉 Zone neutre capturée ! +10 XP")

        } else if territory.ownerID == userID {
            // Renforcement de sa propre zone
            reinforceTerritory(territory)
            pendingCaptureNotifications.append("🛡️ Zone renforcée ! +5 XP")

        } else {
            // Attaque d'une zone ennemie
            attackTerritory(territory, by: user)
            if territory.isNeutral {
                // L'attaque a réussi, capture immédiate
                captureTerritory(territory, by: user)
                pendingCaptureNotifications.append("⚔️ Zone ennemie conquise ! +25 XP")
            } else {
                pendingCaptureNotifications.append("⚔️ Zone ennemie attaquée ! Force réduite")
            }
        }

        try? modelContext.save()
    }

    // MARK: - Territory Actions

    private func captureTerritory(_ territory: Territory, by user: User) {
        let xpGained = territory.captureXP(isAttack: !territory.isNeutral)

        territory.capture(
            by: user.id.uuidString,
            userName: user.username
        )

        user.captureTerritory(xpGained: xpGained)
        capturedThisSession += 1
        xpGainedThisSession += xpGained

        // Vérifier level up
        checkLevelUp(user)
    }

    private func reinforceTerritory(_ territory: Territory) {
        territory.reinforce()

        currentUser?.addXP(5)
        xpGainedThisSession += 5

        // Si c'était une défense contre une attaque
        if territory.isContested {
            currentUser?.defendTerritory()
        }
    }

    private func attackTerritory(_ territory: Territory, by user: User) {
        let oldOwnerID = territory.ownerID
        let wasContested = territory.isContested

        territory.attack(by: user.id.uuidString)

        // Notifications
        if let ownerID = oldOwnerID, ownerID != user.id.uuidString {
            // Si le territoire est maintenant neutre, c'est une perte
            if territory.isNeutral {
                notificationManager?.notifyTerritoryLost(territory: territory, capturedBy: user.username)
                print("⚔️ Territory lost notification sent to \(ownerID)")
            } else if !wasContested {
                // Première attaque - notifier que le territoire est attaqué
                notificationManager?.notifyTerritoryAttacked(territory: territory, attackerName: user.username)
                print("⚔️ Territory attack notification sent to \(ownerID)")
            }
        }
    }

    private func checkLevelUp(_ user: User) {
        // Le level up est géré dans User.addXP()
        // On vérifie juste si un level up vient de se produire
        if user.levelProgress.currentLevelXP < xpGainedThisSession {
            pendingLevelUp = true
        }
    }

    // MARK: - Session Management

    /// Démarre une nouvelle session de tracking
    func startSession() {
        visitedTilesThisSession.removeAll()
        capturedThisSession = 0
        xpGainedThisSession = 0
        pendingCaptureNotifications.removeAll()
        pendingLevelUp = false

        print("🚀 Territory tracking session started")
    }

    /// Termine la session et retourne le résumé
    func endSession() -> SessionSummary {
        let summary = SessionSummary(
            territoriesCaptured: capturedThisSession,
            xpGained: xpGainedThisSession,
            tilesVisited: visitedTilesThisSession.count
        )

        // Reset
        visitedTilesThisSession.removeAll()
        capturedThisSession = 0
        xpGainedThisSession = 0

        try? modelContext.save()

        print("🏁 Session ended: \(summary.territoriesCaptured) territories, \(summary.xpGained) XP")

        return summary
    }

    /// Récupère les notifications en attente et les vide
    func getAndClearNotifications() -> [String] {
        let notifications = pendingCaptureNotifications
        pendingCaptureNotifications.removeAll()
        return notifications
    }

    // MARK: - Maintenance

    /// Applique la décroissance naturelle à tous les territoires
    func applyDecayToAll() {
        let descriptor = FetchDescriptor<Territory>()
        let allTerritories = (try? modelContext.fetch(descriptor)) ?? []

        var changed = false
        for territory in allTerritories {
            if !territory.isNeutral {
                let oldStrength = territory.strengthPoints
                territory.applyDecay()

                if territory.strengthPoints != oldStrength {
                    changed = true

                    // Si le territoire est maintenant neutre, mettre à jour le count
                    if territory.isNeutral && territory.ownerID == currentUser?.id.uuidString {
                        currentUser?.loseTerritory()
                    }
                }
            }
        }

        if changed {
            try? modelContext.save()
            print("🕐 Decay applied to all territories")
        }
    }

    /// Nettoie les territoires neutres loin de l'utilisateur (optimisation)
    func cleanupDistantTerritories(keepRadius: Double = 5000) {
        guard let userLocation = lastUpdateLocation else { return }

        let descriptor = FetchDescriptor<Territory>()
        let allTerritories = (try? modelContext.fetch(descriptor)) ?? []

        var deleted = 0
        for territory in allTerritories {
            if territory.isNeutral {
                let distance = territory.distance(from: userLocation)
                if distance > keepRadius {
                    modelContext.delete(territory)
                    deleted += 1
                }
            }
        }

        if deleted > 0 {
            try? modelContext.save()
            print("🗑️ Cleaned up \(deleted) distant neutral territories")
        }
    }

    // MARK: - Statistics

    func getStatistics() -> TerritoryStatistics {
        let owned = getOwnedTerritories()

        return TerritoryStatistics(
            totalOwned: owned.count,
            totalStrength: owned.reduce(0) { $0 + $1.strengthPoints },
            averageStrength: owned.isEmpty ? 0 : owned.reduce(0) { $0 + $1.strengthPoints } / owned.count,
            endangered: owned.filter { $0.strengthPoints < 30 }.count,
            contested: owned.filter { $0.isContested }.count
        )
    }
}

// MARK: - Supporting Types

struct SessionSummary {
    let territoriesCaptured: Int
    let xpGained: Int
    let tilesVisited: Int
}

struct TerritoryStatistics {
    let totalOwned: Int
    let totalStrength: Int
    let averageStrength: Int
    let endangered: Int
    let contested: Int
}
