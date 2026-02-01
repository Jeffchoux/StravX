//
//  Team.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class Team {
    // MARK: - Identité

    var id: UUID
    var name: String
    var code: String // Code d'invitation unique (ex: "STRVX-A3B9")
    var creatorID: String // UUID du créateur
    var createdAt: Date

    // MARK: - Membres

    var memberIDsData: Data? // JSON encodé de [String] - UUIDs des membres

    // MARK: - Configuration

    var isPrivate: Bool = true // Team privée par défaut
    var maxMembers: Int = 10 // Maximum 10 membres

    // MARK: - Statistiques

    var totalDistance: Double = 0.0 // Distance totale de la team (en mètres)
    var totalActivities: Int = 0
    var totalTerritories: Int = 0

    // MARK: - Initialisation

    init(name: String, creatorID: String, code: String? = nil) {
        self.id = UUID()
        self.name = name
        self.creatorID = creatorID
        self.code = code ?? Team.generateCode()
        self.createdAt = Date()

        // Le créateur est automatiquement membre
        var members = [creatorID]
        self.memberIDsData = try? JSONEncoder().encode(members)
    }

    // MARK: - Propriétés calculées

    var memberIDs: [String] {
        get {
            guard let data = memberIDsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            memberIDsData = try? JSONEncoder().encode(newValue)
        }
    }

    var memberCount: Int {
        memberIDs.count
    }

    var isFull: Bool {
        memberCount >= maxMembers
    }

    var canAddMember: Bool {
        !isFull
    }

    // MARK: - Actions

    /// Ajoute un membre à la team
    func addMember(_ userID: String) -> Bool {
        guard canAddMember else { return false }
        guard !memberIDs.contains(userID) else { return false }

        var members = memberIDs
        members.append(userID)
        memberIDs = members

        return true
    }

    /// Retire un membre de la team
    func removeMember(_ userID: String) -> Bool {
        guard userID != creatorID else { return false } // Le créateur ne peut pas être retiré

        var members = memberIDs
        if let index = members.firstIndex(of: userID) {
            members.remove(at: index)
            memberIDs = members
            return true
        }

        return false
    }

    /// Met à jour les stats de la team
    func updateStats(distance: Double, activities: Int, territories: Int) {
        totalDistance += distance
        totalActivities += activities
        totalTerritories = territories
    }

    // MARK: - Génération de code

    /// Génère un code d'invitation unique au format "STRVX-XXXX"
    static func generateCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Sans I, O, 0, 1 pour éviter confusion
        let randomPart = String((0..<4).map { _ in characters.randomElement()! })
        return "STRVX-\(randomPart)"
    }
}

// MARK: - Extensions

extension Team {
    var debugDescription: String {
        """
        Team(\(name))
        - Code: \(code)
        - Members: \(memberCount)/\(maxMembers)
        - Creator: \(creatorID)
        - Distance: \(String(format: "%.1f", totalDistance/1000)) km
        - Activities: \(totalActivities)
        """
    }
}
