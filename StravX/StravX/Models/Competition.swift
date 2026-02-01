//
//  Competition.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Competition Type

enum CompetitionType: String, Codable {
    case individual = "individual" // Compétition individuelle entre amis
    case team = "team" // Compétition par équipes

    var displayName: String {
        switch self {
        case .individual: return "Individuelle"
        case .team: return "Par Équipes"
        }
    }

    var icon: String {
        switch self {
        case .individual: return "person.fill"
        case .team: return "person.3.fill"
        }
    }
}

// MARK: - Competition Duration

enum CompetitionDuration: Codable {
    case infinite
    case limited(days: Int)

    var displayName: String {
        switch self {
        case .infinite: return "Infinie"
        case .limited(let days): return "\(days) jours"
        }
    }

    var isInfinite: Bool {
        if case .infinite = self {
            return true
        }
        return false
    }
}

// MARK: - Competition Metric

enum CompetitionMetric: String, Codable {
    case distance = "distance" // Total distance parcourue
    case territories = "territories" // Nombre de territoires capturés
    case xp = "xp" // Total XP gagné
    case activities = "activities" // Nombre d'activités

    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .territories: return "Territoires"
        case .xp: return "XP"
        case .activities: return "Activités"
        }
    }

    var unit: String {
        switch self {
        case .distance: return "km"
        case .territories: return "zones"
        case .xp: return "XP"
        case .activities: return "activités"
        }
    }
}

// MARK: - Competition Model

@Model
final class Competition {
    // MARK: - Identité

    var id: UUID
    var name: String
    var creatorID: String // UUID du créateur
    var createdAt: Date

    // MARK: - Configuration

    var typeRaw: String // CompetitionType.rawValue
    var metricRaw: String // CompetitionMetric.rawValue
    var durationData: Data? // JSON encodé de CompetitionDuration

    // MARK: - Dates

    var startDate: Date
    var endDate: Date? // nil si infinie

    // MARK: - Participants

    var participantIDsData: Data? // JSON encodé de [String] - User IDs ou Team IDs
    var maxParticipants: Int = 20

    // MARK: - Statut

    var isActive: Bool = true
    var isEnded: Bool = false

    // MARK: - Initialisation

    init(name: String, creatorID: String, type: CompetitionType, metric: CompetitionMetric, duration: CompetitionDuration, startDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.creatorID = creatorID
        self.typeRaw = type.rawValue
        self.metricRaw = metric.rawValue
        self.durationData = try? JSONEncoder().encode(duration)
        self.startDate = startDate
        self.createdAt = Date()

        // Calculer endDate si duration limitée
        if case .limited(let days) = duration {
            self.endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)
        }

        // Le créateur est automatiquement participant
        let participants = [creatorID]
        self.participantIDsData = try? JSONEncoder().encode(participants)
    }

    // MARK: - Propriétés calculées

    var type: CompetitionType {
        CompetitionType(rawValue: typeRaw) ?? .individual
    }

    var metric: CompetitionMetric {
        CompetitionMetric(rawValue: metricRaw) ?? .distance
    }

    var duration: CompetitionDuration {
        guard let data = durationData else { return .infinite }
        return (try? JSONDecoder().decode(CompetitionDuration.self, from: data)) ?? .infinite
    }

    var participantIDs: [String] {
        get {
            guard let data = participantIDsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            participantIDsData = try? JSONEncoder().encode(newValue)
        }
    }

    var participantCount: Int {
        participantIDs.count
    }

    var isFull: Bool {
        participantCount >= maxParticipants
    }

    var canJoin: Bool {
        !isFull && isActive && !hasEnded
    }

    var hasEnded: Bool {
        if let endDate = endDate {
            return Date() > endDate
        }
        return false
    }

    var daysRemaining: Int? {
        guard let endDate = endDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }

    var progressPercentage: Double {
        guard let endDate = endDate else { return 0 }
        let total = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(1.0, max(0.0, elapsed / total))
    }

    // MARK: - Actions

    /// Ajoute un participant à la compétition
    func addParticipant(_ userID: String) -> Bool {
        guard canJoin else { return false }
        guard !participantIDs.contains(userID) else { return false }

        var participants = participantIDs
        participants.append(userID)
        participantIDs = participants

        return true
    }

    /// Retire un participant de la compétition
    func removeParticipant(_ userID: String) -> Bool {
        guard userID != creatorID else { return false } // Le créateur ne peut pas être retiré

        var participants = participantIDs
        if let index = participants.firstIndex(of: userID) {
            participants.remove(at: index)
            participantIDs = participants
            return true
        }

        return false
    }

    /// Termine la compétition
    func end() {
        isActive = false
        isEnded = true
    }
}

// MARK: - Extensions

extension Competition {
    var debugDescription: String {
        """
        Competition(\(name))
        - Type: \(type.displayName)
        - Metric: \(metric.displayName)
        - Participants: \(participantCount)/\(maxParticipants)
        - Duration: \(duration.displayName)
        - Status: \(isActive ? "Active" : "Inactive")
        """
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable, Comparable {
    let id: String // User ID ou Team ID
    let name: String
    let score: Double // Valeur selon la métrique
    let rank: Int

    static func < (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.score > rhs.score // Ordre décroissant (meilleur score en premier)
    }
}
