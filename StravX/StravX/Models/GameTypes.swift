//
//  GameTypes.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Team Color

enum TeamColor: String, Codable, CaseIterable {
    case red = "Rouge"
    case blue = "Bleu"
    case green = "Vert"
    case neutral = "Neutre"

    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .neutral: return .gray
        }
    }

    var uiColor: UIColor {
        switch self {
        case .red: return UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // #FF3B30
        case .blue: return UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // #007AFF
        case .green: return UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0) // #34C759
        case .neutral: return UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0) // #8E8E93
        }
    }

    var displayName: String {
        switch self {
        case .red: return "🔥 Équipe Feu"
        case .blue: return "💧 Équipe Eau"
        case .green: return "🌿 Équipe Terre"
        case .neutral: return "⚪ Neutre"
        }
    }
}

// MARK: - Badge Types

enum BadgeType: String, Codable {
    // Distance
    case firstKm = "first_km"
    case marathon = "marathon"
    case ultraRunner = "ultra_runner"
    case globeTrotter = "globe_trotter"

    // Territoires
    case firstTerritory = "first_territory"
    case cartographer = "cartographer"
    case baron = "baron"
    case emperor = "emperor"

    // Streaks
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    case streak100 = "streak_100"

    // Spéciaux
    case cityDomination = "city_domination"
    case topRegion = "top_region"
    case defender = "defender"
    case conqueror = "conqueror"

    var icon: String {
        switch self {
        case .firstKm: return "flag.fill"
        case .marathon: return "figure.run"
        case .ultraRunner: return "bolt.fill"
        case .globeTrotter: return "globe.europe.africa.fill"
        case .firstTerritory: return "mappin.circle.fill"
        case .cartographer: return "map.fill"
        case .baron: return "crown.fill"
        case .emperor: return "crown"
        case .streak7: return "flame.fill"
        case .streak30: return "flame.fill"
        case .streak100: return "flame.fill"
        case .cityDomination: return "building.2.fill"
        case .topRegion: return "trophy.fill"
        case .defender: return "shield.fill"
        case .conqueror: return "flag.fill"
        }
    }

    var title: String {
        switch self {
        case .firstKm: return "Premier Kilomètre"
        case .marathon: return "Marathon"
        case .ultraRunner: return "Ultra Runner"
        case .globeTrotter: return "Globe-Trotter"
        case .firstTerritory: return "Premier Territoire"
        case .cartographer: return "Cartographe"
        case .baron: return "Baron"
        case .emperor: return "Empereur"
        case .streak7: return "Série de 7 jours"
        case .streak30: return "Série de 30 jours"
        case .streak100: return "Série de 100 jours"
        case .cityDomination: return "Domination Urbaine"
        case .topRegion: return "Top Régional"
        case .defender: return "Gardien"
        case .conqueror: return "Conquérant"
        }
    }

    var description: String {
        switch self {
        case .firstKm: return "Parcourir ton premier kilomètre"
        case .marathon: return "Parcourir 42 km au total"
        case .ultraRunner: return "Parcourir 100 km au total"
        case .globeTrotter: return "Parcourir 1000 km au total"
        case .firstTerritory: return "Capturer ton premier territoire"
        case .cartographer: return "Posséder 10 territoires"
        case .baron: return "Posséder 50 territoires"
        case .emperor: return "Posséder 100 territoires simultanément"
        case .streak7: return "Faire une activité 7 jours d'affilée"
        case .streak30: return "Faire une activité 30 jours d'affilée"
        case .streak100: return "Faire une activité 100 jours d'affilée"
        case .cityDomination: return "Contrôler 100% de ta ville"
        case .topRegion: return "Atteindre le top 10 de ta région"
        case .defender: return "Défendre avec succès 10 territoires"
        case .conqueror: return "Capturer 100 territoires ennemis"
        }
    }

    var color: Color {
        switch self {
        case .firstKm, .firstTerritory: return .green
        case .marathon, .cartographer, .streak7: return .blue
        case .ultraRunner, .baron, .streak30, .defender: return .purple
        case .globeTrotter, .emperor, .streak100, .cityDomination, .topRegion, .conqueror: return .orange
        }
    }
}

// MARK: - Badge Model

