//
//  ActivitySummaryView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import MapKit

struct ActivitySummaryView: View {
    @Environment(\.dismiss) private var dismiss

    let activity: Activity
    let territoriesCaptured: Int
    let xpGained: Int
    let routeCoordinates: [CLLocationCoordinate2D]
    let capturedTileIDs: [String]
    let leveledUp: Bool
    let newLevel: Int?

    @State private var position: MapCameraPosition = .automatic
    @State private var showConfetti = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Célébration
                        celebrationHeader

                        // Map avec route et territoires
                        activityMap

                        // Stats de l'activité
                        activityStats

                        // Conquêtes
                        conquestStats

                        // Bouton continuer
                        Button {
                            dismiss()
                        } label: {
                            Text("Continuer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.top)
                }

                // Confettis si level up
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                if leveledUp {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showConfetti = false
                    }
                }
                setupMapPosition()
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            if leveledUp, let level = newLevel {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .symbolEffect(.bounce, options: .repeating)

                Text("LEVEL UP!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Niveau \(level)")
                    .font(.title2)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Activité Terminée !")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding()
    }

    // MARK: - Activity Map

    private var activityMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Votre Parcours")
                .font(.headline)
                .padding(.horizontal)

            Map(position: $position) {
                // Route de l'activité
                if !routeCoordinates.isEmpty {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(.blue, lineWidth: 3)
                }

                // Marqueurs début et fin
                if let start = routeCoordinates.first {
                    Annotation("Début", coordinate: start) {
                        Circle()
                            .fill(.green)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                }

                if let end = routeCoordinates.last {
                    Annotation("Fin", coordinate: end) {
                        Circle()
                            .fill(.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    // MARK: - Activity Stats

    private var activityStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ActivityStatCard(
                    title: "Distance",
                    value: activity.distanceFormatted,
                    icon: "location.fill",
                    color: .blue
                )

                ActivityStatCard(
                    title: "Temps",
                    value: activity.durationFormatted,
                    icon: "clock.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                ActivityStatCard(
                    title: "Vitesse Moy.",
                    value: activity.speedFormatted,
                    icon: "speedometer",
                    color: .green
                )

                ActivityStatCard(
                    title: "Type",
                    value: activity.activityTypeLabel,
                    icon: activity.activityTypeIcon,
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Conquest Stats

    private var conquestStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conquêtes")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ConquestStatRow(
                    icon: "map.fill",
                    title: "Territoires Capturés",
                    value: "\(territoriesCaptured)",
                    color: .blue
                )

                ConquestStatRow(
                    icon: "star.fill",
                    title: "XP Gagné",
                    value: "+\(xpGained)",
                    color: .yellow
                )

                if leveledUp, let level = newLevel {
                    ConquestStatRow(
                        icon: "arrow.up.circle.fill",
                        title: "Nouveau Niveau",
                        value: "\(level)",
                        color: .green
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private func setupMapPosition() {
        guard !routeCoordinates.isEmpty else { return }

        // Calculer le centre et la distance pour afficher toute la route
        let latitudes = routeCoordinates.map { $0.latitude }
        let longitudes = routeCoordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let spanLat = (maxLat - minLat) * 1.5 // Marge de 50%
        let spanLon = (maxLon - minLon) * 1.5

        let distance = max(spanLat, spanLon) * 111000 // Conversion en mètres

        position = .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                distance: max(distance, 500) // Minimum 500m
            )
        )
    }
}

// MARK: - Supporting Views

struct ActivityStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ConquestStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Confetti Animation

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confetti) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(piece.position)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                generateConfetti(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
            }
        }
    }

    private func generateConfetti(screenWidth: CGFloat, screenHeight: CGFloat) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

        for _ in 0..<100 {
            let piece = ConfettiPiece(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...15),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: -100...0)
                ),
                opacity: 1.0
            )
            confetti.append(piece)

            // Animer la chute
            withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                if let index = confetti.firstIndex(where: { $0.id == piece.id }) {
                    confetti[index].position.y = screenHeight + 100
                    confetti[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    ActivitySummaryView(
        activity: Activity(distance: 5000, duration: 1800, activityType: "running"),
        territoriesCaptured: 12,
        xpGained: 150,
        routeCoordinates: [],
        capturedTileIDs: [],
        leveledUp: true,
        newLevel: 5
    )
}
