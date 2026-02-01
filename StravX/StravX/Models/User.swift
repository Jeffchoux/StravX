//
//  User.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class User {
    // MARK: - Identité

    var id: UUID
    var username: String
    var createdAt: Date

    // MARK: - Teams (compétitions entre amis)

    var teamIDs: Data? // JSON encodé de [String] - IDs des teams privées
    var personalColor: String = "blue" // Couleur personnelle pour l'affichage (blue, green, red, etc.)

    // MARK: - Progression

    var level: Int = 1
    var totalXP: Int = 0
    var totalDistance: Double = 0.0 // en mètres
    var totalDuration: TimeInterval = 0.0 // en secondes
    var totalActivities: Int = 0

    // MARK: - Territoires

    var territoriesOwned: Int = 0 // Nombre actuel de territoires possédés
    var territoriesCaptured: Int = 0 // Total historique de captures
    var territoriesDefended: Int = 0 // Nombre de défenses réussies
    var territoriesLost: Int = 0 // Nombre de territoires perdus

    // MARK: - Streaks

    var currentStreak: Int = 0 // Jours consécutifs d'activité
    var longestStreak: Int = 0
    var lastActivityDate: Date?

    // MARK: - Badges et Achievements

    var badgesData: Data? // JSON encodé de [Badge]
    var achievementsData: Data? // JSON encodé de [Achievement]
    var questsData: Data? // JSON encodé de [Quest]

    // MARK: - Stats

    var bestActivityDistance: Double = 0.0
    var bestActivityDuration: TimeInterval = 0.0
    var fastestSpeed: Double = 0.0 // km/h

    // MARK: - Social

    var friendsData: Data? // JSON encodé de [String] (UUIDs des amis)
    var publicProfile: Bool = true

    // MARK: - Initialisation

    init(username: String, personalColor: String = "blue") {
        self.id = UUID()
        self.username = username
        self.personalColor = personalColor
        self.createdAt = Date()
        self.lastActivityDate = Date()

        // Créer quelques quêtes de départ
        var quests: [Quest] = []
        for _ in 0..<3 {
            quests.append(Quest.createDailyQuest())
        }
        self.questsData = try? JSONEncoder().encode(quests)
    }

    // MARK: - Propriétés calculées

    var color: Color {
        // Retourne la couleur personnelle de l'utilisateur pour l'affichage
        switch personalColor {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }

    var teamList: [String] {
        get {
            guard let data = teamIDs else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            teamIDs = try? JSONEncoder().encode(newValue)
        }
    }

    var badges: [Badge] {
        get {
            guard let data = badgesData else { return [] }
            return (try? JSONDecoder().decode([Badge].self, from: data)) ?? []
        }
        set {
            badgesData = try? JSONEncoder().encode(newValue)
        }
    }

    var achievements: [Achievement] {
        get {
            guard let data = achievementsData else { return createDefaultAchievements() }
            return (try? JSONDecoder().decode([Achievement].self, from: data)) ?? createDefaultAchievements()
        }
        set {
            achievementsData = try? JSONEncoder().encode(newValue)
        }
    }

    var quests: [Quest] {
        get {
            guard let data = questsData else { return [] }
            return (try? JSONDecoder().decode([Quest].self, from: data)) ?? []
        }
        set {
            questsData = try? JSONEncoder().encode(newValue)
        }
    }

    var friends: [String] {
        get {
            guard let data = friendsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            friendsData = try? JSONEncoder().encode(newValue)
        }
    }

    var levelProgress: (currentLevelXP: Int, neededForNext: Int, progress: Double) {
        LevelSystem.progressInCurrentLevel(xp: totalXP)
    }

    var rankTitle: String {
        LevelSystem.rankTitle(for: level)
    }

    var totalDistanceKm: Double {
        totalDistance / 1000
    }

    var averageSpeed: Double {
        guard totalDuration > 0 else { return 0 }
        let hours = totalDuration / 3600
        return totalDistanceKm / hours
    }

    // MARK: - Actions

    /// Ajoute de l'XP et vérifie si l'utilisateur monte de niveau
    @discardableResult
    func addXP(_ xp: Int) -> Bool {
        let oldLevel = level
        totalXP += xp

        // Recalculer le niveau
        level = LevelSystem.levelFromXP(totalXP)

        // Retourne true si level up
        return level > oldLevel
    }

    /// Enregistre une nouvelle activité
    func recordActivity(distance: Double, duration: TimeInterval, maxSpeed: Double) {
        totalDistance += distance
        totalDuration += duration
        totalActivities += 1

        // Mettre à jour les records
        if distance > bestActivityDistance {
            bestActivityDistance = distance
        }
        if duration > bestActivityDuration {
            bestActivityDuration = duration
        }
        if maxSpeed > fastestSpeed {
            fastestSpeed = maxSpeed
        }

        // Mettre à jour la streak
        updateStreak()

        // Vérifier les achievements distance
        checkAchievements()
    }

    /// Met à jour la streak quotidienne
    private func updateStreak() {
        let now = Date()
        let calendar = Calendar.current

        guard let lastDate = lastActivityDate else {
            // Première activité
            currentStreak = 1
            longestStreak = 1
            lastActivityDate = now
            return
        }

        let daysSinceLastActivity = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: now)).day ?? 0

        if daysSinceLastActivity == 0 {
            // Même jour, ne rien changer
            return
        } else if daysSinceLastActivity == 1 {
            // Jour consécutif, augmenter la streak
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            // Streak cassée
            currentStreak = 1
        }

        lastActivityDate = now

        // Vérifier les badges de streak
        checkStreakBadges()
    }

    /// Capture un territoire
    func captureTerritory(xpGained: Int) {
        territoriesCaptured += 1
        territoriesOwned += 1
        addXP(xpGained)

        // Vérifier les badges de territoire
        checkTerritoryBadges()
    }

    /// Perd un territoire
    func loseTerritory() {
        territoriesOwned = max(0, territoriesOwned - 1)
        territoriesLost += 1
    }

    /// Défend avec succès un territoire
    func defendTerritory() {
        territoriesDefended += 1
        addXP(50) // Bonus défense

        // Check defender badge
        if territoriesDefended >= 10 {
            unlockBadge(.defender)
        }
    }

    /// Débloque un badge
    func unlockBadge(_ type: BadgeType) {
        var currentBadges = badges
        guard !currentBadges.contains(where: { $0.type == type }) else {
            return // Badge déjà débloqué
        }

        let badge = Badge(type: type)
        currentBadges.append(badge)
        badges = currentBadges

        // Bonus XP pour le badge
        addXP(100)
    }

    /// Vérifie et débloque les achievements
    private func checkAchievements() {
        var currentAchievements = achievements
        var changed = false

        for i in 0..<currentAchievements.count {
            // Mettre à jour la progression
            if !currentAchievements[i].isCompleted {
                let title = currentAchievements[i].title

                if title.contains("distance") {
                    currentAchievements[i].currentValue = Int(totalDistanceKm)
                } else if title.contains("territoire") {
                    currentAchievements[i].currentValue = territoriesCaptured
                } else if title.contains("activité") {
                    currentAchievements[i].currentValue = totalActivities
                }

                // Si complété, donner la récompense
                if currentAchievements[i].isCompleted {
                    addXP(currentAchievements[i].xpReward)
                    changed = true
                }
            }
        }

        if changed {
            achievements = currentAchievements
        }
    }

    /// Vérifie et débloque les badges de distance
    private func checkDistanceBadges() {
        if totalDistanceKm >= 1 {
            unlockBadge(.firstKm)
        }
        if totalDistanceKm >= 42 {
            unlockBadge(.marathon)
        }
        if totalDistanceKm >= 100 {
            unlockBadge(.ultraRunner)
        }
        if totalDistanceKm >= 1000 {
            unlockBadge(.globeTrotter)
        }
    }

    /// Vérifie et débloque les badges de territoire
    private func checkTerritoryBadges() {
        if territoriesCaptured >= 1 {
            unlockBadge(.firstTerritory)
        }
        if territoriesOwned >= 10 {
            unlockBadge(.cartographer)
        }
        if territoriesOwned >= 50 {
            unlockBadge(.baron)
        }
        if territoriesOwned >= 100 {
            unlockBadge(.emperor)
        }
    }

    /// Vérifie et débloque les badges de streak
    private func checkStreakBadges() {
        if currentStreak >= 7 {
            unlockBadge(.streak7)
        }
        if currentStreak >= 30 {
            unlockBadge(.streak30)
        }
        if currentStreak >= 100 {
            unlockBadge(.streak100)
        }
    }

    /// Met à jour les quêtes quotidiennes
    func updateQuests(distanceMeters: Double, territoriesCapturedCount: Int) {
        var currentQuests = quests
        var changed = false

        for i in 0..<currentQuests.count {
            guard !currentQuests[i].isCompleted && !currentQuests[i].isExpired else { continue }

            let title = currentQuests[i].title

            if title.contains("km") {
                currentQuests[i].currentValue = Int(distanceMeters)
                if currentQuests[i].isCompleted {
                    addXP(currentQuests[i].xpReward)
                    changed = true
                }
            } else if title.contains("zone") {
                currentQuests[i].currentValue = territoriesCapturedCount
                if currentQuests[i].isCompleted {
                    addXP(currentQuests[i].xpReward)
                    changed = true
                }
            }
        }

        if changed {
            quests = currentQuests
        }

        // Générer de nouvelles quêtes quotidiennes si nécessaire
        refreshDailyQuests()
    }

    /// Rafraîchit les quêtes quotidiennes expirées
    private func refreshDailyQuests() {
        var currentQuests = quests.filter { !$0.isExpired }

        // Ajouter de nouvelles quêtes pour atteindre 3
        while currentQuests.count < 3 {
            currentQuests.append(Quest.createDailyQuest())
        }

        quests = currentQuests
    }

    // MARK: - Achievements par défaut

    private func createDefaultAchievements() -> [Achievement] {
        return [
            Achievement(title: "Premier pas", description: "Parcourir 1 km", targetValue: 1, xpReward: 50),
            Achievement(title: "Marathonien", description: "Parcourir 42 km au total", targetValue: 42, xpReward: 200),
            Achievement(title: "Centurion", description: "Parcourir 100 km au total", targetValue: 100, xpReward: 500),
            Achievement(title: "Conquérant", description: "Capturer 10 territoires", targetValue: 10, xpReward: 150),
            Achievement(title: "Empereur", description: "Capturer 50 territoires", targetValue: 50, xpReward: 300),
            Achievement(title: "Actif", description: "Faire 10 activités", targetValue: 10, xpReward: 100),
            Achievement(title: "Passionné", description: "Faire 50 activités", targetValue: 50, xpReward: 250)
        ]
    }
}

// MARK: - Extensions

extension User {
    var debugDescription: String {
        """
        User(\(username))
        - Level \(level) (\(rankTitle))
        - XP: \(totalXP)
        - Distance: \(String(format: "%.1f", totalDistanceKm)) km
        - Territories: \(territoriesOwned) owned, \(territoriesCaptured) total
        - Streak: \(currentStreak) days (best: \(longestStreak))
        - Badges: \(badges.count)
        """
    }
}
