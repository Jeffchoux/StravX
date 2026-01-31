//
//  GeoTile.swift
//  StravX
//
//  Created by Claude Code
//  Copyright © 2026 StravX. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

/// Système de grille géographique pour diviser le monde en zones capturables
/// Alternative légère et performante à H3
struct GeoTile: Hashable, Codable {
    let tileID: String
    let centerLat: Double
    let centerLon: Double
    let zoom: Int // Niveau de zoom (plus grand = zones plus petites)

    // MARK: - Configuration

    /// Taille d'une tile en degrés selon le niveau de zoom
    /// Zoom 15 ≈ 100m x 100m (parfait pour une ville)
    static let tileSizes: [Int: Double] = [
        13: 0.01,    // ~1.1 km
        14: 0.005,   // ~550 m
        15: 0.0025,  // ~275 m (OPTIMAL pour StravX)
        16: 0.00125, // ~137 m
        17: 0.000625 // ~68 m
    ]

    static let defaultZoom = 15 // Niveau optimal pour le jeu

    // MARK: - Création

    /// Crée une GeoTile à partir de coordonnées GPS
    static func from(coordinate: CLLocationCoordinate2D, zoom: Int = defaultZoom) -> GeoTile {
        guard let tileSize = tileSizes[zoom] else {
            fatalError("Invalid zoom level: \(zoom)")
        }

        // Arrondir les coordonnées à la grille
        let tileLat = floor(coordinate.latitude / tileSize) * tileSize + tileSize / 2
        let tileLon = floor(coordinate.longitude / tileSize) * tileSize + tileSize / 2

        // Créer un ID unique basé sur lat/lon/zoom
        let tileID = "\(zoom)_\(Int(tileLat * 100000))_\(Int(tileLon * 100000))"

        return GeoTile(
            tileID: tileID,
            centerLat: tileLat,
            centerLon: tileLon,
            zoom: zoom
        )
    }

    // MARK: - Propriétés calculées

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
    }

    var tileSize: Double {
        Self.tileSizes[zoom] ?? Self.tileSizes[Self.defaultZoom]!
    }

    /// Retourne les 4 coins de la tile (pour dessiner un carré)
    var boundingBox: [CLLocationCoordinate2D] {
        let halfSize = tileSize / 2
        return [
            CLLocationCoordinate2D(latitude: centerLat - halfSize, longitude: centerLon - halfSize), // SW
            CLLocationCoordinate2D(latitude: centerLat - halfSize, longitude: centerLon + halfSize), // SE
            CLLocationCoordinate2D(latitude: centerLat + halfSize, longitude: centerLon + halfSize), // NE
            CLLocationCoordinate2D(latitude: centerLat + halfSize, longitude: centerLon - halfSize)  // NW
        ]
    }

    /// Retourne les points d'un hexagone approximatif (visuellement plus joli)
    var hexagonPoints: [CLLocationCoordinate2D] {
        let halfSize = tileSize / 2
        let quarterSize = tileSize / 4

        // Hexagone pointant vers le haut
        return [
            CLLocationCoordinate2D(latitude: centerLat + halfSize, longitude: centerLon), // Top
            CLLocationCoordinate2D(latitude: centerLat + quarterSize, longitude: centerLon + halfSize), // Top-right
            CLLocationCoordinate2D(latitude: centerLat - quarterSize, longitude: centerLon + halfSize), // Bottom-right
            CLLocationCoordinate2D(latitude: centerLat - halfSize, longitude: centerLon), // Bottom
            CLLocationCoordinate2D(latitude: centerLat - quarterSize, longitude: centerLon - halfSize), // Bottom-left
            CLLocationCoordinate2D(latitude: centerLat + quarterSize, longitude: centerLon - halfSize)  // Top-left
        ]
    }

    /// Retourne un MKPolygon pour afficher sur la carte (carré)
    var polygon: MKPolygon {
        var coords = boundingBox
        return MKPolygon(coordinates: &coords, count: coords.count)
    }

    /// Retourne un MKPolygon hexagonal (optionnel)
    var hexagonPolygon: MKPolygon {
        var coords = hexagonPoints
        return MKPolygon(coordinates: &coords, count: coords.count)
    }

    // MARK: - Utilitaires

    /// Vérifie si une coordonnée est dans cette tile
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let halfSize = tileSize / 2
        let latDiff = abs(coordinate.latitude - centerLat)
        let lonDiff = abs(coordinate.longitude - centerLon)
        return latDiff <= halfSize && lonDiff <= halfSize
    }

    /// Retourne les tiles voisines (8 directions + centre)
    func neighbors(includeCenter: Bool = false) -> [GeoTile] {
        var tiles: [GeoTile] = []
        let offsets: [(Double, Double)] = [
            (-1, -1), (-1, 0), (-1, 1),  // Top row
            (0, -1),           (0, 1),   // Middle row (sans centre)
            (1, -1),  (1, 0),  (1, 1)    // Bottom row
        ]

        if includeCenter {
            tiles.append(self)
        }

        for (latOffset, lonOffset) in offsets {
            let coord = CLLocationCoordinate2D(
                latitude: centerLat + latOffset * tileSize,
                longitude: centerLon + lonOffset * tileSize
            )
            tiles.append(GeoTile.from(coordinate: coord, zoom: zoom))
        }

        return tiles
    }

    /// Distance en mètres jusqu'à une autre tile
    func distance(to other: GeoTile) -> Double {
        let from = CLLocation(latitude: centerLat, longitude: centerLon)
        let to = CLLocation(latitude: other.centerLat, longitude: other.centerLon)
        return from.distance(from: to)
    }

    /// Retourne toutes les tiles dans un rayon donné (en mètres)
    static func tilesAround(coordinate: CLLocationCoordinate2D, radius: Double, zoom: Int = defaultZoom) -> [GeoTile] {
        let center = GeoTile.from(coordinate: coordinate, zoom: zoom)
        var tiles: Set<GeoTile> = [center]

        // Calculer combien de tiles on doit checker dans chaque direction
        let tileSize = tileSizes[zoom]!
        let approxTileSizeMeters = tileSize * 111000 // 1 degré ≈ 111km
        let tilesRadius = Int(ceil(radius / approxTileSizeMeters))

        // Générer toutes les tiles dans le rayon
        for latOffset in -tilesRadius...tilesRadius {
            for lonOffset in -tilesRadius...tilesRadius {
                let coord = CLLocationCoordinate2D(
                    latitude: coordinate.latitude + Double(latOffset) * tileSize,
                    longitude: coordinate.longitude + Double(lonOffset) * tileSize
                )
                let tile = GeoTile.from(coordinate: coord, zoom: zoom)

                // Vérifier si la tile est vraiment dans le rayon
                if center.distance(to: tile) <= radius {
                    tiles.insert(tile)
                }
            }
        }

        return Array(tiles)
    }
}

// MARK: - Extensions pour faciliter l'utilisation

extension CLLocationCoordinate2D {
    /// Retourne la GeoTile qui contient cette coordonnée
    var geoTile: GeoTile {
        GeoTile.from(coordinate: self)
    }

    /// Retourne la GeoTile à un niveau de zoom spécifique
    func geoTile(zoom: Int) -> GeoTile {
        GeoTile.from(coordinate: self, zoom: zoom)
    }
}

extension CLLocation {
    /// Retourne la GeoTile qui contient cette position
    var geoTile: GeoTile {
        GeoTile.from(coordinate: self.coordinate)
    }
}
