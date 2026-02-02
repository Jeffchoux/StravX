//
//  LocationManager.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import CoreLocation
import Combine
import UIKit

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    // État actuel
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isAuthorized: Bool { authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways }
    var isDenied: Bool { authorizationStatus == .denied || authorizationStatus == .restricted }
    var isNotDetermined: Bool { authorizationStatus == .notDetermined }
    var permissionMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Localisation non configurée. Veuillez autoriser l'accès."
        case .restricted:
            return "L'accès à la localisation est restreint sur cet appareil."
        case .denied:
            return "L'accès à la localisation est refusé. Veuillez l'activer dans les réglages."
        case .authorizedWhenInUse:
            return "Localisation autorisée pendant l'utilisation."
        case .authorizedAlways:
            return "Localisation toujours autorisée."
        @unknown default:
            return "État de localisation inconnu."
        }
    }

    // Tracking d'activité
    var isTracking = false
    var trackingStartTime: Date?
    var totalDistance: Double = 0.0 // en mètres
    var currentSpeed: Double = 0.0 // en m/s
    var maxSpeed: Double = 0.0 // en m/s - vitesse maximale enregistrée
    var routeCoordinates: [CLLocationCoordinate2D] = []

    private var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self

        // 🔋 OPTIMISATION BATTERIE : Précision économique par défaut
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = AppConstants.Location.idleDistanceFilter

        // 🔋 Background updates DÉSACTIVÉS par défaut (activé seulement pendant une activité)
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true // Économie d'énergie

        authorizationStatus = locationManager.authorizationStatus

        AppLogger.info("LocationManager initialized in power-saving mode", category: AppLogger.location)
        AppLogger.debug("Authorization status: \(authorizationStatus.rawValue)", category: AppLogger.location)
    }

    // MARK: - Authorization

    func requestAuthorization() {
        AppLogger.info("Requesting location authorization", category: AppLogger.location)
        AppLogger.debug("Current status: \(authorizationStatus.rawValue)", category: AppLogger.location)

        switch authorizationStatus {
        case .notDetermined:
            // Demander la permission pour la première fois
            AppLogger.info("Requesting when-in-use authorization", category: AppLogger.location)
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            AppLogger.info("Already authorized for when-in-use", category: AppLogger.location)
        case .authorizedAlways:
            AppLogger.info("Already authorized always", category: AppLogger.location)
        case .denied, .restricted:
            AppLogger.warning("Location access denied or restricted", category: AppLogger.location)
        @unknown default:
            break
        }
    }

    func requestAlwaysAuthorization() {
        // Méthode séparée pour demander la permission "toujours" si nécessaire
        if authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    func openSettings() {
        // Ouvrir les réglages de l'app pour permettre à l'utilisateur d'activer la localisation
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 🔋 OPTIMISATION : NE PAS démarrer automatiquement le GPS
            // Le GPS sera activé uniquement quand l'utilisateur lance une activité
            AppLogger.info("\(AppLogger.success) Location authorization granted (GPS idle for battery saving)", category: AppLogger.location)
        case .denied, .restricted:
            AppLogger.warning("\(AppLogger.failure) Location access denied", category: AppLogger.location)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Location Updates

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location
        currentSpeed = max(0, location.speed) // speed en m/s, on ignore les valeurs négatives

        // Mettre à jour la vitesse maximale si on est en train de tracker
        if isTracking && currentSpeed > maxSpeed {
            maxSpeed = currentSpeed
        }

        // Si on est en train de tracker une activité
        if isTracking {
            addLocationToRoute(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.error("\(AppLogger.failure) Location error", error: error, category: AppLogger.location)
    }

    // MARK: - Activity Tracking

    func startTracking() {
        // Vérifier les permissions avant de commencer
        if !isAuthorized {
            if isNotDetermined {
                // Si les permissions n'ont jamais été demandées, les demander
                requestAuthorization()
                AppLogger.info("Requesting location authorization", category: AppLogger.location)
            } else if isDenied {
                // Si les permissions sont refusées, informer l'utilisateur
                AppLogger.warning("Location access denied. Please enable in Settings", category: AppLogger.location)
            }
            return
        }

        // Si on a les permissions, démarrer le tracking
        isTracking = true
        trackingStartTime = Date()
        totalDistance = 0.0
        maxSpeed = 0.0
        routeCoordinates = []
        lastLocation = nil

        // 🔋 OPTIMISATION : Activer haute précision SEULEMENT pendant l'activité
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // Meilleure précision pour sport
        locationManager.distanceFilter = AppConstants.Location.activeDistanceFilter
        locationManager.allowsBackgroundLocationUpdates = true // Permet le tracking en arrière-plan
        locationManager.pausesLocationUpdatesAutomatically = false // Empêche la pause automatique
        locationManager.showsBackgroundLocationIndicator = true

        locationManager.startUpdatingLocation()
        AppLogger.info("\(AppLogger.locationIcon) Tracking started (high precision enabled)", category: AppLogger.location)
    }

    func stopTracking() {
        isTracking = false
        trackingStartTime = nil

        // 🔋 OPTIMISATION : Revenir en mode économie d'énergie après l'activité
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = AppConstants.Location.idleDistanceFilter
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = false

        locationManager.stopUpdatingLocation()
        AppLogger.info("\(AppLogger.locationIcon) Tracking stopped (power-saving mode enabled)", category: AppLogger.location)
    }

    func pauseTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        AppLogger.info("⏸️ Tracking paused", category: AppLogger.location)
    }

    func resumeTracking() {
        guard trackingStartTime != nil else { return }
        isTracking = true
        locationManager.startUpdatingLocation()
        AppLogger.info("▶️ Tracking resumed", category: AppLogger.location)
    }

    private func addLocationToRoute(_ location: CLLocation) {
        // Ajouter la coordonnée au parcours
        routeCoordinates.append(location.coordinate)

        // Calculer la distance depuis la dernière position
        if let last = lastLocation {
            let distance = location.distance(from: last)

            // Filtrer les valeurs aberrantes (plus de 100m entre 2 points = probablement une erreur GPS)
            if distance < AppConstants.Location.maxPointDistance {
                totalDistance += distance
            }
        }

        lastLocation = location
    }

    // MARK: - Computed Properties

    var elapsedTime: TimeInterval {
        guard let startTime = trackingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

    var distanceKm: Double {
        totalDistance / 1000
    }

    var speedKmh: Double {
        currentSpeed * 3.6 // conversion m/s en km/h
    }

    var maxSpeedKmh: Double {
        maxSpeed * 3.6 // conversion m/s en km/h
    }

    var avgSpeedKmh: Double {
        guard elapsedTime > 0 else { return 0 }
        let distanceKm = totalDistance / 1000
        let timeHours = elapsedTime / 3600
        return distanceKm / timeHours
    }

    var paceMinPerKm: Double {
        guard avgSpeedKmh > 0 else { return 0 }
        return 60 / avgSpeedKmh // minutes par km
    }

    // MARK: - Helpers

    func reset() {
        stopTracking()
        totalDistance = 0.0
        maxSpeed = 0.0
        routeCoordinates = []
        lastLocation = nil
        trackingStartTime = nil
    }

    func encodeRoutePoints() -> Data? {
        do {
            let coordinates = routeCoordinates.map { coordinate in
                ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
            }
            return try JSONSerialization.data(withJSONObject: coordinates)
        } catch {
            AppLogger.error("Error encoding route", error: error, category: AppLogger.location)
            return nil
        }
    }

    static func decodeRoutePoints(_ data: Data) -> [CLLocationCoordinate2D]? {
        do {
            guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Double]] else {
                return nil
            }

            return array.compactMap { dict in
                guard let lat = dict["latitude"], let lon = dict["longitude"] else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        } catch {
            AppLogger.error("Error decoding route", error: error, category: AppLogger.location)
            return nil
        }
    }
}
