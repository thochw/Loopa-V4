//
//  MapboxMapStyle.swift
//  ios loopa
//
//  Style Mapbox partagé et helpers pour toute l'app.
//

import MapKit
import MapboxMaps

/// Style Mapbox personnalisé (thochw) – utilisé partout à la place d'Apple Maps.
/// Les couches POI (commercial, recreation, landmark) sont ajoutées dans chaque carte ; le style doit être basé sur Mapbox Streets (source "composite" / layer "poi_label").
extension MapboxMaps.MapStyle {
    static let appStyle = MapboxMaps.MapStyle(uri: MapboxMaps.StyleURI(rawValue: "mapbox://styles/thochw/cmkbqgty5004901rxgct4a0z6")!)
    /// Mapbox Standard – requis pour TapInteraction(.standardPoi) et POIs cliquables.
    static let standardStyle = MapboxMaps.MapStyle(uri: .standard)
}

/// Convertit un `MKCoordinateSpan` en niveau de zoom Mapbox (approximatif).
func mapboxZoom(from span: MKCoordinateSpan) -> Double {
    let lat = max(0.001, span.latitudeDelta)
    return min(20, max(1, 14 - log2(lat * 25)))
}
