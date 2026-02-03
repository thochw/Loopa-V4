//
//  ExploreView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit
import MapKit
import MapboxMaps
import CoreLocation
import Combine

struct City: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let flag: String
}

struct SearchSuggestion: Identifiable {
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

struct ExploreView: View {
    enum Variant {
        case groups
        case travelers
    }
    
    let variant: Variant
    let onProfileClick: (User) -> Void
    let onAddGroupClick: (CreateType?) -> Void
    let onJoinGroupChat: (Explore) -> Void
    
    @State private var isSheetOpen = true
    @State private var isSheetExpanded = false
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showCitySearch = false
    @State private var currentCity = "Montréal, Canada"
    @State private var homeCity = "Montréal, Canada"
    @State private var lastGeocodedLocation: CLLocation?
    @State private var isGeocoding = false
    @State private var selectedCity: City?
    @State private var showTeleportConfirmation = false
    @State private var showFilters = false
    @State private var selectedLifestyleFilter: String? = nil
    @State private var selectedExploreFilter: String? = nil
    @State private var selectedCreateType: CreateType? = nil
    @State private var selectedJoinItem: JoinItem?
    @State private var showAllTravelers = false
    @State private var showProfileEditor = false
    @State private var friendsSheetType: FriendsSheetType = .travelers
    @State private var selectedSearchPin: SearchPin?
    @State private var selectedPlaceSheet: PlaceSelection?
    @State private var travelAnimationToken = UUID()
    @State private var showCreatePlaceSheet = false
    @State private var exploreViewport: MapboxMaps.Viewport = .camera(center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), zoom: 10, bearing: 0, pitch: 0)
    @State private var animateNextViewportSync = false
    @State private var pendingUserRecenter = false
    @State private var isFollowingUser = false
    @State private var suppressNextViewportSync = false
    @State private var didInitialFriendsRecenter = false
    
    // Search functionality
    @State private var searchText = ""
    @State private var searchSuggestions: [SearchSuggestion] = []
    @State private var isSearchFocused = false
    @State private var isSearching = false
    @FocusState private var searchFieldFocused: Bool
    private var isTeleported: Bool {
        variant == .travelers && currentCity != homeCity
    }
    
    enum CreateType {
        case group
    }

    enum FriendsSheetType: String, CaseIterable {
        case travelers = "Travelers"
        case groups = "Groups"
    }
    
