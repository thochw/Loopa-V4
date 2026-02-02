//
//  MapboxMapStyle.swift
//  ios loopa
//
//  Style Mapbox partagé et helpers pour toute l'app.
//

import MapKit
import MapboxMaps

/// Style Mapbox personnalisé (thochw) – utilisé partout à la place d'Apple Maps.
extension MapboxMaps.MapStyle {
    static let appStyle = MapboxMaps.MapStyle(uri: MapboxMaps.StyleURI(rawValue: "mapbox://styles/thochw/cmkbqgty5004901rxgct4a0z6")!)
}

/// Convertit un `MKCoordinateSpan` en niveau de zoom Mapbox (approximatif).
func mapboxZoom(from span: MKCoordinateSpan) -> Double {
    let lat = max(0.001, span.latitudeDelta)
    return min(20, max(1, 14 - log2(lat * 25)))
}
