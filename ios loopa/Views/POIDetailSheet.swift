//
//  POIDetailSheet.swift
//  ios loopa
//
//  Fiche détail d’un POI cliqué sur la carte (nom, adresse, notes, photos).
//

import SwiftUI
import MapKit
import MapboxMaps
import CoreLocation

/// POI sélectionné au tap sur la carte (données du layer poi_label + adresse optionnelle).
struct TappedPOI: Identifiable {
    let id = UUID()
    var name: String
    var address: String?
    let coordinate: CLLocationCoordinate2D
    var notes: String
    var photoURLs: [String] // URLs ou identifiants pour afficher des images
    
    /// Créé depuis TapInteraction(.standardPoi) – Mapbox Standard style.
    static func from(standardPoi: MapboxMaps.StandardPoiFeature, coordinate: CLLocationCoordinate2D) -> TappedPOI {
        TappedPOI(
            name: standardPoi.name ?? "POI",
            address: nil,
            coordinate: coordinate,
            notes: "",
            photoURLs: []
        )
    }
    
    static func from(queriedFeature: MapboxMaps.QueriedRenderedFeature) -> TappedPOI? {
        let q = queriedFeature.queriedFeature
        guard q.sourceLayer == "poi_label" else { return nil }
        let feature = q.feature
        let name: String
        if let props = feature.properties?.turfRawValue as? [String: Any] {
            name = (props["name"] as? String) ?? (props["name_en"] as? String) ?? "POI"
        } else {
            name = "POI"
        }
        let coord: CLLocationCoordinate2D
        if case .point(let point) = feature.geometry {
            coord = CLLocationCoordinate2D(latitude: point.coordinates.latitude, longitude: point.coordinates.longitude)
        } else {
            return nil
        }
        return TappedPOI(name: name, address: nil, coordinate: coord, notes: "", photoURLs: [])
    }
}

/// Vue sheet : nom, adresse, notes, photos, bouton fermer.
struct POIDetailSheetView: View {
    let poi: TappedPOI
    var onDismiss: () -> Void
    @State private var resolvedAddress: String?
    
    private var displayAddress: String {
        resolvedAddress ?? poi.address ?? "—"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Nom
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(poi.name)
                            .font(.app(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Adresse (reverse geocode au besoin)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address")
                            .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(displayAddress)
                            .font(.app(size: 15, weight: .regular))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear {
                        if resolvedAddress == nil && poi.address == nil {
                            Task {
                                resolvedAddress = await reverseGeocode(coordinate: poi.coordinate)
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(poi.notes.isEmpty ? "No notes." : poi.notes)
                            .font(.app(size: 15, weight: .regular))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Photos
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photos")
                            .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        if poi.photoURLs.isEmpty {
                            Text("No photos.")
                                .font(.app(size: 15, weight: .regular))
                                .foregroundStyle(.secondary)
                        } else {
                            // Placeholder pour une grille de photos
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(poi.photoURLs, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .aspectRatio(1, contentMode: .fill)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("POI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
        }
    }
}

/// Reverse geocode pour obtenir l’adresse à partir des coordonnées.
func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
    let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let geocoder = CLGeocoder()
    guard let placemarks = try? await geocoder.reverseGeocodeLocation(loc),
          let pm = placemarks.first else { return nil }
    var parts: [String] = []
    if let thoroughfare = pm.thoroughfare { parts.append(thoroughfare) }
    if let subThoroughfare = pm.subThoroughfare { parts.append(subThoroughfare) }
    if let locality = pm.locality { parts.append(locality) }
    if let country = pm.country { parts.append(country) }
    return parts.isEmpty ? nil : parts.joined(separator: ", ")
}
