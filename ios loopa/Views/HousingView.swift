//
//  HousingView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import MapKit

enum HousingTab: String, CaseIterable {
    case spots = "Find a Spot"
    case roommates = "Roommates"
    case swaps = "Home Swaps"
}

struct HousingView: View {
    @State private var activeTab: HousingTab = .spots
    @State private var showMapView = false
    @State private var selectedMapFilter: String? = nil
    @State private var showSearchFlow = false
    @State private var showCreateSheet = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var housingSpots: [HousingSpot] = AppData.shared.housingSpots
    @State private var roommates: [Roommate] = AppData.shared.roommates
    @State private var swaps: [HomeSwap] = AppData.shared.swaps
    private let data = AppData.shared
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                housingHeroSection
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 1)
                    .background(Color.black.opacity(0.08))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                
                // Enhanced Content with smooth transitions
                ZStack(alignment: .top) {
                    if showMapView {
                        housingMapContent
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    } else {
                        Color(white: 0.97)
                            .ignoresSafeArea()
                        
                        LinearGradient(
                            colors: [Color.black.opacity(0.08), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 10)
                        
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                switch activeTab {
                                case .spots:
                                ForEach(housingSpots) { spot in
                                        housingSpotCard(spot: spot)
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                case .roommates:
                                ForEach(roommates) { roommate in
                                        roommateCard(roommate: roommate)
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                case .swaps:
                                ForEach(swaps) { swap in
                                        swapCard(swap: swap)
                                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 100)
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: showMapView)
            }
            
            Button(action: {
                showCreateSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.appAccent, in: Circle())
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 70)
        }
        .background(Color(.systemGroupedBackground))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeTab)
        .sheet(isPresented: $showSearchFlow) {
            HousingSearchFlowView(activeTab: $activeTab) {
                showSearchFlow = false
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateHousingListingView(activeTab: $activeTab, coordinate: mapRegion.center) { spot in
                housingSpots.insert(spot, at: 0)
            } onCreateRoommate: { roommate in
                roommates.insert(roommate, at: 0)
            } onCreateSwap: { swap in
                swaps.insert(swap, at: 0)
            } onClose: {
                showCreateSheet = false
            }
        }
    }

    private var housingHeroSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: {
                    showSearchFlow = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Start my search")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.white, in: Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 16, y: 10)
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showMapView.toggle()
                    }
                }) {
                    Image(systemName: showMapView ? "list.bullet" : "map.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 48, height: 48)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .bottom, spacing: 40) {
                ForEach(HousingTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            activeTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                tabIconView(for: tab)
                                    .frame(width: 70, height: 70)
                                    .clipped()
                            }

                            Text(tabLabel(for: tab))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)

                            Spacer(minLength: 6)
                        }
                        .frame(height: 94)
                        .overlay(alignment: .bottom) {
                            Capsule()
                                .fill(activeTab == tab ? Color.appAccent : Color.clear)
                                .frame(width: 52, height: 3)
                                .offset(y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 0)
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
    }

    private func tabIcon(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "house.fill"
        case .roommates:
            return "person.2.fill"
        case .swaps:
            return "arrow.triangle.2.circlepath"
        }
    }

    private func tabLabel(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "Housing"
        case .roommates:
            return "Roommates"
        case .swaps:
            return "Swaps"
        }
    }

    @ViewBuilder
    private func tabIconView(for tab: HousingTab) -> some View {
        if tab == .spots {
            Image("Untitled design (14)")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.15)
        } else if tab == .roommates {
            Image("b (1)")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.1)
        } else {
            Image(systemName: tabIcon(for: tab))
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(activeTab == tab ? Color.appAccent : .primary)
        }
    }

    private var housingMapContent: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $mapRegion, annotationItems: mapItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.appAccent, in: Circle())
                        Text(item.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white, in: Capsule())
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: {}) {
                        mapFilterChip(icon: "slider.horizontal.3", text: "Filter", isSelected: false)
                    }
                    .buttonStyle(.plain)

                    ForEach(mapFilters, id: \.self) { filter in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMapFilter = selectedMapFilter == filter ? nil : filter
                            }
                        }) {
                            mapFilterChip(text: filter, isSelected: selectedMapFilter == filter)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
    }

    private var mapFilters: [String] {
        switch activeTab {
        case .spots:
            return ["Studio", "Private room", "Entire place"]
        case .roommates:
            return ["Pet friendly", "Quiet", "Social"]
        case .swaps:
            return ["Short stay", "Long stay", "Verified"]
        }
    }

    private func mapFilterChip(icon: String? = nil, text: String, isSelected: Bool = false) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isSelected ? AnyShapeStyle(Color.appAccent) : AnyShapeStyle(.regularMaterial),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .strokeBorder(isSelected ? Color.clear : Color(.systemGray5).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private struct MapItem: Identifiable {
        let id: String
        let title: String
        let coordinate: CLLocationCoordinate2D
        let icon: String
    }

    private var mapItems: [MapItem] {
        switch activeTab {
        case .spots:
            return housingSpots.map {
                MapItem(
                    id: "spot-\($0.id)",
                    title: $0.title,
                    coordinate: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng),
                    icon: "house.fill"
                )
            }
        case .roommates:
            return roommates.map {
                MapItem(
                    id: "roommate-\($0.id)",
                    title: $0.name,
                    coordinate: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng),
                    icon: "person.fill"
                )
            }
        case .swaps:
            return swaps.map {
                MapItem(
                    id: "swap-\($0.id)",
                    title: $0.title,
                    coordinate: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng),
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
    }

private struct HousingSearchFlowView: View {
    @Binding var activeTab: HousingTab
    let onClose: () -> Void

    @State private var stepIndex = 0
    @State private var locationText = ""
    @State private var selectedCity: String? = nil
    @State private var selectedWhat: Set<String> = []
    @State private var selectedBudget: Set<String> = []
    @State private var selectedRoommatesRange: Set<String> = []
    @State private var selectedRoommatesGender: Set<String> = []

    private let popularCities = [
        "Montreal, Canada",
        "Paris, France",
        "New York, USA",
        "London, UK",
        "Tokyo, Japan",
        "Lisbon, Portugal"
    ]

    private let housingTypes = ["Apartment", "House", "Student residence", "Room"]
    private let roommatesRanges = ["1 roommate", "2-3 roommates", "4+ roommates"]
    private let roommatesGenders = ["Any", "Women only", "Men only", "Mixed"]
    private let budgetRanges = ["$0-500", "$500-1000", "$1000-1500", "$1500+"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    whereStep
                        .opacity(stepIndex == 0 ? 1 : 0)
                        .frame(maxHeight: stepIndex == 0 ? .infinity : 0)
                    whatStep
                        .opacity(stepIndex == 1 ? 1 : 0)
                        .frame(maxHeight: stepIndex == 1 ? .infinity : 0)
                    budgetStep
                        .opacity(stepIndex == 2 ? 1 : 0)
                        .frame(maxHeight: stepIndex == 2 ? .infinity : 0)
                    actionBar
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .bottom, spacing: 40) {
                ForEach(HousingTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            activeTab = tab
                            resetSelectionsForTab()
                        }
                    }) {
                        VStack(spacing: 6) {
                            HousingSearchTabIcon(tab: tab)
                                .frame(width: 60, height: 60)
                            Text(tabLabel(for: tab))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                            Capsule()
                                .fill(activeTab == tab ? Color.appAccent : Color.clear)
                                .frame(width: 46, height: 3)
                        }
                        .frame(height: 86)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Button(action: { advanceToStep(0) }) {
                    stepChip(title: "Where", isActive: stepIndex == 0)
                }
                .buttonStyle(.plain)
                Button(action: { advanceToStep(1) }) {
                    stepChip(title: "What", isActive: stepIndex == 1)
                }
                .buttonStyle(.plain)
                Button(action: { advanceToStep(2) }) {
                    stepChip(title: "Budget", isActive: stepIndex == 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var whereStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("Search a city", text: $locationText)
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        if !locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            advanceToStep(1)
                        }
                    }
                if !locationText.isEmpty {
                    Button(action: { locationText = "" }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Color(.systemGray6), in: Circle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

            Text("Popular destinations")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(popularCities, id: \.self) { city in
                    Button(action: {
                        selectedCity = city
                        locationText = city
                        advanceToStep(1)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(city)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Popular option")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selectedCity == city ? Color.appAccent : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var whatStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            if activeTab == .roommates {
                Text("How many roommates?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                chipGrid(options: roommatesRanges, selection: $selectedRoommatesRange, allowsMultiple: true)

                Text("Roommate preference")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                chipGrid(options: roommatesGenders, selection: $selectedRoommatesGender, allowsMultiple: true)
            } else {
                Text("Type of place")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                chipGrid(options: housingTypes, selection: $selectedWhat, allowsMultiple: true)
            }
        }
    }

    private var budgetStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Budget")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            chipGrid(options: budgetRanges, selection: $selectedBudget, allowsMultiple: true)
        }
    }

    private var actionBar: some View {
        HStack {
            Button(action: resetAll) {
                Text("Clear all")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {
                if stepIndex < 2 {
                    advanceToStep(stepIndex + 1)
                } else if canSearch {
                    onClose()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                    Text(stepIndex < 2 ? "Next" : "Search")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(stepIndex < 2 || canSearch ? .white : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    stepIndex < 2 || canSearch ? Color.appAccent : Color(.systemGray5),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(stepIndex == 2 && !canSearch)
        }
        .padding(.top, 4)
    }

    private var canSearch: Bool {
        isStepComplete(0) && isStepComplete(1) && isStepComplete(2)
    }

    private func stepChip(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isActive ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.white : Color(.systemGray6), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? Color.black.opacity(0.08) : Color.clear, lineWidth: 1)
            )
    }

    private func chipGrid(options: [String], selection: Binding<Set<String>>, allowsMultiple: Bool) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selection.wrappedValue.contains(option) {
                        selection.wrappedValue.remove(option)
                    } else {
                        if allowsMultiple {
                            selection.wrappedValue.insert(option)
                        } else {
                            selection.wrappedValue = [option]
                        }
                    }
                }) {
                    Text(option)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection.wrappedValue.contains(option) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selection.wrappedValue.contains(option) ? Color.appAccent : Color.white,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func advanceToStep(_ step: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            stepIndex = min(max(step, 0), 2)
        }
    }

    private func isStepComplete(_ index: Int) -> Bool {
        switch index {
        case 0:
            return selectedCity != nil || !locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1:
            if activeTab == .roommates {
                return !selectedRoommatesRange.isEmpty && !selectedRoommatesGender.isEmpty
            }
            return !selectedWhat.isEmpty
        case 2:
            return !selectedBudget.isEmpty
        default:
            return false
        }
    }

    private func resetSelectionsForTab() {
        selectedWhat.removeAll()
        selectedRoommatesRange.removeAll()
        selectedRoommatesGender.removeAll()
    }

    private func resetAll() {
        locationText = ""
        selectedCity = nil
        selectedWhat.removeAll()
        selectedBudget.removeAll()
        selectedRoommatesRange.removeAll()
        selectedRoommatesGender.removeAll()
    }

    private func tabLabel(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "Housing"
        case .roommates:
            return "Roommates"
        case .swaps:
            return "Swaps"
        }
    }
}

private struct HousingSearchTabIcon: View {
    let tab: HousingTab

    var body: some View {
        switch tab {
        case .spots:
            Image("Untitled design (14)")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.1)
        case .roommates:
            Image("b (1)")
                .resizable()
                .scaledToFill()
                .scaleEffect(1.1)
        case .swaps:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

private struct CreateHousingListingView: View {
    @Binding var activeTab: HousingTab
    let coordinate: CLLocationCoordinate2D
    let onCreateSpot: (HousingSpot) -> Void
    let onCreateRoommate: (Roommate) -> Void
    let onCreateSwap: (HomeSwap) -> Void
    let onClose: () -> Void

    @State private var selectedTab: HousingTab

    @State private var housingTitle = ""
    @State private var housingDescription = ""
    @State private var housingPrice = ""
    @State private var housingPeriod = "mo"
    @State private var housingType = "Apartment"
    @State private var housingPhotoUrls = ""
    @State private var housingBadgesSelected: Set<String> = []
    @State private var housingBadgesCustom = ""

    @State private var roommateName = ""
    @State private var roommateAge = ""
    @State private var roommateBudget = ""
    @State private var roommateLocation = ""
    @State private var roommateMoveIn = ""
    @State private var roommateTags = ""

    @State private var swapTitle = ""
    @State private var swapTarget = ""
    @State private var swapDates = ""
    @State private var swapHomeType = "Entire home"

    init(
        activeTab: Binding<HousingTab>,
        coordinate: CLLocationCoordinate2D,
        onCreateSpot: @escaping (HousingSpot) -> Void,
        onCreateRoommate: @escaping (Roommate) -> Void,
        onCreateSwap: @escaping (HomeSwap) -> Void,
        onClose: @escaping () -> Void
    ) {
        _activeTab = activeTab
        _selectedTab = State(initialValue: activeTab.wrappedValue)
        self.coordinate = coordinate
        self.onCreateSpot = onCreateSpot
        self.onCreateRoommate = onCreateRoommate
        self.onCreateSwap = onCreateSwap
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    tabSelector
                    formContent
                    actionBar
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack {
            Text("Create")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var tabSelector: some View {
        HStack(alignment: .bottom, spacing: 32) {
            ForEach(HousingTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                        activeTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        HousingSearchTabIcon(tab: tab)
                            .frame(width: 60, height: 60)
                        Text(tabLabel(for: tab))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        Capsule()
                            .fill(selectedTab == tab ? Color.appAccent : Color.clear)
                            .frame(width: 44, height: 3)
                    }
                    .frame(height: 86)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        switch selectedTab {
        case .spots:
            housingForm
        case .roommates:
            roommatesForm
        case .swaps:
            swapsForm
        }
    }

    private var housingForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Housing listing")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            formTextField("Title", text: $housingTitle)
            formTextField("Price", text: $housingPrice, keyboard: .numberPad)

            HStack(spacing: 12) {
                formPicker("Period", selection: $housingPeriod, options: ["mo", "week", "day"])
                formPicker("Type", selection: $housingType, options: ["Apartment", "House", "Student residence", "Room"])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $housingDescription)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                    if housingDescription.isEmpty {
                        Text("Describe the place, what's included, and what makes it special.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
            }

            formTextField("Photo URLs (comma separated)", text: $housingPhotoUrls)

            VStack(alignment: .leading, spacing: 8) {
                Text("Badges")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                badgeGrid(options: housingBadgeOptions, selection: $housingBadgesSelected)
                formTextField("Custom badges (comma separated)", text: $housingBadgesCustom)
            }
        }
    }

    private var roommatesForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Roommates listing")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            formTextField("Name", text: $roommateName)
            HStack(spacing: 12) {
                formTextField("Age", text: $roommateAge, keyboard: .numberPad)
                formTextField("Budget", text: $roommateBudget, keyboard: .numberPad)
            }
            formTextField("Location", text: $roommateLocation)
            formTextField("Move-in date", text: $roommateMoveIn)
            formTextField("Tags (comma separated)", text: $roommateTags)
        }
    }

    private var swapsForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Home swap listing")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            formTextField("Title", text: $swapTitle)
            formTextField("Target destination", text: $swapTarget)
            formTextField("Dates", text: $swapDates)
            formPicker("Home type", selection: $swapHomeType, options: ["Entire home", "Private room", "Studio"])
        }
    }

    private var actionBar: some View {
        Button(action: handleCreate) {
            Text("Publish")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canPublish ? Color.appAccent : Color(.systemGray5), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canPublish)
    }

    private var canPublish: Bool {
        switch selectedTab {
        case .spots:
            return !housingTitle.isEmpty && Int(housingPrice) != nil
        case .roommates:
            return !roommateName.isEmpty && Int(roommateAge) != nil && Int(roommateBudget) != nil && !roommateLocation.isEmpty
        case .swaps:
            return !swapTitle.isEmpty && !swapTarget.isEmpty && !swapDates.isEmpty
        }
    }

    private func handleCreate() {
        switch selectedTab {
        case .spots:
            let parsedPhotos = housingPhotoUrls
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let customBadges = housingBadgesCustom
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let allBadges = Array(housingBadgesSelected) + customBadges
            let photos = parsedPhotos.isEmpty
                ? ["https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80"]
                : parsedPhotos
            let spot = HousingSpot(
                id: Int(Date().timeIntervalSince1970),
                title: housingTitle,
                description: housingDescription.isEmpty ? "No description yet." : housingDescription,
                price: Int(housingPrice) ?? 0,
                currency: "$",
                period: housingPeriod,
                image: photos.first ?? "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80",
                photos: photos,
                badges: allBadges.isEmpty ? ["Furnished", "Near metro"] : allBadges,
                rating: 4.8,
                recommender: "You",
                recommenderImg: "https://i.pravatar.cc/150?u=you",
                lat: coordinate.latitude,
                lng: coordinate.longitude,
                type: housingType
            )
            onCreateSpot(spot)
        case .roommates:
            let tags = roommateTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            let roommate = Roommate(
                id: Int(Date().timeIntervalSince1970),
                name: roommateName,
                age: Int(roommateAge) ?? 0,
                budget: Int(roommateBudget) ?? 0,
                location: roommateLocation,
                image: "https://i.pravatar.cc/150?u=\(roommateName.lowercased())",
                tags: tags.isEmpty ? ["Friendly", "Clean", "Flexible"] : tags,
                lat: coordinate.latitude,
                lng: coordinate.longitude,
                moveIn: roommateMoveIn.isEmpty ? "ASAP" : roommateMoveIn
            )
            onCreateRoommate(roommate)
        case .swaps:
            let swap = HomeSwap(
                id: Int(Date().timeIntervalSince1970),
                title: swapTitle,
                target: swapTarget,
                dates: swapDates,
                image: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80",
                owner: "You",
                ownerImg: "https://i.pravatar.cc/150?u=you",
                lat: coordinate.latitude,
                lng: coordinate.longitude,
                homeType: swapHomeType
            )
            onCreateSwap(swap)
        }
        onClose()
    }

    private func tabLabel(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "Housing"
        case .roommates:
            return "Roommates"
        case .swaps:
            return "Swaps"
        }
    }

    private func formTextField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            )
    }

    private func formPicker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { selection.wrappedValue = option }
            }
        } label: {
            HStack(spacing: 6) {
                Text("\(title):")
                    .foregroundStyle(.secondary)
                Text(selection.wrappedValue)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var housingBadgeOptions: [String] {
        ["Furnished", "Near metro", "Utilities included", "Pet friendly", "Quiet", "Balcony"]
    }

    private func badgeGrid(options: [String], selection: Binding<Set<String>>) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selection.wrappedValue.contains(option) {
                        selection.wrappedValue.remove(option)
                    } else {
                        selection.wrappedValue.insert(option)
                    }
                }) {
                    Text(option)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selection.wrappedValue.contains(option) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection.wrappedValue.contains(option) ? Color.appAccent : Color.white,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

    
    private func housingSpotCard(spot: HousingSpot) -> some View {
        Button(action: {}) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    let heroImage = spot.photos.first ?? spot.image
                    AsyncImage(url: URL(string: heroImage)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            Color(.systemGray5)
                        } else {
                            ProgressView()
                                .tint(.secondary)
                        }
                    }
                    .frame(height: 180)
                    .clipped()
                    
                    // Enhanced Rating Badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", spot.rating))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .padding(16)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text(spot.title)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(spot.currency)\(spot.price)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.appAccent)
                            Text("/\(spot.period)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(spot.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !spot.badges.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(spot.badges.prefix(3), id: \.self) { badge in
                                Text(badge)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray6), in: Capsule())
                            }
                        }
                    }
                    
                    // Enhanced Recommender Section
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: spot.recommenderImg)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.quaternary, lineWidth: 1))
                        
                        Text("Recommended by **\(spot.recommender)**")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func roommateCard(roommate: Roommate) -> some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: roommate.image)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.secondary)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ProgressView()
                            .tint(.secondary)
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(roommate.name), \(roommate.age)")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("\(roommate.location) • $\(roommate.budget)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    // Enhanced Tags
                    HStack(spacing: 6) {
                        ForEach(roommate.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    .ultraThinMaterial,
                                    in: Capsule()
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func swapCard(swap: HomeSwap) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: swap.image)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 160)
                .clipped()
                
                Text(swap.homeType)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(swap.title)
                    .font(.system(size: 18, weight: .bold))
                
                HStack {
                    Text(swap.dates)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("Owner: \(swap.owner)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        
                        AsyncImage(url: URL(string: swap.ownerImg)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}
