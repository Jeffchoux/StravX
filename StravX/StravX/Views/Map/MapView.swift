//
//  MapView.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
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
            }
            .navigationTitle("Carte")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if locationManager.isAuthorized {
                    updateCameraPosition()
                }
            }
            .onChange(of: locationManager.currentLocation) { oldValue, newValue in
                updateCameraPosition()
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
}

#Preview {
    MapView()
}
