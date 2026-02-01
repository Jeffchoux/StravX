//
//  Territory.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Territory {
    // MARK: - Identité

    var tileID: String // Identifiant unique de la GeoTile
    var centerLat: Double
    var centerLon: Double
    var zoom: Int

    // MARK: - Propriété

    var ownerID: String? // UUID de l'utilisateur propriétaire
    var ownerName: String? // Pseudo affiché
    var capturedAt: Date?

    // MARK: - Force et défense

    var strengthPoints: Int = 0 // Points de défense (0-100)
    var lastReinforcedAt: Date? // Dernière visite du propriétaire
    var isContested: Bool = false // Zone actuellement attaquée
    var contestedBy: String? // UserID de l'attaquant

    // MARK: - Historique

    var captureCount: Int = 0 // Nombre de fois capturée
    var lastCapturedBy: String? // Dernier capturant
    var captureHistoryData: Data? // JSON encodé de [CaptureEvent]

    // MARK: - Initialisation

    init(tile: GeoTile, ownerID: String? = nil, ownerName: String? = nil) {
        self.tileID = tile.tileID
        self.centerLat = tile.centerLat
        self.centerLon = tile.centerLon
        self.zoom = tile.zoom
        self.ownerID = ownerID
        self.ownerName = ownerName

        if ownerID != nil {
            self.capturedAt = Date()
            self.strengthPoints = 10 // Force initiale
        }
    }

    // MARK: - Propriétés calculées

    var isNeutral: Bool {
        ownerID == nil
    }

    var geoTile: GeoTile {
        GeoTile(tileID: tileID, centerLat: centerLat, centerLon: centerLon, zoom: zoom)
    }

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
    }

    var captureHistory: [CaptureEvent] {
        guard let data = captureHistoryData else { return [] }
        return (try? JSONDecoder().decode([CaptureEvent].self, from: data)) ?? []
    }

    var daysSinceLastReinforced: Int {
        guard let lastReinforced = lastReinforcedAt else { return 999 }
        let days = Calendar.current.dateComponents([.day], from: lastReinforced, to: Date()).day ?? 0
        return days
    }

    var isWeak: Bool {
        strengthPoints < 30
    }

    var isStrong: Bool {
        strengthPoints >= 70
    }

    /// Indicateur de danger (1-5, 5 = très en danger)
    var dangerLevel: Int {
        if isNeutral { return 0 }
        if strengthPoints >= 80 { return 1 }
        if strengthPoints >= 60 { return 2 }
        if strengthPoints >= 40 { return 3 }
        if strengthPoints >= 20 { return 4 }
        return 5
    }

    // MARK: - Actions

    /// Capture cette zone par un nouveau propriétaire
    func capture(by userID: String, userName: String) {
        let wasNeutral = isNeutral
        _ = ownerID // Ancien propriétaire (pour historique futur)

        // Mettre à jour la propriété
        self.ownerID = userID
        self.ownerName = userName
        self.capturedAt = Date()
        self.lastReinforcedAt = Date()
        self.captureCount += 1
        self.lastCapturedBy = userID

        // Force initiale selon le type de capture
        if wasNeutral {
            self.strengthPoints = 10 // Zone neutre = faible départ
        } else {
            self.strengthPoints = 25 // Zone conquise = force moyenne
        }

        // Réinitialiser le statut de contestation
        self.isContested = false
        self.contestedBy = nil

        // TODO: Réactiver l'historique quand CaptureEvent sera adapté au système de teams privées
        // Pour l'instant on utilise captureCount et lastCapturedBy
    }

    /// Renforce cette zone (le propriétaire repasse dedans)
    func reinforce() {
        guard !isNeutral else { return }

        lastReinforcedAt = Date()
        strengthPoints = min(100, strengthPoints + 10) // +10 points, max 100

        // Si la zone était contestée, la défense réussit
        if isContested {
            isContested = false
            contestedBy = nil
            // Bonus de défense réussie
            strengthPoints = min(100, strengthPoints + 20)
        }
    }

    /// Attaque cette zone (réduit sa force)
    func attack(by userID: String) {
        guard !isNeutral else { return }
        guard ownerID != userID else { return } // On ne peut pas s'attaquer soi-même

        isContested = true
        contestedBy = userID

        // Réduire la force de 50%
        strengthPoints = max(0, strengthPoints / 2)

        // Si la force tombe à 0, la zone devient neutre
        if strengthPoints == 0 {
            ownerID = nil
            ownerName = nil
            capturedAt = nil
            isContested = false
            contestedBy = nil
        }
    }

    /// Décroissance naturelle de la force (1 point par jour)
    func applyDecay() {
        guard !isNeutral else { return }

        let days = daysSinceLastReinforced
        if days > 0 {
            strengthPoints = max(0, strengthPoints - days)

            // Si la force tombe à 0, la zone devient neutre
            if strengthPoints == 0 {
                ownerID = nil
                ownerName = nil
                capturedAt = nil
            }
        }
    }

    /// Points XP gagnés en capturant cette zone
    func captureXP(isAttack: Bool) -> Int {
        if isNeutral || !isAttack {
            return 10 // Zone neutre ou renforcement
        } else if strengthPoints > 50 {
            return 50 // Zone très forte = grosse récompense
        } else {
            return 25 // Zone ennemie standard
        }
    }

    // MARK: - Historique

    private func addCaptureEvent(_ event: CaptureEvent) {
        var history = captureHistory
        history.append(event)

        // Garder seulement les 10 derniers événements
        if history.count > 10 {
            history = Array(history.suffix(10))
        }

        captureHistoryData = try? JSONEncoder().encode(history)
    }

    // MARK: - Utilitaires

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        geoTile.contains(coordinate)
    }

    func distance(from coordinate: CLLocationCoordinate2D) -> Double {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let tileLocation = CLLocation(latitude: centerLat, longitude: centerLon)
        return location.distance(from: tileLocation)
    }
}

// MARK: - Extensions

extension Territory {
    /// Description textuelle pour debug
    var debugDescription: String {
        """
        Territory(\(tileID))
        - Owner: \(ownerName ?? "None")
        - Strength: \(strengthPoints)/100
        - Contested: \(isContested)
        - Captured: \(captureCount) times
        """
    }

    /// Emoji représentant l'état de la zone
    var statusEmoji: String {
        if isContested {
            return "⚔️"
        } else if isNeutral {
            return "⚪"
        } else if strengthPoints >= 80 {
            return "🛡️"
        } else if strengthPoints < 30 {
            return "⚠️"
        } else {
            return "📍" // Zone capturée standard
        }
    }
}
