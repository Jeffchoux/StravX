//
//  NewActivityView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreLocation

struct NewActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var locationManager = LocationManager()
    @State private var territoryManager: TerritoryManager?
    @State private var timer: Timer?
    @State private var territoryCheckTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isPaused = false
    @State private var showingDiscardAlert = false
    @State private var territoriesCaptured: Int = 0
    @State private var xpGained: Int = 0
    @State private var showingNotification: String? = nil
    @State private var showingSummary = false
    @State private var summaryData: (activity: Activity, territories: Int, xp: Int, levelUp: Bool, newLevel: Int)?
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let hapticSuccess = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Afficher alerte si permissions refusées
                    if !locationManager.isAuthorized && !locationManager.isNotDetermined {
                        VStack(spacing: 16) {
                            Image(systemName: "location.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red)

                            Text("Localisation désactivée")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(locationManager.permissionMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Ouvrir les réglages") {
                                locationManager.openSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(20)
                    } else {
                        // Stats principales
                        VStack(spacing: 24) {
                            StatCard(
                                title: "Distance",
                                value: String(format: "%.2f", locationManager.distanceKm),
                                unit: "km",
                                icon: "location.fill"
                            )

                            StatCard(
                                title: "Temps",
                                value: formatTime(elapsedTime),
                                unit: "",
                                icon: "clock.fill"
                            )

                            StatCard(
                                title: "Vitesse",
                                value: String(format: "%.1f", locationManager.speedKmh),
                                unit: "km/h",
                                icon: "speedometer"
                            )

                            // Stat Territoires capturés
                            if locationManager.isTracking || territoriesCaptured > 0 {
                                StatCard(
                                    title: "Territoires",
                                    value: "\(territoriesCaptured)",
                                    unit: "XP: \(xpGained)",
                                    icon: "map.fill"
                                )
                            }
                        }
                    }

                    // Notification de capture
                    if let notification = showingNotification {
                        Text(notification)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut, value: showingNotification)
                    }

                    Spacer()

                    // Boutons de contrôle
                    VStack(spacing: 20) {
                        if locationManager.isTracking {
                            // Bouton Pause principal
                            Button {
                                pauseTracking()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 40))
                                    Text("PAUSE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        } else if locationManager.trackingStartTime != nil {
                            // Bouton Resume principal
                            Button {
                                resumeTracking()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 40))
                                    Text("REPRENDRE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        } else {
                            // Bouton Start principal
                            Button {
                                startTracking()
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 40))
                                    Text("DÉMARRER")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(
                                    locationManager.isAuthorized ?
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : LinearGradient(
                                        colors: [.gray],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: locationManager.isAuthorized ? .green.opacity(0.3) : .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(!locationManager.isAuthorized)
                        }

                        // Bouton Stop secondaire (plus petit)
                        if locationManager.trackingStartTime != nil {
                            Button {
                                stopTracking()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.title3)
                                    Text("TERMINER")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(Color.red)
                                .cornerRadius(25)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationTitle("Nouvelle activité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        if locationManager.trackingStartTime != nil {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Abandonner l'activité?", isPresented: $showingDiscardAlert) {
                Button("Continuer", role: .cancel) {}
                Button("Abandonner", role: .destructive) {
                    locationManager.reset()
                    timer?.invalidate()
                    dismiss()
                }
            } message: {
                Text("L'activité en cours sera perdue.")
            }
            .onAppear {
                // Initialiser le TerritoryManager
                if territoryManager == nil {
                    territoryManager = TerritoryManager(modelContext: modelContext)
                }

                if !locationManager.isAuthorized {
                    locationManager.requestAuthorization()
                }
            }
            .onDisappear {
                timer?.invalidate()
                territoryCheckTimer?.invalidate()
            }
            .fullScreenCover(isPresented: $showingSummary, onDismiss: {
                dismiss() // Fermer NewActivityView après le résumé
            }) {
                if let data = summaryData {
                    ActivitySummaryView(
                        activity: data.activity,
                        territoriesCaptured: data.territories,
                        xpGained: data.xp,
                        routeCoordinates: locationManager.routeCoordinates,
                        capturedTileIDs: [],
                        leveledUp: data.levelUp,
                        newLevel: data.newLevel
                    )
                }
            }
        }
    }

    private func startTracking() {
        // Vérifier les permissions avant de démarrer
        if !locationManager.isAuthorized {
            // Les permissions ont déjà été demandées dans onAppear,
            // donc si on arrive ici c'est que l'utilisateur a refusé
            return
        }

        locationManager.startTracking()

        // Ne démarrer le timer que si le tracking a effectivement commencé
        if locationManager.isTracking {
            startTimer()
            startTerritoryTracking()
        }
    }

    private func pauseTracking() {
        locationManager.pauseTracking()
        isPaused = true
        timer?.invalidate()
        territoryCheckTimer?.invalidate()
    }

    private func resumeTracking() {
        locationManager.resumeTracking()
        isPaused = false
        startTimer()
        startTerritoryTracking()
    }

    private func startTerritoryTracking() {
        // Démarrer la session de capture de territoires
        territoryManager?.startSession()
        territoriesCaptured = 0
        xpGained = 0

        // Timer pour vérifier la position toutes les 3 secondes
        territoryCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            checkTerritoryPassage()
        }
    }

    private func checkTerritoryPassage() {
        guard let location = locationManager.currentLocation else { return }
        guard locationManager.isTracking else { return }

        let oldTerritories = territoryManager?.capturedThisSession ?? 0

        // Vérifier le passage dans un territoire
        territoryManager?.checkPassage(at: location.coordinate)

        // Récupérer les stats de la session
        if let manager = territoryManager {
            territoriesCaptured = manager.capturedThisSession
            xpGained = manager.xpGainedThisSession

            // Haptic feedback si nouvelle capture
            if territoriesCaptured > oldTerritories {
                hapticSuccess.notificationOccurred(.success)
            }

            // Afficher les notifications de capture
            let notifications = manager.getAndClearNotifications()
            for notification in notifications {
                showNotification(notification)
            }
        }
    }

    private func showNotification(_ message: String) {
        hapticImpact.impactOccurred()

        withAnimation {
            showingNotification = message
        }

        // Cacher après 2 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingNotification = nil
            }
        }
    }

    private func stopTracking() {
        // Arrêter les timers
        timer?.invalidate()
        territoryCheckTimer?.invalidate()

        // Terminer la session de territoires et récupérer le résumé
        let summary = territoryManager?.endSession()

        // Capturer les données de l'activité AVANT de reset
        let distance = locationManager.totalDistance
        let duration = locationManager.elapsedTime
        let maxSpeedKmh = locationManager.maxSpeedKmh
        _ = locationManager.routeCoordinates // Coordonnées capturées pour le résumé

        // Mettre à jour l'utilisateur avec l'activité
        var leveledUp = false
        var newLevel: Int?
        if let user = territoryManager?.getUser() {
            let oldLevel = user.level
            user.recordActivity(
                distance: distance,
                duration: duration,
                maxSpeed: maxSpeedKmh
            )
            newLevel = user.level
            leveledUp = newLevel != oldLevel
        }

        // Sauvegarder l'activité
        let savedActivity = saveActivity()

        // Reset après la sauvegarde
        locationManager.reset()

        // Préparer les données du résumé
        if let activity = savedActivity, let summary = summary {
            summaryData = (
                activity: activity,
                territories: summary.territoriesCaptured,
                xp: summary.xpGained,
                levelUp: leveledUp,
                newLevel: newLevel ?? 1
            )
            showingSummary = true
        } else {
            // Pas de données, juste fermer
            dismiss()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = locationManager.elapsedTime
        }
    }

    private func saveActivity() -> Activity? {
        // Capturer les valeurs AVANT toute modification
        let distance = locationManager.totalDistance
        let duration = locationManager.elapsedTime
        let maxSpeedKmh = locationManager.maxSpeedKmh
        let avgSpeedKmh = locationManager.avgSpeedKmh
        let routePoints = locationManager.encodeRoutePoints()

        // Vérifier qu'on a bien des données à sauvegarder
        guard duration > 0 else {
            print("Warning: No activity duration to save")
            // Créer quand même une activité minimale pour éviter les crashes
            let minimalActivity = Activity(
                distance: 0,
                duration: 1,
                activityType: "running",
                maxSpeed: 0,
                routePoints: nil
            )
            modelContext.insert(minimalActivity)
            try? modelContext.save()
            return minimalActivity
        }

        let detectedType = detectActivityType(speedKmh: avgSpeedKmh)

        let activity = Activity(
            distance: distance,
            duration: duration,
            activityType: detectedType,
            maxSpeed: maxSpeedKmh,
            routePoints: routePoints
        )

        // Avertir si l'activité est suspecte
        if !activity.isValid {
            print("⚠️ Activité suspecte détectée: \(activity.validationMessage ?? "Raison inconnue")")
        }

        modelContext.insert(activity)

        do {
            try modelContext.save()
            print("Activity saved: distance=\(distance)m, duration=\(duration)s, type=\(detectedType), valid=\(activity.isValid)")
            return activity
        } catch {
            print("Error saving activity: \(error)")
            return nil
        }
    }

    private func detectActivityType(speedKmh: Double) -> String {
        // Détection automatique du type d'activité basée sur la vitesse moyenne
        switch speedKmh {
        case 0..<6:
            return "walking"  // Marche: moins de 6 km/h
        case 6..<15:
            return "running"  // Course: 6-15 km/h
        case 15..<35:
            return "cycling"  // Vélo: 15-35 km/h
        case 35...:
            return "driving"  // Véhicule motorisé (sera marqué comme invalide)
        default:
            return "running"
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.9))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold))

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(20)
    }
}

#Preview {
    NewActivityView()
        .modelContainer(for: [Activity.self, Territory.self, User.self], inMemory: true)
}
