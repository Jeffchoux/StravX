//
//  ActivityDetailView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import MapKit

struct ActivityDetailView: View {
    let activity: Activity
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header avec icône et type
                HStack {
                    Image(systemName: activity.activityTypeIcon)
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .frame(width: 80, height: 80)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.activityTypeLabel)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(activity.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(activity.date, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()

                // Stats principales
                HStack(spacing: 16) {
                    ActivityStatBox(
                        icon: "location.fill",
                        title: "Distance",
                        value: activity.distanceFormatted
                    )

                    ActivityStatBox(
                        icon: "clock.fill",
                        title: "Durée",
                        value: activity.durationFormatted
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    ActivityStatBox(
                        icon: "speedometer",
                        title: "Vitesse moy.",
                        value: activity.speedFormatted
                    )

                    ActivityStatBox(
                        icon: "calendar",
                        title: "Date",
                        value: activity.date.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                .padding(.horizontal)

                // Carte du parcours (si disponible)
                if let routeData = activity.routePoints,
                   let coordinates = LocationManager.decodeRoutePoints(routeData),
                   !coordinates.isEmpty {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parcours")
                            .font(.headline)
                            .padding(.horizontal)

                        Map(position: $position) {
                            MapPolyline(coordinates: coordinates)
                                .stroke(.blue, lineWidth: 4)

                            if let firstCoordinate = coordinates.first {
                                Annotation("Départ", coordinate: firstCoordinate) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 12, height: 12)
                                }
                            }

                            if let lastCoordinate = coordinates.last {
                                Annotation("Arrivée", coordinate: lastCoordinate) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .frame(height: 300)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    .onAppear {
                        centerMapOnRoute(coordinates)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func centerMapOnRoute(_ coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        let region = MKCoordinateRegion(
            coordinates: coordinates,
            padding: 100
        )

        position = .region(region)
    }
}

struct ActivityStatBox: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)

            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// Extension pour calculer région depuis coordonnées
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D], padding: CLLocationDegrees) {
        guard !coordinates.isEmpty else {
            self = MKCoordinateRegion()
            return
        }

        let lats = coordinates.map { $0.latitude }
        let longs = coordinates.map { $0.longitude }

        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLong = longs.min() ?? 0
        let maxLong = longs.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLong + maxLong) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLong - minLong) * 1.5
        )

        self = MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    NavigationStack {
        ActivityDetailView(
            activity: Activity(
                distance: 5000,
                duration: 1800,
                activityType: "running"
            )
        )
    }
}
