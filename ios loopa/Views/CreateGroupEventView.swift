//
//  CreateGroupEventView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import MapKit
import MapboxMaps
import PhotosUI

struct CreateGroupEventView: View {
    enum CreationType: Identifiable {
        case group
        
        var id: String {
            switch self {
            case .group: return "group"
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @Binding var showCelebration: Bool
    var preselectedType: CreationType
    
    var body: some View {
        ZStack {
            CreateGroupFlowView(onComplete: {
                showCelebration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }, showCelebration: $showCelebration)
        }
    }
}

// MARK: - Create Group Flow
struct CreateGroupFlowView: View {
    @Environment(\.dismiss) private var dismiss
    enum Step: Int, CaseIterable {
        case namePhoto = 0
        case category = 1
        case location = 2
        
        var title: String {
            switch self {
            case .namePhoto: return "Group Name"
            case .category: return "Category"
            case .location: return "Location"
            }
        }
    }
    
    let onComplete: () -> Void
    @Binding var showCelebration: Bool
    @State private var currentStep: Step = .namePhoto
    @State private var groupName: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var groupImage: UIImage?
    @State private var selectedCategory: String = ""
    @State private var selectedLocation: CLLocationCoordinate2D?
    
    private let categories: [(name: String, color: Color, emoji: String)] = [
        ("Restaurants", Color.pink, "🍽️"),
        ("Cafes", Color.orange, "☕"),
        ("Activities", Color.blue, "🎯"),
        ("Museums", Color.purple, "🏛️"),
        ("Nightlife", Color.pink, "🌙"),
        ("Nature", Color.green, "🌿"),
        ("Shopping", Color.orange, "🛍️"),
        ("Viewpoints", Color.blue, "🌅")
    ]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress Indicator (Step X / Total)
                    progressIndicator
                    
                    // Step Content
                    ScrollView {
                        stepContent
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                            .frame(minHeight: geometry.size.height - 120) // Account for progress + buttons
                    }
                    .background(Color.white)
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep.rawValue > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                previousStep()
                            }
                        }) {
                            Text("Back")
                                .font(.app(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 20)
                                )
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            nextStep()
                        }
                    }) {
                        Text(currentStep == .location ? "Create" : "Next")
                            .font(.app(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canProceed ? Color.appAccent : Color.gray,
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                    }
                    .disabled(!canProceed)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 0) // No bottom padding to show rounded corners
                .background(
                    Color.clear,
                    in: UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 0,
                            bottomLeading: 36,
                            bottomTrailing: 36,
                            topTrailing: 0
                        ),
                        style: .continuous
                    )
                )
                }
            }
            .clipShape(UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 36,
                    bottomTrailing: 36,
                    topTrailing: 0
                ),
                style: .continuous
            ))
            .background(Color.white)
            .navigationTitle(currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .background(Color.white)
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= currentStep.rawValue ? Color.appAccent : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .namePhoto:
            namePhotoStep
        case .category:
            categoryStep
        case .location:
            locationStep
        }
    }
    
    private var namePhotoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name this group")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Pick a memorable title for this spot")
                    .font(.app(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            TextField("Enter place name", text: $groupName)
                .font(.app(size: 17, weight: .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Add a photo")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Choose a photo that represents this place")
                    .font(.app(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let groupImage = groupImage {
                        // Miniature photo avec fond
                        HStack(spacing: 12) {
                            Image(uiImage: groupImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Photo selected")
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Tap to change")
                                    .font(.app(size: 13, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.appAccent)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                    } else {
                        // État vide avec placeholder
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(Color.appAccent)
                            
                            Text("Tap to add photo")
                                .font(.app(size: 15, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                            
                            Text("JPG, PNG or HEIC")
                                .font(.app(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                )
                                .foregroundStyle(Color.secondary.opacity(0.3))
                        )
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        groupImage = image
                    }
                }
            }
        }
    }
    
    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose a category")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("What's your group about?")
                    .font(.app(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            // Pastilles (Flow Layout)
            FlowLayout(spacing: 10) {
                ForEach(categories, id: \.name) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            selectedCategory = category.name
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(category.emoji)
                                .font(.app(size: 16))
                            
                            Text(category.name)
                                .font(.app(size: 14, weight: .semibold))
                                .foregroundStyle(selectedCategory == category.name ? .white : .primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedCategory == category.name 
                                ? AnyShapeStyle(category.color)
                                : AnyShapeStyle(category.color.opacity(0.15)),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedCategory == category.name ? Color.clear : category.color.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose a location")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Pin your group's location on the map")
                    .font(.app(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            LocationPickerMapView(selectedLocation: $selectedLocation)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .namePhoto:
            return !groupName.isEmpty && groupImage != nil
        case .category:
            return !selectedCategory.isEmpty
        case .location:
            return selectedLocation != nil
        }
    }
    
    private func nextStep() {
        if currentStep == .location {
            // Create group
            onComplete()
        } else {
            currentStep = Step(rawValue: currentStep.rawValue + 1) ?? .namePhoto
        }
    }
    
    private func previousStep() {
        currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .namePhoto
    }
}

// MARK: - Location Picker Map View
struct LocationPickerMapView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var pickerViewport: MapboxMaps.Viewport = .camera(center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), zoom: 12, bearing: 0, pitch: 0)
    @State private var lastMapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673)
    @State private var selectedPOI: TappedPOI?
    
    var body: some View {
        ZStack(alignment: .center) {
            MapboxMaps.MapReader { proxy in
                MapboxMaps.Map(viewport: $pickerViewport) {
                    MapboxMaps.SymbolLayer(id: "app-poi-picker", source: "composite")
                        .sourceLayer("poi_label")
                        .textField(Exp(.get) { "name" })
                        .textSize(12)
                        .textColor(MapboxMaps.StyleColor(.darkGray))
                    MapboxMaps.ForEvery(annotations) { item in
                        MapboxMaps.MapViewAnnotation(coordinate: item.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    MapboxMaps.TapInteraction { context in
                        handlePOITap(context: context, map: proxy.map)
                        return false
                    }
                }
                .mapStyle(MapboxMaps.MapStyle.appStyle)
                .ornamentOptions(MapboxMaps.OrnamentOptions(scaleBar: MapboxMaps.ScaleBarViewOptions(visibility: .hidden)))
                .onAppear {
                    pickerViewport = MapboxMaps.Viewport.camera(center: region.center, zoom: mapboxZoom(from: region.span), bearing: 0, pitch: 0)
                    lastMapCenter = region.center
                }
                .onChange(of: region.center.latitude) { _, _ in
                    pickerViewport = MapboxMaps.Viewport.camera(center: region.center, zoom: mapboxZoom(from: region.span), bearing: 0, pitch: 0)
                    lastMapCenter = region.center
                }
                .onChange(of: region.center.longitude) { _, _ in
                    pickerViewport = MapboxMaps.Viewport.camera(center: region.center, zoom: mapboxZoom(from: region.span), bearing: 0, pitch: 0)
                    lastMapCenter = region.center
                }
            }
            .sheet(item: $selectedPOI) { (poi: TappedPOI) in
                POIDetailSheetView(poi: poi, onDismiss: { selectedPOI = nil })
            }
            
            // Center Pin
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.appAccent)
                .offset(y: -16)
            
            VStack {
                Spacer()
                Button(action: {
                    selectedLocation = lastMapCenter
                }) {
                    Text("Select This Location")
                        .font(.app(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Color.appAccent,
                            in: Capsule()
                        )
                }
                .padding(.bottom, 0)
            }
        }
    }
    
    private func handlePOITap(context: MapboxMaps.InteractionContext, map: MapboxMaps.MapboxMap?) {
        guard let map = map else { return }
        let options = MapboxMaps.RenderedQueryOptions(layerIds: ["app-poi-picker"], filter: nil)
        _ = map.queryRenderedFeatures(with: context.point, options: options) { result in
            guard let features = try? result.get(),
                  let first = features.first(where: { $0.queriedFeature.sourceLayer == "poi_label" }) ?? features.first,
                  let poi = TappedPOI.from(queriedFeature: first) else { return }
            DispatchQueue.main.async {
                selectedPOI = poi
            }
        }
    }
    
    private var annotations: [LocationAnnotation] {
        guard let location = selectedLocation else { return [] }
        return [LocationAnnotation(coordinate: location)]
    }
    
    private struct LocationAnnotation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}
