//
//  CreatePlaceView.swift
//  ios loopa
//
//  Created for place creation flow
//

import SwiftUI
import MapKit
import CoreLocation
import PhotosUI
import Combine

struct PlaceSearchSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D?
    let type: SuggestionType
    let icon: String
    let completion: MKLocalSearchCompletion?
    
    enum SuggestionType {
        case city
        case place
        case poi
    }
}

struct CreatePlaceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()
    
    enum Step: Int, CaseIterable {
        case category = 0
        case location = 1
        case details = 2
        
        var title: String {
            switch self {
            case .category: return "Save a place"
            case .location: return "Save a place"
            case .details: return "Save a place"
            }
        }
        
        var subtitle: String {
            switch self {
            case .category: return "Choose Category"
            case .location: return "Location"
            case .details: return "Details"
            }
        }
    }
    
    @State private var currentStep: Step = .category
    @State private var selectedCategory: PlaceCategory?
    @State private var locationSearchText = ""
    @State private var locationSuggestions: [PlaceSearchSuggestion] = []
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedLocationName: String?
    @State private var isLocationSearchFocused = false
    @State private var isUsingCurrentLocation = false
    @State private var nearbyPOIs: [MKMapItem] = []
    @FocusState private var locationFieldFocused: Bool
    @State private var selectedStatus: PlaceStatus?
    @State private var rating: Int = 0
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var comment: String = ""
    
    enum PlaceCategory: String, CaseIterable {
        case food = "Food"
        case cafes = "Cafes"
        case bars = "Bars"
        case activities = "Activities"
        
        var emoji: String {
            switch self {
            case .food: return "🥪"
            case .cafes: return "🍵"
            case .bars: return "🍹"
            case .activities: return "🎡"
            }
        }
        
        var color: Color {
            switch self {
            case .food: return .orange
            case .cafes: return .brown
            case .bars: return .pink
            case .activities: return .blue
            }
        }
    }
    
    enum PlaceStatus: String, CaseIterable {
        case toTry = "🧐 To try"
        case done = "🥳 Done"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Step content
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                
                // Navigation buttons
                navigationButtons
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .onChange(of: locationSearchText) { oldValue, newValue in
                if !newValue.isEmpty {
                    searchForLocationSuggestions(query: newValue)
                } else {
                    locationSuggestions = []
                }
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                loadImages(from: newValue)
            }
            .onReceive(searchCompleter.$results) { results in
                guard !locationSearchText.isEmpty else {
                    locationSuggestions = []
                    return
                }
                
                let suggestions = results.prefix(10).map { completion in
                    PlaceSearchSuggestion(
                        name: completion.title,
                        subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                        coordinate: nil,
                        type: .poi,
                        icon: "mappin.circle.fill",
                        completion: completion
                    )
                }
                locationSuggestions = suggestions
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<Step.allCases.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentStep.rawValue ? Color.appAccent : Color(.systemGray4))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .category:
            categoryStep
        case .location:
            locationStep
        case .details:
            detailsStep
        }
    }
    
    // MARK: - Step 1: Category
    private var categoryStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose Category")
                    .font(.app(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Select a category for this place")
                    .font(.app(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    categoryButton(category: category)
                }
            }
        }
    }
    
    private func categoryButton(category: PlaceCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Text(category.emoji)
                        .font(.app(size: 48))
                    
                    Text(category.rawValue)
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            selectedCategory == category ? Color.appAccent : Color(.systemGray5),
                            lineWidth: selectedCategory == category ? 2 : 1
                        )
                )
                .shadow(
                    color: selectedCategory == category ? Color.appAccent.opacity(0.2) : .black.opacity(0.05),
                    radius: selectedCategory == category ? 8 : 4,
                    y: selectedCategory == category ? 4 : 2
                )
                
                // Selection dot
                if selectedCategory == category {
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: -8, y: 8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 2: Location
    private var locationStep: some View {
        VStack(spacing: 20) {
            // Search bar
            VStack(alignment: .leading, spacing: 12) {
                Text("Search for a place or address")
                    .font(.app(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                
                ZStack(alignment: .top) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter place name or address", text: $locationSearchText)
                            .font(.app(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($locationFieldFocused)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    
                    // Suggestions dropdown
                    if !locationSuggestions.isEmpty && locationFieldFocused {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(locationSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                                    Button(action: {
                                        handleLocationSuggestionTap(suggestion)
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: suggestion.icon)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(Color.appAccent)
                                                .frame(width: 24, height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.name)
                                                    .font(.app(size: 15, weight: .medium))
                                                    .foregroundStyle(.primary)
                                                
                                                if let subtitle = suggestion.subtitle {
                                                    Text(subtitle)
                                                        .font(.app(size: 13, weight: .regular))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemBackground))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if index < locationSuggestions.count - 1 {
                                        Divider()
                                            .padding(.leading, 54)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                        .padding(.top, 60)
                    }
                }
            }
            
            // Current location button
            Button(action: {
                useCurrentLocation()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Use your current location")
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.appAccent.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            
            // Selected location display
            if let locationName = selectedLocationName {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.green)
                    
                    Text(locationName)
                        .font(.app(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // Nearby POIs (when using current location)
            if isUsingCurrentLocation && !nearbyPOIs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nearby Places")
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(nearbyPOIs.prefix(10).enumerated()), id: \.offset) { _, poi in
                                poiCard(poi: poi)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func poiCard(poi: MKMapItem) -> some View {
        Button(action: {
            selectedLocation = poi.placemark.coordinate
            selectedLocationName = poi.name
            isUsingCurrentLocation = false
            nearbyPOIs = []
        }) {
            VStack(alignment: .leading, spacing: 8) {
                if let category = poi.pointOfInterestCategory {
                    Image(systemName: iconForPlaceType(category))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(colorForPlaceType(category))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text(poi.name ?? "Unknown")
                    .font(.app(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let address = poi.placemark.title {
                    Text(address)
                        .font(.app(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(width: 140)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 3: Details (Status, Rating, Photos & Comments combined)
    private var detailsStep: some View {
        VStack(spacing: 16) {
            // Status section
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    ForEach(PlaceStatus.allCases, id: \.self) { status in
                        statusButtonCompact(status: status)
                    }
                }
            }
            
            Divider()
            
            // Rating section (reduced height)
            VStack(alignment: .leading, spacing: 8) {
                Text("Rating")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                rating = star
                            }
                        }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 28, weight: .regular))
                                .foregroundStyle(star <= rating ? .yellow : Color(.systemGray4))
                                .symbolEffect(.bounce, value: rating)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                
                if rating > 0 {
                    Text(ratingText)
                        .font(.app(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            
            Divider()
            
            // Comments section (moved below rating)
            VStack(alignment: .leading, spacing: 8) {
                Text("Comment (Optional)")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                TextEditor(text: $comment)
                    .font(.app(size: 14, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(height: 60)
                    .padding(10)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(.systemGray5), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
            }
            
            Divider()
            
            // Photos section (moved to last)
            VStack(alignment: .leading, spacing: 8) {
                Text("Photos")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                PhotosPicker(
                    selection: Binding(
                        get: { selectedPhotos },
                        set: { selectedPhotos = $0 }
                    ),
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(loadedImages.isEmpty ? "Add Photos" : "Add More Photos")
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                
                if !loadedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    
                                    Button(action: {
                                        withAnimation {
                                            loadedImages.remove(at: index)
                                            if index < selectedPhotos.count {
                                                selectedPhotos.remove(at: index)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .background(Color.black.opacity(0.5), in: Circle())
                                    }
                                    .padding(3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func statusButtonCompact(status: PlaceStatus) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedStatus = status
            }
        }) {
            HStack(spacing: 12) {
                Text(status.rawValue)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundStyle(selectedStatus == status ? .white : .primary)
                
                Spacer()
                
                if selectedStatus == status {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                selectedStatus == status
                    ? Color.appAccent
                    : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        selectedStatus == status ? Color.clear : Color(.systemGray5),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: selectedStatus == status ? Color.appAccent.opacity(0.3) : .black.opacity(0.05),
                radius: selectedStatus == status ? 8 : 3,
                y: selectedStatus == status ? 4 : 1
            )
        }
        .buttonStyle(.plain)
    }
    
    private func statusButton(status: PlaceStatus) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedStatus = status
            }
        }) {
            HStack(spacing: 16) {
                Text(status.rawValue)
                    .font(.app(size: 18, weight: .semibold))
                    .foregroundStyle(selectedStatus == status ? .white : .primary)
                
                Spacer()
                
                if selectedStatus == status {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                selectedStatus == status
                    ? Color.appAccent
                    : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        selectedStatus == status ? Color.clear : Color(.systemGray5),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: selectedStatus == status ? Color.appAccent.opacity(0.3) : .black.opacity(0.05),
                radius: selectedStatus == status ? 12 : 4,
                y: selectedStatus == status ? 6 : 2
            )
        }
        .buttonStyle(.plain)
    }
    
    private var ratingText: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                if currentStep == .details {
                    savePlace()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if let nextStep = Step(rawValue: currentStep.rawValue + 1) {
                            currentStep = nextStep
                        }
                    }
                }
            }) {
                Text(currentStep == .details ? "Save Place" : "Continue")
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        canProceedToNextStep ? Color.appAccent : Color(.systemGray4),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .disabled(!canProceedToNextStep)
            .buttonStyle(.plain)
            
            if currentStep != .category {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if let previousStep = Step(rawValue: currentStep.rawValue - 1) {
                            currentStep = previousStep
                        }
                    }
                }) {
                    Text("Back")
                    .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case .category:
            return selectedCategory != nil
        case .location:
            return selectedLocation != nil
        case .details:
            return selectedStatus != nil && rating > 0
        }
    }
    
    // MARK: - Helper Functions
    private func searchForLocationSuggestions(query: String) {
        guard !query.isEmpty else {
            locationSuggestions = []
            searchCompleter.reset()
            return
        }
        searchCompleter.update(query: query)
    }
    
    private func handleLocationSuggestionTap(_ suggestion: PlaceSearchSuggestion) {
        if let completion = suggestion.completion {
            let request = MKLocalSearch.Request(completion: completion)
            request.resultTypes = [.pointOfInterest, .address]
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                DispatchQueue.main.async {
                    if let response = response, let firstResult = response.mapItems.first {
                        selectedLocation = firstResult.placemark.coordinate
                        selectedLocationName = firstResult.name ?? suggestion.name
                        locationSearchText = selectedLocationName ?? ""
                        locationFieldFocused = false
                        locationSuggestions = []
                    }
                }
            }
        } else if let coordinate = suggestion.coordinate {
            selectedLocation = coordinate
            selectedLocationName = suggestion.name
            locationSearchText = suggestion.name
            locationFieldFocused = false
            locationSuggestions = []
        }
    }
    
    private func useCurrentLocation() {
        locationManager.requestLocationPermission()
        locationManager.startUpdatingLocation()
        isUsingCurrentLocation = true
        
        if let location = locationManager.location {
            selectedLocation = location.coordinate
            selectedLocationName = "Current Location"
            
            // Search for nearby POIs
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = selectedCategory?.rawValue ?? "restaurant"
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            request.resultTypes = [.pointOfInterest]
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                DispatchQueue.main.async {
                    if let response = response {
                        nearbyPOIs = Array(response.mapItems.prefix(20))
                    }
                }
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                loadedImages = images
            }
        }
    }
    
    private func iconForPlaceType(_ category: MKPointOfInterestCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .hotel: return "bed.double.fill"
        case .gasStation: return "fuelpump.fill"
        case .parking: return "parkingsign.circle.fill"
        case .museum: return "building.columns.fill"
        case .theater: return "theatermasks.fill"
        case .store: return "bag.fill"
        case .fitnessCenter: return "figure.run"
        case .school: return "graduationcap.fill"
        case .hospital: return "cross.case.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func colorForPlaceType(_ category: MKPointOfInterestCategory) -> Color {
        switch category {
        case .restaurant: return .orange
        case .cafe: return .brown
        case .hotel: return .blue
        case .gasStation: return .red
        case .parking: return .teal
        case .museum: return .purple
        case .theater: return .pink
        case .store: return .green
        case .fitnessCenter: return .mint
        case .school: return .indigo
        case .hospital: return .red
        default: return .appAccent
        }
    }
    
    private func savePlace() {
        // TODO: Save place to data model
        // For now, just dismiss
        dismiss()
    }
}

// Reuse SearchCompleter from ExploreView
private final class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address, .query]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        )
    }
    
    func update(query: String) {
        completer.queryFragment = query
    }
    
    func reset() {
        completer.queryFragment = ""
        results = []
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
