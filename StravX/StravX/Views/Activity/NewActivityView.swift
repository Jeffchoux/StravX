//
//  NewActivityView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData

struct NewActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var locationManager = LocationManager()
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isPaused = false
    @State private var showingDiscardAlert = false

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
                        }
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
                if !locationManager.isAuthorized {
                    locationManager.requestAuthorization()
                }
            }
            .onDisappear {
                timer?.invalidate()
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
        }
    }

    private func pauseTracking() {
        locationManager.pauseTracking()
        isPaused = true
        timer?.invalidate()
    }

    private func resumeTracking() {
        locationManager.resumeTracking()
        isPaused = false
        startTimer()
    }

    private func stopTracking() {
        // Sauvegarder l'activité AVANT d'arrêter le tracking pour conserver les données
        saveActivity()

        // Maintenant on peut arrêter le tracking et le timer
        timer?.invalidate()

        // Reset après la sauvegarde
        locationManager.reset()

        // Fermer la vue
        dismiss()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = locationManager.elapsedTime
        }
    }

    private func saveActivity() {
        // Capturer les valeurs AVANT toute modification
        let distance = locationManager.totalDistance
        let duration = locationManager.elapsedTime
        let maxSpeedKmh = locationManager.maxSpeedKmh
        let avgSpeedKmh = locationManager.avgSpeedKmh
        let routePoints = locationManager.encodeRoutePoints()

        // Vérifier qu'on a bien des données à sauvegarder
        guard duration > 0 else {
            print("Warning: No activity duration to save")
            return
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
        } catch {
            print("Error saving activity: \(error)")
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
        .modelContainer(for: [Activity.self], inMemory: true)
}
