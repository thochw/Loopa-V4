//
//  ExploreView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct City: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let flag: String
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
    @State private var showCreateOptions = false
    @State private var selectedCreateType: CreateType? = nil
    @State private var selectedJoinItem: JoinItem?
    @State private var showAllTravelers = false
    @State private var showProfileEditor = false
    @State private var friendsSheetType: FriendsSheetType = .travelers
    private var isTeleported: Bool {
        variant == .travelers && currentCity != homeCity
    }
    
    enum CreateType {
        case group
    }

    enum FriendsSheetType: String, CaseIterable {
        case travelers = "Travelers"
        case groups = "Places"
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        annotationView(for: item)
                    }
                }
                .ignoresSafeArea()
                .onTapGesture {
                    if variant == .groups && isSheetExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isSheetExpanded = false
                        }
                    }
                }
                .onAppear {
                    locationManager.requestLocationPermission()
                    locationManager.startUpdatingLocation()
                }
                .onChange(of: locationManager.location) { oldValue, newValue in
                    if let newLocation = newValue {
                        if !isTeleported {
                            withAnimation {
                                region.center = adjustedCenter(newLocation.coordinate)
                            }
                        }
                        updateCityFromLocation(newLocation)
                    }
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
                
                // Tap to dismiss pastilles (behind buttons but above map)
                if showCreateOptions && variant == .groups {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCreateOptions = false
                            }
                        }
                        .ignoresSafeArea()
                }
                
                // Floating Action Buttons (Right Side) - Only for Groups variant
                if variant == .groups {
                    HStack(spacing: 12) {
                        // Create Options Pills (Groups/Events) - Vertical Stack
                        if showCreateOptions {
                            VStack(spacing: 8) {
                                // Groups Pill
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCreateType = .group
                                        showCreateOptions = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            onAddGroupClick(.group)
                                        }
                                    }
                                }) {
                                    Text("Add place")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.appAccent, in: Capsule())
                                        .shadow(color: Color.appAccent.opacity(0.4), radius: 8, y: 4)
                                }
                                .buttonStyle(.plain)
                                
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        VStack(spacing: 12) {
                            // Recenter Map Button (on top)
                            Button(action: {
                                if let location = locationManager.location {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        currentCity = homeCity
                                        region.center = adjustedCenter(location.coordinate)
                                    }
                                    updateCityFromLocation(location)
                                } else {
                                    locationManager.requestLocationPermission()
                                    locationManager.startUpdatingLocation()
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        .regularMaterial,
                                        in: Circle()
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            }
                            
                            // Add Group Button (below, white on blue)
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showCreateOptions.toggle()
                                }
                            }) {
                                Image(systemName: showCreateOptions ? "xmark" : "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Color.appAccent,
                                        in: Circle()
                                    )
                                    .shadow(color: Color.appAccent.opacity(0.4), radius: 12, y: 6)
                                    .rotationEffect(.degrees(showCreateOptions ? 45 : 0))
                            }
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
                                        region.center = adjustedCenter(location.coordinate)
                                    }
                                    updateCityFromLocation(location)
                                } else {
                                    locationManager.requestLocationPermission()
                                    locationManager.startUpdatingLocation()
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(width: 56, height: 56)
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
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
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
                                        region.center = adjustedCenter(location.coordinate)
                                    } else {
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
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                .regularMaterial,
                                in: Capsule()
                            )
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
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
                            region.center = adjustedCenter(city.coordinate)
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
            .fullScreenCover(isPresented: $showProfileEditor) {
                ProfileEditorView {
                    showProfileEditor = false
                }
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
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showCitySearch = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(getCityName(from: currentCity))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            HStack(spacing: 8) {
                // Profile button
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
                    .frame(width: 44, height: 44) // HIG minimum touch target
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
            }
        }
    }
    
    private var travelersHeader: some View {
        VStack(spacing: 12) {
            // Enhanced Search Bar
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showCitySearch = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(getCityName(from: currentCity))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            
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
                    .font(.system(size: 16))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
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
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
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
        guard variant == .travelers else { return coordinate }
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
            Text("Nearby Places")
                .font(.system(size: 24, weight: .bold))
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        avatarStack(avatars: group.avatars)
                        
                        Text("\(group.attendees) Travelers")
                            .font(.system(size: 12, weight: .medium))
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
                    .font(.system(size: 22, weight: .bold))
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
                    .frame(width: 130, height: 170)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 80)
                .offset(y: 45)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.flag)
                        .font(.system(size: 18))
                        .offset(y: -145)
                        .padding(.leading, 10)
                        .padding(.top, 10)
                    
                    HStack(spacing: 6) {
                        Text(user.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    .offset(y: -10)
                    
                    Text(user.distance)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: -10)
                }
                .padding(.leading, 12)
                .padding(.bottom, 12)
            }
            .frame(width: 130, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        switch variant {
        case .groups:
            return data.groups.map { AnnotationItem(id: $0.id, coordinate: $0.coordinate, type: .group($0)) }
        case .travelers:
            return data.users.map { AnnotationItem(id: $0.id, coordinate: $0.coordinate, type: .user($0)) }
        }
    }
    
    private func annotationView(for item: AnnotationItem) -> some View {
        switch item.type {
        case .group(let group):
            return AnyView(groupAnnotation(group: group))
        case .user(let user):
            return AnyView(userAnnotation(user: user))
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
                .font(.system(size: 10, weight: .bold))
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
        let id: Int
        let coordinate: CLLocationCoordinate2D
        let type: AnnotationType
        
        enum AnnotationType {
            case group(Explore)
            case user(User)
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text("\(group.attendees) Travelers")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    Button(action: {
                        selectedJoinItem = nil
                        onJoinGroupChat(group)
                    }) {
                        Text("Save Place")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)

                    Button(action: { selectedJoinItem = nil }) {
                        Text("Close")
                            .font(.system(size: 15, weight: .semibold))
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
                    .font(.system(size: 20, weight: .semibold))
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Circle()
                            .fill(user.online ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                    Text(user.flag)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                Text(user.distance)
                    .font(.system(size: 13, weight: .medium))
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
}
