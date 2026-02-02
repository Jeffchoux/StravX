//
//  Activity.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Activity {
    var id: UUID
    var userID: UUID // ID de l'utilisateur qui a fait l'activité
    var date: Date
    var distance: Double // en mètres
    var duration: TimeInterval // en secondes
    var activityType: String // "running", "cycling", "walking", "driving"
    var avgSpeed: Double // km/h
    var maxSpeed: Double = 0.0 // km/h vitesse maximale
    var isValid: Bool = true // false si triche détectée
    var validationMessage: String? = nil // Message d'invalidation si triche
    var routePoints: Data? // Encoded array of CLLocationCoordinate2D

    init(userID: UUID = UUID(), distance: Double, duration: TimeInterval, activityType: String = "running", maxSpeed: Double = 0, routePoints: Data? = nil) {
        self.id = UUID()
        self.userID = userID
        self.date = Date()
        self.distance = distance
        self.duration = duration
        self.activityType = activityType
        self.maxSpeed = maxSpeed
        self.routePoints = routePoints

        // Calcul vitesse moyenne (km/h)
        if duration > 0 {
            let distanceKm = distance / 1000
            let durationHours = duration / 3600
            self.avgSpeed = distanceKm / durationHours
        } else {
            self.avgSpeed = 0
        }

        // Validation anti-triche
        let (valid, message) = validateActivity()
        self.isValid = valid
        self.validationMessage = message
    }

    private func validateActivity() -> (Bool, String?) {
        // Vitesses maximales réalistes par type d'activité
        let maxSpeedLimits: [String: Double] = [
            "walking": AppConstants.ActivityLimits.walkingMaxSpeed,
            "running": AppConstants.ActivityLimits.runningMaxSpeed,
            "cycling": AppConstants.ActivityLimits.cyclingMaxSpeed,
            "driving": 999.0  // Marqué comme invalide automatiquement
        ]

        // Si c'est de la conduite, invalide automatiquement
        if activityType == "driving" {
            return (false, "Activité motorisée détectée - Non autorisé")
        }

        // Vérifier la vitesse moyenne
        if let limit = maxSpeedLimits[activityType], avgSpeed > limit {
            return (false, "Vitesse moyenne anormale (\(String(format: "%.1f", avgSpeed)) km/h)")
        }

        // Vérifier la vitesse maximale
        if maxSpeed > 0 {
            if activityType == "walking" && maxSpeed > AppConstants.ActivityLimits.walkingMaxPeakSpeed {
                return (false, "Vitesse maximale trop élevée pour de la marche")
            } else if activityType == "running" && maxSpeed > AppConstants.ActivityLimits.runningMaxPeakSpeed {
                return (false, "Vitesse maximale irréaliste pour de la course")
            } else if activityType == "cycling" && maxSpeed > AppConstants.ActivityLimits.cyclingMaxPeakSpeed {
                return (false, "Vitesse maximale suspecte pour du vélo")
            }
        }

        // Vérifier la cohérence distance/temps
        if distance > 0 && duration > 0 {
            // Si moins de 10m parcourus en plus de 5 minutes, suspect
            if distance < AppConstants.ActivityLimits.minValidDistance && duration > AppConstants.ActivityLimits.maxDurationForMinDistance {
                return (false, "Distance trop faible pour la durée")
            }
        }

        return (true, nil)
    }

    // Propriétés calculées pour faciliter l'affichage
    var distanceKm: Double {
        distance / 1000
    }

    var distanceFormatted: String {
        String(format: "%.2f km", distanceKm)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    var speedFormatted: String {
        String(format: "%.1f km/h", avgSpeed)
    }

    var activityTypeIcon: String {
        switch activityType {
        case "running":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "walking":
            return "figure.walk"
        case "driving":
            return "car.fill"
        default:
            return "figure.run"
        }
    }

    var activityTypeLabel: String {
        switch activityType {
        case "running":
            return "Course"
        case "cycling":
            return "Vélo"
        case "walking":
            return "Marche"
        case "driving":
            return "Véhicule (Invalide)"
        default:
            return "Activité"
        }
    }

    // Propriétés pour l'affichage dans FriendsView
    var startDate: Date {
        date
    }

    var type: String {
        activityType
    }

    var typeIcon: String {
        activityTypeIcon
    }

    var typeColor: Color {
        switch activityType {
        case "running":
            return .blue
        case "cycling":
            return .green
        case "walking":
            return .orange
        case "driving":
            return .red
        default:
            return .gray
        }
    }

    var territoriesCaptured: Int {
        // Note: Territory capture tracking per activity not yet implemented
        // This will be added when implementing detailed activity analytics
        0
    }
}

// Extension pour SwiftUI Color
import SwiftUI

