//
//  MapView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var locationManager = LocationManager()
    @State private var territoryManager: TerritoryManager?
    @State private var position: MapCameraPosition = .automatic
    @State private var showTerritories = true

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    // Afficher les territoires
                    if showTerritories, let manager = territoryManager {
                        ForEach(manager.visibleTerritories, id: \.tileID) { territory in
                            MapPolygon(territory.geoTile.polygon)
                                .foregroundStyle(territoryColor(for: territory).opacity(0.3))
                                .stroke(territoryColor(for: territory), lineWidth: territory.isContested ? 3 : 1.5)
                        }
                    }

                    // Afficher la position utilisateur
                    if let location = locationManager.currentLocation {
                        Annotation("Ma position", coordinate: location.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.3))
                                    .frame(width: 40, height: 40)

                                Circle()
                                    .fill(.blue)
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                VStack {
                    Spacer()

                    if !locationManager.isAuthorized {
                        VStack(spacing: 16) {
                            Image(systemName: locationManager.isDenied ? "location.slash.fill" : "location.slash")
                                .font(.system(size: 50))
                                .foregroundColor(locationManager.isDenied ? .red : .gray)

                            Text(locationManager.isDenied ? "Localisation refusée" : "Autorisation de localisation requise")
                                .font(.headline)

                            Text(locationManager.permissionMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            if locationManager.isNotDetermined {
                                Button("Autoriser la localisation") {
                                    locationManager.requestAuthorization()
                                }
                                .buttonStyle(.borderedProminent)
                            } else if locationManager.isDenied {
                                Button("Ouvrir les réglages") {
                                    locationManager.openSettings()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(20)
                        .padding()
                    }
                }

                // Bouton toggle territoires
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showTerritories.toggle()
                        } label: {
                            Image(systemName: showTerritories ? "map.fill" : "map")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Carte")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if territoryManager == nil {
                    territoryManager = TerritoryManager(modelContext: modelContext)
                }
                if locationManager.isAuthorized {
                    updateCameraPosition()
                    loadTerritories()
                }
            }
            .onChange(of: locationManager.currentLocation) { oldValue, newValue in
                updateCameraPosition()
                loadTerritories()
            }
        }
    }

    private func updateCameraPosition() {
        if let location = locationManager.currentLocation {
            position = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 1000
                )
            )
        }
    }

    private func loadTerritories() {
        guard let location = locationManager.currentLocation else { return }
        territoryManager?.loadTerritoriesAround(location.coordinate, radius: 1500)
    }

    private func territoryColor(for territory: Territory) -> Color {
        if territory.isNeutral {
            return .gray // Territoire neutre
        } else if let currentUserID = territoryManager?.getUser()?.id.uuidString,
                  territory.ownerID == currentUserID {
            return territoryManager?.getUser()?.color ?? .blue // Mes territoires
        } else {
            return .red // Territoires ennemis
        }
    }
}

#Preview {
    MapView()
        .modelContainer(for: [Activity.self, Territory.self, User.self], inMemory: true)
}