    // Cities database with coordinates
    private let cities: [City] = [
        City(name: "Montréal, Canada", coordinate: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), flag: "🇨🇦"),
        City(name: "Toronto, Canada", coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832), flag: "🇨🇦"),
        City(name: "Vancouver, Canada", coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), flag: "🇨🇦"),
        City(name: "New York, USA", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), flag: "🇺🇸"),
        City(name: "Los Angeles, USA", coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), flag: "🇺🇸"),
        City(name: "San Francisco, USA", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), flag: "🇺🇸"),
        City(name: "Paris, France", coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), flag: "🇫🇷"),
        City(name: "London, UK", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), flag: "🇬🇧"),
        City(name: "Tokyo, Japan", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), flag: "🇯🇵"),
        City(name: "Sydney, Australia", coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), flag: "🇦🇺"),
        City(name: "Berlin, Germany", coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), flag: "🇩🇪"),
        City(name: "Barcelona, Spain", coordinate: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734), flag: "🇪🇸"),
        City(name: "Rome, Italy", coordinate: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), flag: "🇮🇹"),
        City(name: "Amsterdam, Netherlands", coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041), flag: "🇳🇱"),
        City(name: "Lisbon, Portugal", coordinate: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393), flag: "🇵🇹"),
        City(name: "Bangkok, Thailand", coordinate: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018), flag: "🇹🇭"),
        City(name: "Dubai, UAE", coordinate: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708), flag: "🇦🇪"),
        City(name: "Singapore", coordinate: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198), flag: "🇸🇬"),
        City(name: "Seoul, South Korea", coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), flag: "🇰🇷"),
        City(name: "Mexico City, Mexico", coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332), flag: "🇲🇽")
    ]
    
    private let data = AppData.shared
    
    private var exploreMapView: some View {
        MapboxMaps.Map(viewport: $exploreViewport) {
            MapboxMaps.Puck2D(bearing: .heading)
            MapboxMaps.ForEvery(annotations) { item in
                MapboxMaps.MapViewAnnotation(coordinate: item.coordinate) {
                    annotationView(for: item)
                }
            }
        }
        .mapStyle(MapboxMaps.MapStyle.appStyle)
        .ignoresSafeArea()
        .onAppear {
            syncViewport(animated: false)
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
        }
        .onChange(of: region.center.latitude) { _, _ in
            if suppressNextViewportSync {
                suppressNextViewportSync = false
                return
            }
            syncViewport(animated: animateNextViewportSync)
            animateNextViewportSync = false
        }
        .onChange(of: region.center.longitude) { _, _ in
            if suppressNextViewportSync {
                suppressNextViewportSync = false
                return
            }
            syncViewport(animated: animateNextViewportSync)
            animateNextViewportSync = false
        }
        .onChange(of: region.span.latitudeDelta) { _, _ in
            syncViewport(animated: false)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map (Mapbox)
                exploreMapView
                .onTapGesture {
                    isFollowingUser = false
                    if variant == .groups && isSheetExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isSheetExpanded = false
                        }
                    }
                }
                .onChange(of: isSheetOpen) { _, isOpen in
                    guard variant == .travelers else { return }
                    if isFollowingUser {
                        if let coordinate = locationManager.location?.coordinate {
                            recenterMapOnUser(coordinate)
                        }
                        return
                    }
                    let baseCoordinate = selectedSearchPin?.coordinate
                        ?? locationManager.location?.coordinate
                        ?? region.center
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        region.center = mapCenterForSheet(baseCoordinate, isOpen: isOpen)
                    }
                }
                .onChange(of: locationManager.location) { oldValue, newValue in
                    if let newLocation = newValue {
                        if variant == .travelers && !didInitialFriendsRecenter && !isTeleported && selectedSearchPin == nil {
                            didInitialFriendsRecenter = true
                            currentCity = homeCity
                            recenterMapOnUser(newLocation.coordinate)
                            updateCityFromLocation(newLocation)
                            return
                        }
                        if isFollowingUser {
                            updateCityFromLocation(newLocation)
                            return
                        }
                        if !isTeleported && selectedSearchPin == nil {
                        withAnimation {
                                region.center = adjustedCenter(newLocation.coordinate)
                            }
                        }
                        updateCityFromLocation(newLocation)
                        if pendingUserRecenter {
                            pendingUserRecenter = false
                            recenterMapOnUser(newLocation.coordinate)
                        }
                    }
                }
                .onReceive(searchCompleter.$results) { results in
                    guard !searchText.isEmpty else {
                        searchSuggestions = []
                        isSearching = false
                        return
                    }

                    let suggestions = results.prefix(12).map { completion in
                        SearchSuggestion(
                            name: completion.title,
                            subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                            coordinate: nil,
                            type: .poi,
                            icon: "mappin.circle.fill",
                            completion: completion
                        )
                    }
                    searchSuggestions = suggestions
                    isSearching = false
                }
                
                // Header
                VStack {
                    headerView
                    Spacer()
                }
                
                // Bottom Sheet (Travelers only)
                if variant == .travelers && !isTeleported {
                VStack {
                    Spacer()
                    bottomSheet
                        .frame(height: isSheetOpen ? sheetHeight(for: geometry.size.height) : 0)
                        .offset(y: isSheetOpen ? 0 : sheetHeight(for: geometry.size.height))
                        .padding(.horizontal, 16) // Match navigation bar width
                }
                .ignoresSafeArea(edges: .bottom)
                }
                
                
                // Floating Action Buttons (Right Side) - Only for Groups variant
                if variant == .groups {
                    VStack(spacing: 16) {
                        // Recenter Map Button (on top)
                                Button(action: {
                            if let location = locationManager.location {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentCity = homeCity
                                    selectedSearchPin = nil
                                    recenterMapOnUser(location.coordinate)
                                }
                                updateCityFromLocation(location)
                            } else {
                                pendingUserRecenter = true
                                locationManager.requestLocationPermission()
                                locationManager.startUpdatingLocation()
                                recenterMapOnUser(locationManager.location?.coordinate ?? region.center)
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: 50, height: 50)
                                .background(
                                    .regularMaterial,
                                    in: Circle()
                                )
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        }
                        
                        // Add Place Button (below, white on blue) - Opens sheet directly
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCreatePlaceSheet = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Color.appAccent,
                                    in: Circle()
                                )
                                .shadow(color: Color.appAccent.opacity(0.4), radius: 12, y: 6)
                        }
                    }
                    .padding(.trailing, 20)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(y: 250)
                }

                if variant == .travelers {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                if let location = locationManager.location {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        currentCity = homeCity
                                        selectedSearchPin = nil
                                        recenterMapOnUser(location.coordinate)
                                    }
                                    updateCityFromLocation(location)
                                } else {
                                    pendingUserRecenter = true
                                    locationManager.requestLocationPermission()
                                    locationManager.startUpdatingLocation()
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        .regularMaterial,
                                        in: Circle()
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    onAddGroupClick(.group)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Color.appAccent,
                                        in: Circle()
                                    )
                                    .shadow(color: Color.appAccent.opacity(0.4), radius: 12, y: 6)
                            }
                        }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 20)
                        .padding(.bottom, isSheetOpen ? sheetHeight(for: geometry.size.height) - 24 : 80)
                    }
                }
                
                // Show Travelers Button (when sheet is closed)
                if variant == .travelers && !isSheetOpen {
                    VStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if isTeleported {
                                    if let location = locationManager.location {
                                        selectedSearchPin = nil
                                        region.center = adjustedCenter(location.coordinate)
                                    } else {
                                        selectedSearchPin = nil
                                        region.center = adjustedCenter(CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673))
                                    }
                                    currentCity = homeCity
                                }
                                isSheetExpanded = false
                                isSheetOpen = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Show Travelers")
                                    .font(.app(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Color(hex: "222222"),
                                in: Capsule()
                            )
                            .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                        }
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .sheet(isPresented: $showCitySearch) {
                CitySearchView(
                    cities: cities,
                    currentCity: currentCity,
                    onCitySelected: { city in
                        selectedCity = city
                        showTeleportConfirmation = true
                        showCitySearch = false
                    }
                )
            }
            .alert("Téléporter la carte ?", isPresented: $showTeleportConfirmation) {
                Button("Annuler", role: .cancel) {
                    selectedCity = nil
                }
                Button("Téléporter") {
                    if let city = selectedCity {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentCity = city.name
                            selectedSearchPin = nil
                            animateToPlace(city.coordinate)
                            if variant == .travelers {
                                isSheetOpen = false
                            }
                        }
                    }
                    selectedCity = nil
                }
            } message: {
                Text("Do you really want to teleport?")
            }
            .sheet(isPresented: $showFilters) {
                TravelersFilterView()
            }
            .sheet(isPresented: $showAllTravelers) {
                allTravelersSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            .sheet(item: $selectedPlaceSheet) { selection in
                PlaceDetailSheet(mapItem: selection.item) {
                    selectedPlaceSheet = nil
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
            }
            .fullScreenCover(isPresented: $showProfileEditor) {
                ProfileEditorView {
                    showProfileEditor = false
                }
            }
            .sheet(isPresented: $showCreatePlaceSheet) {
                CreatePlaceView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            if variant == .groups {
                groupsHeader
            } else {
                travelersHeader
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
    }
    
    private var groupsHeader: some View {
        VStack(spacing: 12) {
            // Enhanced Search Bar with profile picture inside (full width)
            ZStack(alignment: .top) {
        HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search a place to save...", text: $searchText)
                        .font(.app(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($searchFieldFocused)
                        .onChange(of: searchText) { oldValue, newValue in
                            if !newValue.isEmpty {
                                searchForSuggestions(query: newValue)
                            } else {
                                searchSuggestions = []
                                selectedSearchPin = nil
                            }
                        }
                        .onSubmit {
                            performSearch()
                        }
            
            Spacer()
            
                    // Profile picture or close button (inside search bar) - same size to prevent layout shift
                    Group {
                        if searchText.isEmpty && !searchFieldFocused {
                            Button(action: {
                                showProfileEditor = true
                            }) {
                    AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                        } else {
                            ProgressView()
                                .tint(.secondary)
                        }
                    }
                                .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    searchText = ""
                                    searchSuggestions = []
                                    searchFieldFocused = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(Color.appAccent.opacity(0.7))
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .frame(width: 32, height: 32)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                
                // Search Suggestions Dropdown - scrollable list
                if !searchSuggestions.isEmpty && searchFieldFocused {
                    ScrollView(showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(searchSuggestions.enumerated()), id: \.element.id) { index, suggestion in
            Button(action: {
                                    handleSuggestionTap(suggestion)
                                }) {
                                    HStack(spacing: 12) {
                                        searchSuggestionIcon(suggestion)
                                        
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
                                
                                if index < searchSuggestions.count - 1 {
                                    Divider()
                                        .padding(.leading, 64)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    .padding(.top, 60)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedExploreFilter = selectedExploreFilter == "food" ? nil : "food"
                        }
                    }) {
                        filterChipContent(emoji: "🥪", text: "Food", isSelected: selectedExploreFilter == "food")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedExploreFilter = selectedExploreFilter == "cafes" ? nil : "cafes"
                        }
                    }) {
                        filterChipContent(emoji: "🍵", text: "Cafes", isSelected: selectedExploreFilter == "cafes")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedExploreFilter = selectedExploreFilter == "bars" ? nil : "bars"
                        }
                    }) {
                        filterChipContent(emoji: "🍹", text: "Bars", isSelected: selectedExploreFilter == "bars")
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedExploreFilter = selectedExploreFilter == "activities" ? nil : "activities"
                        }
                    }) {
                        filterChipContent(emoji: "🎡", text: "Activities", isSelected: selectedExploreFilter == "activities")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var travelersHeader: some View {
        VStack(spacing: 12) {
            // Enhanced Search Bar with profile picture inside (full width)
            ZStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField(currentCity, text: $searchText)
                        .font(.app(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($searchFieldFocused)
                        .onChange(of: searchText) { oldValue, newValue in
                            if !newValue.isEmpty {
                                searchForSuggestions(query: newValue)
                            } else {
                                searchSuggestions = []
                                selectedSearchPin = nil
                            }
                        }
                        .onSubmit {
                            performSearch()
                        }
                    
                    Spacer()
                    
                    // Profile picture or close button (inside search bar) - same size to prevent layout shift
                    Group {
                        if searchText.isEmpty && !searchFieldFocused {
                            Button(action: {
                                showProfileEditor = true
                            }) {
                                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else if phase.error != nil {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ProgressView()
                                            .tint(.secondary)
                                    }
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    searchText = ""
                                    searchSuggestions = []
                                    searchFieldFocused = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(Color.appAccent.opacity(0.7))
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .frame(width: 32, height: 32)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                
                // Search Suggestions Dropdown - scrollable list
                if !searchSuggestions.isEmpty && searchFieldFocused {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(searchSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                                Button(action: {
                                    handleSuggestionTap(suggestion)
                                }) {
                                    HStack(spacing: 12) {
                                        searchSuggestionIcon(suggestion)
                                        
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
                                
                                if index < searchSuggestions.count - 1 {
                                    Divider()
                                        .padding(.leading, 64)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    .padding(.top, 60)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 6)
            
            // Enhanced Filter Chips with better spacing
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            showFilters = true
                        }
                    }) {
                        filterChipContent(icon: "slider.horizontal.3", text: "Filter", isPrimary: true)
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLifestyleFilter = selectedLifestyleFilter == "backpacking" ? nil : "backpacking"
                        }
                    }) {
                        filterChipContent(emoji: "🎒", text: "backpacking", isSelected: selectedLifestyleFilter == "backpacking")
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLifestyleFilter = selectedLifestyleFilter == "digital nomad" ? nil : "digital nomad"
                        }
                    }) {
                        filterChipContent(emoji: "💻", text: "digital nomad", isSelected: selectedLifestyleFilter == "digital nomad")
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLifestyleFilter = selectedLifestyleFilter == "gap year" ? nil : "gap year"
                        }
                    }) {
                        filterChipContent(emoji: "👋", text: "gap year", isSelected: selectedLifestyleFilter == "gap year")
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLifestyleFilter = selectedLifestyleFilter == "studying abroad" ? nil : "studying abroad"
                        }
                    }) {
                        filterChipContent(emoji: "📚", text: "studying abroad", isSelected: selectedLifestyleFilter == "studying abroad")
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLifestyleFilter = selectedLifestyleFilter == "living abroad" ? nil : "living abroad"
                        }
                    }) {
                        filterChipContent(emoji: "🏠", text: "living abroad", isSelected: selectedLifestyleFilter == "living abroad")
                    }
                    .buttonStyle(.plain)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLifestyleFilter = selectedLifestyleFilter == "au pair" ? nil : "au pair"
                        }
                    }) {
                        filterChipContent(emoji: "🤹", text: "au pair", isSelected: selectedLifestyleFilter == "au pair")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func filterChipContent(icon: String? = nil, emoji: String? = nil, text: String, isPrimary: Bool = false, isSelected: Bool = false) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
            }
            if let emoji = emoji {
                Text(emoji)
                    .font(.app(size: 16))
            }
            Text(text)
                .font(.app(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? AnyShapeStyle(Color.appAccent)
                : AnyShapeStyle(.regularMaterial),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    isSelected ? Color.clear : Color(.systemGray5).opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }
    
    private func getCityName(from cityString: String) -> String {
        // Keep "City, Country" format for the search bar
        return cityString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getCityFlag(from cityString: String) -> String {
        // Match by city name first
        if let city = cities.first(where: { $0.name == cityString }) {
            return city.flag
        }

        // Fallback: derive from country part of "City, Country"
        let components = cityString.components(separatedBy: ", ")
        if components.count >= 2 {
            let country = components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return flagForCountry(country)
        }

        return "🇨🇦" // Default flag
    }

    private func flagForCountry(_ country: String) -> String {
        switch country.lowercased() {
        case "canada":
            return "🇨🇦"
        case "usa", "united states", "united states of america":
            return "🇺🇸"
        case "uk", "united kingdom":
            return "🇬🇧"
        case "france":
            return "🇫🇷"
        case "germany":
            return "🇩🇪"
        case "australia":
            return "🇦🇺"
        case "japan":
            return "🇯🇵"
        case "spain":
            return "🇪🇸"
        case "italy":
            return "🇮🇹"
        case "netherlands":
            return "🇳🇱"
        case "portugal":
            return "🇵🇹"
        case "thailand":
            return "🇹🇭"
        case "uae", "united arab emirates":
            return "🇦🇪"
        case "singapore":
            return "🇸🇬"
        case "south korea", "korea, republic of":
            return "🇰🇷"
        case "mexico":
            return "🇲🇽"
        default:
            return "🇨🇦"
        }
    }

    private func updateCityFromLocation(_ location: CLLocation) {
        if isGeocoding {
            return
        }
        if let lastLocation = lastGeocodedLocation,
           location.distance(from: lastLocation) < 5000 {
            return
        }

        let wasTeleported = isTeleported
        isGeocoding = true

        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            isGeocoding = false
            guard error == nil, let placemark = placemarks?.first else { return }

            let city = placemark.locality
                ?? placemark.subAdministrativeArea
                ?? placemark.administrativeArea
            let country = placemark.country

            guard let city, let country else { return }

            let cityString = "\(city), \(country)"
            homeCity = cityString
            if !wasTeleported {
                currentCity = cityString
            }
            lastGeocodedLocation = location
        }
    }

    private func adjustedCenter(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        mapCenterForSheet(coordinate, isOpen: isSheetOpen)
    }

    private func syncViewport(animated: Bool) {
        let nextViewport = MapboxMaps.Viewport.camera(
            center: region.center,
            zoom: mapboxZoom(from: region.span),
            bearing: 0,
            pitch: 0
        )
        if animated {
            withViewportAnimation(.easeInOut(duration: 0.35)) {
                exploreViewport = nextViewport
            }
        } else {
            exploreViewport = nextViewport
        }
    }

    private func recenterMapOnUser(_ coordinate: CLLocationCoordinate2D) {
        isFollowingUser = true
        suppressNextViewportSync = true
        region.center = coordinate
        let bottomPadding: CGFloat = (variant == .travelers && isSheetOpen) ? 420 : 0
        let viewportPadding = EdgeInsets(top: 0, leading: 0, bottom: bottomPadding, trailing: 0)
        withViewportAnimation(.default(maxDuration: 0.6)) {
            exploreViewport = .followPuck(
                zoom: max(mapboxZoom(from: region.span), 13),
                bearing: .heading,
                pitch: 0
            ).padding(viewportPadding)
        }
    }

    private func mapCenterForSheet(_ coordinate: CLLocationCoordinate2D, isOpen: Bool) -> CLLocationCoordinate2D {
        guard variant == .travelers, isOpen else { return coordinate }
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude - 0.030,
            longitude: coordinate.longitude
        )
    }
    
    private func iconButton(icon: String, color: Color = .secondary) -> some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 38, height: 38) // HIG minimum touch target
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            // Enhanced Drag Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 4)
            
            ScrollView {
                ZStack(alignment: .top) {
                    if let joinItem = selectedJoinItem {
                        joinBottomSheetContent(item: joinItem)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if variant == .groups {
                    groupsContent
                            .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                        friendsSheetContent
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedJoinItem?.id)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if variant == .groups,
                           value.translation.height < -10,
                           !isSheetExpanded,
                           selectedJoinItem == nil {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isSheetExpanded = true
                            }
                        }
                    }
            )
            .padding(.top, 4)
        }
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 28,
                bottomLeading: 24,
                bottomTrailing: 24,
                topTrailing: 28
            ),
            style: .continuous
        ))
        .shadow(color: .black.opacity(0.15), radius: 30, y: -8)
        .padding(.bottom, 100) // Space for navigation bar
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Smooth drag feedback
                }
                .onEnded { value in
                    if variant == .groups {
                        if value.translation.height > 120 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if isSheetExpanded {
                                    isSheetExpanded = false
                                } else {
                                    isSheetOpen = false
                                }
                            }
                        } else if value.translation.height < -120 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSheetOpen = true
                                isSheetExpanded = true
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSheetOpen = true
                            }
                        }
                    } else {
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSheetOpen = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSheetOpen = true
                            }
                        }
                    }
                }
        )
    }
    
    private func sheetHeight(for screenHeight: CGFloat) -> CGFloat {
        // Increased height for join views to avoid scrolling
        if selectedJoinItem != nil {
            return screenHeight * 0.70
        }
        if variant == .groups && isSheetExpanded {
            return variant == .groups ? screenHeight * 0.75 : screenHeight * 0.80
        }
        return variant == .groups ? screenHeight * 0.50 : screenHeight * 0.55
    }
    
    private var groupsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            groupsView
        }
        .padding(.bottom, 20)
        .padding(.top, 0)
    }

    private var friendsSheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("View Type", selection: $friendsSheetType) {
                ForEach(FriendsSheetType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            ZStack(alignment: .top) {
                if friendsSheetType == .groups {
                groupsView
                        .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                    travelersContent
                        .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: friendsSheetType)
        }
        .padding(.bottom, 20)
        .padding(.top, 0)
    }
    
    private var groupsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nearby Groups")
                .font(.app(size: 24, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
            
            ForEach(data.groups) { group in
                groupRow(group: group)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    
    private func groupRow(group: Explore) -> some View {
        Button(action: {
            handleGroupTap(group)
        }) {
            HStack(spacing: 16) {
                // Enhanced group image with rounded rectangle style
                AsyncImage(url: URL(string: group.image)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemGray5))
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemGray6))
                            
                            ProgressView()
                                .tint(.secondary)
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.systemGray5).opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.title)
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        avatarStack(avatars: group.avatars)
                        
                        Text("\(group.attendees) Travelers")
                            .font(.app(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var filteredUsers: [User] {
        guard let lifestyleFilter = selectedLifestyleFilter else {
            return data.users
        }
        // Filter users by selected lifestyle
        return data.users.filter { user in
            user.lifestyle?.lowercased() == lifestyleFilter.lowercased()
        }
    }
    
    private var travelersContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(filteredUsers.count) Nearby Travelers")
                    .font(.app(size: 22, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filteredUsers) { user in
                        travelerCard(user: user)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Button(action: {
                showAllTravelers = true
            }) {
                Text("See all 468 Nearby Travelers")
                    .font(.app(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func travelerCard(user: User) -> some View {
        Button(action: {
            onProfileClick(user)
        }) {
            ZStack(alignment: .bottomLeading) {
                userImageView(user)
                        .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 140)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 65)
                .offset(y: 37.5)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.flag)
                        .font(.app(size: 16))
                        .offset(y: -120)
                        .padding(.leading, 8)
                        .padding(.top, 8)
                    
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.app(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                    }
                    .offset(y: -8)
                    
                    Text(user.distance)
                        .font(.app(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: -8)
                }
                .padding(.leading, 10)
                .padding(.bottom, 10)
            }
            .frame(width: 110, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func avatarStack(avatars: [String]) -> some View {
        HStack(spacing: -8) {
            ForEach(Array(avatars.prefix(3).enumerated()), id: \.offset) { _, avatar in
                AsyncImage(url: URL(string: avatar)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }
    
    // MARK: - Annotations
    private var annotations: [AnnotationItem] {
        var items: [AnnotationItem]
        switch variant {
        case .groups:
            items = filteredGroups.map {
                AnnotationItem(id: "group-\($0.id)", coordinate: $0.coordinate, type: .group($0))
            }
        case .travelers:
            items = data.users.map {
                AnnotationItem(id: "user-\($0.id)", coordinate: $0.coordinate, type: .user($0))
            }
        }

        if let pin = selectedSearchPin {
            items.append(AnnotationItem(id: "search-\(pin.id)", coordinate: pin.coordinate, type: .search(pin)))
        }

        return items
    }
    
    private func annotationView(for item: AnnotationItem) -> some View {
        switch item.type {
        case .group(let group):
            return AnyView(groupAnnotation(group: group))
        case .user(let user):
            return AnyView(userAnnotation(user: user))
        case .search(let pin):
            return AnyView(searchPinAnnotation(pin: pin))
        }
    }
    
    private func groupAnnotation(group: Explore) -> some View {
        HStack(spacing: 0) {
            AsyncImage(url: URL(string: group.image)) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .background(Circle().fill(Color.white).padding(2))
            
            Text(group.title)
                .font(.app(size: 10, weight: .bold))
                .foregroundStyle(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 8)
                .offset(x: -4)
        }
        .onTapGesture {
            handleGroupTap(group)
        }
    }
    
    private func userAnnotation(user: User) -> some View {
        ZStack {
            userImageView(user)
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .offset(x: 16, y: -16)
        }
        .onTapGesture {
            onProfileClick(user)
        }
    }
    
    private struct AnnotationItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let type: AnnotationType
        
        enum AnnotationType {
            case group(Explore)
            case user(User)
            case search(SearchPin)
        }
    }

    private struct SearchPin {
        let id = UUID().uuidString
        let coordinate: CLLocationCoordinate2D
        let title: String?
        let iconName: String
        let tint: Color
    }

    private struct PlaceSelection: Identifiable {
        let id = UUID()
        let item: MKMapItem
    }

    private func searchPinAnnotation(pin: SearchPin) -> some View {
        VStack(spacing: 4) {
            Image(systemName: pin.iconName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(pin.tint)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)

            if let title = pin.title, !title.isEmpty {
                Text(title)
                    .font(.app(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func userImageView(_ user: User) -> some View {
        if let url = URL(string: user.image), url.scheme != nil {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
        } else if let uiImage = UIImage(named: user.image) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            Color.gray.opacity(0.3)
        }
    }

    private func handleGroupTap(_ group: Explore) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            region.center = group.coordinate
            isSheetOpen = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            selectedJoinItem = .group(group)
        }
    }

    private var filteredGroups: [Explore] {
        guard let filter = selectedExploreFilter else { return data.groups }
        let keywords: [String]
        switch filter {
        case "food":
            keywords = ["restaurant", "food", "dinner", "lunch", "brunch"]
        case "cafes":
            keywords = ["cafe", "café", "coffee"]
        case "bars":
            keywords = ["bar", "bars", "cocktail", "club", "pub", "wine"]
        case "activities":
            keywords = ["activity", "activities", "hangout", "art", "gym", "billiard"]
        default:
            keywords = []
        }
        if keywords.isEmpty {
            return data.groups
        }
        return data.groups.filter { group in
            let title = group.title.lowercased()
            return keywords.contains { title.contains($0) }
        }
    }

    @ViewBuilder
    private func joinBottomSheetContent(item: JoinItem) -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: { selectedJoinItem = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color(.systemGray6), in: Circle())
                }
            }
            .padding(.horizontal, 20)

            switch item {
            case .group(let group):
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: group.image)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.title)
                            .font(.app(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text("\(group.attendees) Travelers")
                            .font(.app(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    Button(action: {
                        selectedJoinItem = nil
                        onJoinGroupChat(group)
                    }) {
                        Text("Save Place")
                            .font(.app(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    Button(action: { selectedJoinItem = nil }) {
                        Text("Close")
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                }

            }
        }
        .padding(.bottom, 20)
    }

    private var allTravelersSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Nearby Travelers")
                    .font(.app(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: { showAllTravelers = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredUsers) { user in
                        travelerListRow(user: user)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }

    private func travelerListRow(user: User) -> some View {
        Button(action: {
            showAllTravelers = false
            onProfileClick(user)
        }) {
            HStack(spacing: 12) {
                userImageView(user)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.app(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Circle()
                            .fill(user.online ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                    Text(user.flag)
                        .font(.app(size: 14))
                }
                
                Spacer()
                
                Text(user.distance)
                    .font(.app(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private enum JoinItem: Identifiable {
        case group(Explore)

        var id: String {
            switch self {
            case .group(let group):
                return "group-\(group.id)"
            }
        }
    }
    
    // MARK: - Search Functions
    
    private func searchForSuggestions(query: String) {
        guard !query.isEmpty else {
            searchSuggestions = []
            isSearching = false
            searchCompleter.reset()
            return
        }
        
        isSearching = true
        searchCompleter.update(query: query)
    }
    
    private func iconForPlaceType(_ category: MKPointOfInterestCategory?) -> String {
        guard let category = category else {
            return "mappin.circle.fill"
        }
        
        switch category {
        case .restaurant:
            return "fork.knife"
        case .cafe:
            return "cup.and.saucer.fill"
        case .hotel:
            return "bed.double.fill"
        case .gasStation:
            return "fuelpump.fill"
        case .parking:
            return "parkingsign.circle.fill"
        case .museum:
            return "building.columns.fill"
        case .theater:
            return "theatermasks.fill"
        case .store:
            return "bag.fill"
        case .fitnessCenter:
            return "figure.run"
        case .school:
            return "graduationcap.fill"
        case .hospital:
            return "cross.case.fill"
        default:
            return "mappin.circle.fill"
        }
    }

    private func colorForPlaceType(_ category: MKPointOfInterestCategory?) -> Color {
        guard let category = category else { return .appAccent }
        switch category {
        case .restaurant:
            return .orange
        case .cafe:
            return .brown
        case .hotel:
            return .blue
        case .gasStation:
            return .red
        case .parking:
            return .teal
        case .museum:
            return .purple
        case .theater:
            return .pink
        case .store:
            return .green
        case .fitnessCenter:
            return .mint
        case .school:
            return .indigo
        case .hospital:
            return .red
        default:
            return .appAccent
        }
    }

    private func colorForSuggestionIcon(_ iconName: String) -> Color {
        switch iconName {
        case "fork.knife":
            return .orange
        case "cup.and.saucer.fill":
            return .brown
        case "bed.double.fill":
            return .blue
        case "fuelpump.fill":
            return .red
        case "parkingsign.circle.fill":
            return .teal
        case "building.columns.fill":
            return .purple
        case "theatermasks.fill":
            return .pink
        case "bag.fill":
            return .green
        case "figure.run":
            return .mint
        case "graduationcap.fill":
            return .indigo
        case "cross.case.fill":
            return .red
        default:
            return .appAccent
        }
    }

    private func searchSuggestionIcon(_ suggestion: SearchSuggestion) -> some View {
        let tint = colorForSuggestionIcon(suggestion.icon)
        return ZStack {
            Circle()
                .fill(tint.opacity(0.18))
            Image(systemName: suggestion.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 30, height: 30)
    }
    
    private func handleSuggestionTap(_ suggestion: SearchSuggestion) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            searchText = suggestion.name
            searchFieldFocused = false
            searchSuggestions = []
        }

        if let completion = suggestion.completion {
            performSearch(for: completion)
            return
        }

        // If it's a city, teleport to it
        if suggestion.type == .city, let coordinate = suggestion.coordinate {
            selectedSearchPin = SearchPin(
                coordinate: coordinate,
                title: suggestion.name,
                iconName: "mappin.circle.fill",
                tint: .appAccent
            )
            teleportToLocation(coordinate)
        } else if let coordinate = suggestion.coordinate {
            // For places, center the map on the location
            animateToPlace(coordinate)
            selectedSearchPin = SearchPin(
                coordinate: coordinate,
                title: suggestion.name,
                iconName: "mappin.circle.fill",
                tint: .appAccent
            )
        } else {
            performSearch()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        // Use MKLocalSearch for WORLDWIDE full search
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        // Set worldwide region (entire globe) - allows searching all POIs worldwide
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        )
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response, let firstResult = response.mapItems.first {
                    let coordinate = firstResult.placemark.coordinate
                    selectedSearchPin = SearchPin(
                        coordinate: coordinate,
                        title: firstResult.name,
                        iconName: iconForPlaceType(firstResult.pointOfInterestCategory),
                        tint: colorForPlaceType(firstResult.pointOfInterestCategory)
                    )
                    selectedPlaceSheet = PlaceSelection(item: firstResult)

                    // Center map on the found location
                    self.animateToPlace(coordinate)
                }
                
                self.searchFieldFocused = false
                self.searchSuggestions = []
            }
        }
    }

    private func performSearch(for completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = [.pointOfInterest, .address]

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response, let firstResult = response.mapItems.first {
                    let coordinate = firstResult.placemark.coordinate
                    selectedSearchPin = SearchPin(
                        coordinate: coordinate,
                        title: firstResult.name,
                        iconName: iconForPlaceType(firstResult.pointOfInterestCategory),
                        tint: colorForPlaceType(firstResult.pointOfInterestCategory)
                    )
                    selectedPlaceSheet = PlaceSelection(item: firstResult)
                    self.animateToPlace(coordinate)
                }

                self.searchFieldFocused = false
                self.searchSuggestions = []
            }
        }
    }
    
    private func teleportToLocation(_ coordinate: CLLocationCoordinate2D) {
        // Find matching city
        if let city = cities.first(where: { city in
            abs(city.coordinate.latitude - coordinate.latitude) < 0.1 &&
            abs(city.coordinate.longitude - coordinate.longitude) < 0.1
        }) {
            selectedCity = city
            showTeleportConfirmation = true
        }
    }

    private func zoomToPlace(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
    }

    private func animateToPlace(_ coordinate: CLLocationCoordinate2D) {
        let token = UUID()
        travelAnimationToken = token
        let currentSpan = region.span

        withAnimation(.easeInOut(duration: 0.6)) {
            region.center = coordinate
            region.span = currentSpan
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard travelAnimationToken == token else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                zoomToPlace(coordinate)
            }
        }
    }
}

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

private struct PlaceDetailSheet: View {
    let mapItem: MKMapItem
    let onClose: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var isSaved = false

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 6)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.appAccent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(mapItem.name ?? "Place")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let category = categoryLabel {
                        Text(category)
                            .font(.app(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    if let address = formattedAddress {
                        Text(address)
                            .font(.app(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray6), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    let phoneUrl = mapItem.phoneNumber
                        .flatMap { number in
                            URL(string: "tel://\(number.filter { $0.isNumber })")
                        }
                    let websiteUrl = mapItem.url

                    Button(action: { if let websiteUrl { openURL(websiteUrl) } }) {
                        ctaButton(
                            title: "Website",
                            detail: nil,
                            systemImage: "safari.fill",
                            foreground: .primary,
                            background: Color(.systemGray6)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(websiteUrl == nil)
                    .opacity(websiteUrl == nil ? 0.45 : 1)

                    Button(action: { if let phoneUrl { openURL(phoneUrl) } }) {
                        ctaButton(
                            title: "Call",
                            detail: nil,
                            systemImage: "phone.fill",
                            foreground: .primary,
                            background: Color(.systemGray6)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(phoneUrl == nil)
                    .opacity(phoneUrl == nil ? 0.45 : 1)

                    Button(action: { isSaved.toggle() }) {
                        ctaButton(
                            title: isSaved ? "Saved" : "Save",
                            detail: nil,
                            systemImage: isSaved ? "bookmark.fill" : "bookmark",
                            foreground: .primary,
                            background: Color(.systemGray6)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: openDirections) {
                    ctaButton(
                        title: "Directions",
                        detail: nil,
                        systemImage: "arrow.triangle.turn.up.right.circle.fill",
                        foreground: .white,
                        background: Color.appAccent
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 16)
    }

    private var formattedAddress: String? {
        let placemark = mapItem.placemark
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        let cityLine = [placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
        var parts = [street, cityLine].filter { !$0.isEmpty }
        if let country = placemark.country, !country.isEmpty {
            parts.append(country)
        }
        return parts.isEmpty ? placemark.title : parts.joined(separator: " • ")
    }

    private var categoryLabel: String? {
        guard let category = mapItem.pointOfInterestCategory else { return nil }
        switch category {
        case .airport: return "Airport"
        case .amusementPark: return "Amusement park"
        case .aquarium: return "Aquarium"
        case .atm: return "ATM"
        case .bakery: return "Bakery"
        case .bank: return "Bank"
        case .beach: return "Beach"
        case .brewery: return "Brewery"
        case .cafe: return "Cafe"
        case .campground: return "Campground"
        case .carRental: return "Car rental"
        case .evCharger: return "EV charger"
        case .fireStation: return "Fire station"
        case .fitnessCenter: return "Fitness center"
        case .foodMarket: return "Food market"
        case .gasStation: return "Gas station"
        case .hospital: return "Hospital"
        case .hotel: return "Hotel"
        case .laundry: return "Laundry"
        case .library: return "Library"
        case .marina: return "Marina"
        case .movieTheater: return "Movie theater"
        case .museum: return "Museum"
        case .nationalPark: return "National park"
        case .nightlife: return "Nightlife"
        case .park: return "Park"
        case .parking: return "Parking"
        case .pharmacy: return "Pharmacy"
        case .police: return "Police"
        case .postOffice: return "Post office"
        case .publicTransport: return "Public transport"
        case .restaurant: return "Restaurant"
        case .restroom: return "Restroom"
        case .school: return "School"
        case .stadium: return "Stadium"
        case .store: return "Store"
        case .theater: return "Theater"
        case .university: return "University"
        case .winery: return "Winery"
        case .zoo: return "Zoo"
        default: return nil
        }
    }

    private func ctaButton(
        title: String,
        detail: String?,
        systemImage: String,
        foreground: Color,
        background: Color
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.app(size: 14, weight: .semibold))
            }
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.app(size: 11, weight: .regular))
                    .foregroundStyle(foreground.opacity(foreground == .white ? 0.85 : 0.7))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(background, in: Capsule())
    }

    private func openDirections() {
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