struct Badge: Codable, Identifiable, Hashable {
    let id: UUID
    let type: BadgeType
    let unlockedAt: Date

    init(type: BadgeType, unlockedAt: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = unlockedAt
    }
}

// MARK: - Achievement Model

struct Achievement: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let xpReward: Int
    var isCompleted: Bool {
        currentValue >= targetValue
    }
    var progress: Double {
        Double(currentValue) / Double(targetValue)
    }

    init(title: String, description: String, targetValue: Int, currentValue: Int = 0, xpReward: Int) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.xpReward = xpReward
    }
}

// MARK: - Quest Model

struct Quest: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let xpReward: Int
    let expiresAt: Date
    var isCompleted: Bool {
        currentValue >= targetValue
    }
    var isExpired: Bool {
        Date() > expiresAt
    }
    var progress: Double {
        Double(currentValue) / Double(targetValue)
    }

    init(title: String, description: String, targetValue: Int, currentValue: Int = 0, xpReward: Int, expiresAt: Date) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.xpReward = xpReward
        self.expiresAt = expiresAt
    }

    /// Crée une quête quotidienne aléatoire
    static func createDailyQuest() -> Quest {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let midnight = Calendar.current.startOfDay(for: tomorrow)

        let quests: [(String, String, Int, Int)] = [
            ("Parcourir 5 km", "Marche, cours ou pédale pour parcourir 5 km", 5000, 50),
            ("Capturer 3 zones", "Conquiers 3 nouveaux territoires", 3, 75),
            ("Renforcer 5 zones", "Passe dans 5 de tes territoires existants", 5, 40),
            ("20 minutes d'activité", "Reste actif pendant au moins 20 minutes", 1200, 30),
            ("Explorer ta ville", "Visite 10 zones différentes", 10, 60)
        ]

        let quest = quests.randomElement()!
        return Quest(
            title: quest.0,
            description: quest.1,
            targetValue: quest.2,
            xpReward: quest.3,
            expiresAt: midnight
        )
    }
}

// MARK: - Capture Event

struct CaptureEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let userID: String
    let userName: String
    let teamColor: TeamColor
    let capturedAt: Date
    let previousOwner: String?

    init(userID: String, userName: String, teamColor: TeamColor, capturedAt: Date = Date(), previousOwner: String? = nil) {
        self.id = UUID()
        self.userID = userID
        self.userName = userName
        self.teamColor = teamColor
        self.capturedAt = capturedAt
        self.previousOwner = previousOwner
    }
}

// MARK: - Level System

struct LevelSystem {
    static func xpForLevel(_ level: Int) -> Int {
        // Progression exponentielle
        switch level {
        case 1...5: return level * 200           // 200, 400, 600, 800, 1000
        case 6...10: return 1000 + (level - 5) * 400  // 1400, 1800, ..., 3000
        case 11...15: return 3000 + (level - 10) * 800 // 3800, 4600, ..., 7000
        case 16...20: return 7000 + (level - 15) * 1500 // 8500, 10000, ..., 14500
        default: return 14500 + (level - 20) * 2500 // 17000, 19500, ...
        }
    }

    static func totalXPForLevel(_ level: Int) -> Int {
        var total = 0
        for l in 1..<level {
            total += xpForLevel(l)
        }
        return total
    }

    static func levelFromXP(_ xp: Int) -> Int {
        var level = 1
        var totalXP = 0

        while totalXP + xpForLevel(level) <= xp {
            totalXP += xpForLevel(level)
            level += 1
        }

        return level
    }

    static func progressInCurrentLevel(xp: Int) -> (currentLevelXP: Int, neededForNext: Int, progress: Double) {
        let level = levelFromXP(xp)
        let totalXPForCurrentLevel = totalXPForLevel(level)
        let xpInCurrentLevel = xp - totalXPForCurrentLevel
        let xpNeededForNext = xpForLevel(level)
        let progress = Double(xpInCurrentLevel) / Double(xpNeededForNext)

        return (xpInCurrentLevel, xpNeededForNext, progress)
    }

    static func rankTitle(for level: Int) -> String {
        switch level {
        case 1...5: return "Explorateur"
        case 6...10: return "Aventurier"
        case 11...15: return "Conquérant"
        case 16...20: return "Champion"
        default: return "Légende"
        }
    }
}
