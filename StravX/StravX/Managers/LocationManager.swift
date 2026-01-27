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
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Mise à jour tous les 10 mètres
        locationManager.allowsBackgroundLocationUpdates = true // Permet le tracking en arrière-plan
        locationManager.pausesLocationUpdatesAutomatically = false // Empêche la pause automatique
        authorizationStatus = locationManager.authorizationStatus

        print("🔵 LocationManager initialisé")
        print("🔵 Status actuel: \(authorizationStatus.rawValue)")
        print("🔵 isNotDetermined: \(isNotDetermined)")
        print("🔵 isAuthorized: \(isAuthorized)")
        print("🔵 isDenied: \(isDenied)")
    }

    // MARK: - Authorization

    func requestAuthorization() {
        print("🟢 requestAuthorization appelé")
        print("🟢 Status actuel: \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .notDetermined:
            // Demander la permission pour la première fois
            print("🟡 Demande de permission...")
            locationManager.requestWhenInUseAuthorization()
            print("🟡 requestWhenInUseAuthorization appelé")
        case .authorizedWhenInUse:
            // Si on a déjà la permission "pendant l'utilisation", on peut demander "toujours" si besoin
            // Pour une app de tracking sportif, on pourrait demander la permission "toujours" pour le tracking en arrière-plan
            // locationManager.requestAlwaysAuthorization() // Décommenter si besoin
            print("Already authorized for when in use")
        case .authorizedAlways:
            print("Already authorized always")
        case .denied, .restricted:
            print("Location access denied or restricted. Please enable location services in Settings.")
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
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
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
        print("Location error: \(error.localizedDescription)")
    }

    // MARK: - Activity Tracking

    func startTracking() {
        // Vérifier les permissions avant de commencer
        if !isAuthorized {
            if isNotDetermined {
                // Si les permissions n'ont jamais été demandées, les demander
                requestAuthorization()
                print("Requesting location authorization...")
            } else if isDenied {
                // Si les permissions sont refusées, informer l'utilisateur
                print("Location access denied. Please enable in Settings.")
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

        // Activer le mode arrière-plan pour le tracking sportif
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        trackingStartTime = nil
        locationManager.stopUpdatingLocation()
    }

    func pauseTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }

    func resumeTracking() {
        guard trackingStartTime != nil else { return }
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    private func addLocationToRoute(_ location: CLLocation) {
        // Ajouter la coordonnée au parcours
        routeCoordinates.append(location.coordinate)

        // Calculer la distance depuis la dernière position
        if let last = lastLocation {
            let distance = location.distance(from: last)

            // Filtrer les valeurs aberrantes (plus de 100m entre 2 points = probablement une erreur GPS)
            if distance < 100 {
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
            print("Error encoding route: \(error)")
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
            print("Error decoding route: \(error)")
            return nil
        }
    }
}
