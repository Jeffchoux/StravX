//
//  ConquestView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import SwiftData
import MapKit

struct ConquestView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var territoryManager: TerritoryManager?
    @State private var locationManager = LocationManager()
    @State private var ownedTerritories: [Territory] = []
    @State private var stats: TerritoryStatistics?
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedTerritory: Territory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête avec stats globales
                    statsHeader

                    // Carte avec territoires possédés
                    territoryMap

                    // Liste des territoires
                    if !ownedTerritories.isEmpty {
                        territoryList
                    } else {
                        emptyState
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Mes Territoires")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatBox(
                    title: "Territoires",
                    value: "\(stats?.totalOwned ?? 0)",
                    icon: "map.fill",
                    color: .blue
                )

                StatBox(
                    title: "Force Totale",
                    value: "\(stats?.totalStrength ?? 0)",
                    icon: "shield.fill",
                    color: .green
                )
            }

            HStack(spacing: 16) {
                StatBox(
                    title: "Moy. Force",
                    value: "\(stats?.averageStrength ?? 0)",
                    icon: "chart.bar.fill",
                    color: .orange
                )

                StatBox(
                    title: "En Danger",
                    value: "\(stats?.endangered ?? 0)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Territory Map

    private var territoryMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carte de Domination")
                .font(.headline)
                .padding(.horizontal)

            Map(position: $position, selection: $selectedTerritory) {
                ForEach(ownedTerritories, id: \.tileID) { territory in
                    MapPolygon(territory.geoTile.polygon)
                        .foregroundStyle(Color.blue.opacity(0.4))
                        .stroke(territory.isContested ? Color.red : Color.blue, lineWidth: 2)
                        .tag(territory)
                }

                // Position utilisateur
                if let location = locationManager.currentLocation {
                    Annotation("Vous", coordinate: location.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    // MARK: - Territory List

    private var territoryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vos Zones (\(ownedTerritories.count))")
                .font(.headline)
                .padding(.horizontal)

            ForEach(ownedTerritories, id: \.tileID) { territory in
                TerritoryCard(territory: territory)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "map.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 12) {
                Text("Aucun Territoire")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Lancez une activité pour commencer à conquérir des zones !")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadData() {
        if territoryManager == nil {
            territoryManager = TerritoryManager(modelContext: modelContext)
        }

        ownedTerritories = territoryManager?.getOwnedTerritories() ?? []
        stats = territoryManager?.getStatistics()

        // Centrer la carte sur les territoires
        if let firstTerritory = ownedTerritories.first {
            position = .camera(
                MapCamera(
                    centerCoordinate: firstTerritory.centerCoordinate,
                    distance: 5000
                )
            )
        } else if let location = locationManager.currentLocation {
            position = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 5000
                )
            )
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
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
                .font(.title)
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

struct TerritoryCard: View {
    let territory: Territory

    var body: some View {
        HStack(spacing: 16) {
            // Icône de statut
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(territory.statusEmoji)
                    .font(.title2)
            }

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text("Zone #\(territory.tileID.suffix(6))")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(territory.strengthPoints)", systemImage: "shield.fill")
                        .font(.caption)
                        .foregroundColor(territory.strengthPoints < 30 ? .red : .green)

                    if territory.isContested {
                        Label("Attaquée !", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if let captured = territory.capturedAt {
                        Text(captured, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Barre de force
            VStack(spacing: 4) {
                ProgressView(value: Double(territory.strengthPoints), total: 100)
                    .tint(territory.strengthPoints < 30 ? .red : .green)

                Text("\(territory.strengthPoints)/100")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
        }
        .padding()
        .background(territory.isContested ? Color.red.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(territory.isContested ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    ConquestView()
        .modelContainer(for: [Territory.self, User.self], inMemory: true)
}
