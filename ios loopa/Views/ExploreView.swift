//
//  ExploreView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import MapKit
import MapboxMaps
import PhotosUI
import Combine

// Style Mapbox partagé : MapboxMapStyle.appStyle (voir MapboxMapStyle.swift)

enum HousingTab: String, CaseIterable {
    case spots = "Housing"
    case roommates = "Roommates"
}

struct ExploreView: View {
    @Binding var hideTabBar: Bool
    var onMessageRoommate: ((Roommate) -> Void)? = nil

    init(hideTabBar: Binding<Bool> = .constant(false), onMessageRoommate: ((Roommate) -> Void)? = nil) {
        _hideTabBar = hideTabBar
        self.onMessageRoommate = onMessageRoommate
    }

    @State private var activeTab: HousingTab = .spots
    @State private var showMapView = false
    @State private var selectedMapFilter: String? = nil
    @State private var showSearchFlow = false
    @State private var showCreateSheet = false
    @State private var showCreateTripSheet = false
    @State private var showTripsList = false
    @State private var selectedTripForHousing: Trip?
    @State private var selectedHousingSpot: HousingSpot? = nil
    @State private var selectedRoommate: Roommate? = nil
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var housingSpots: [HousingSpot] = AppData.shared.housingSpots
    @State private var roommates: [Roommate] = AppData.shared.roommates
    @State private var selectedPOI: TappedPOI? = nil
    @State private var trips: [Trip] = [
        Trip(
            destination: "Bali",
            startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 17)) ?? Date(),
            endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 23)) ?? Date(),
            imageUrl: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80"
        )
    ]
    private let data = AppData.shared
    
    var body: some View {
        ExploreTripsMapView(
            cities: data.citiesWithRecommendations,
            spots: housingSpots,
            avatarImages: data.users.map(\.image),
            hideTabBar: $hideTabBar,
            onClose: {},
            showBackButton: false
        )
    }

    private var myTripHeader: some View {
        HStack {
            Text("My trips")
                .font(.app(size: 26, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()
            
            Button(action: {
                showCreateTripSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.appAccent, in: Circle())
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
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
                            .font(.app(size: 15, weight: .semibold))
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
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color(hex: "222222"), in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .bottom, spacing: 80) {
                ForEach(HousingTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            activeTab = tab
                        }
                    }) {
                        HousingTabLabel(
                            text: tabLabel(for: tab),
                            isActive: activeTab == tab
                        )
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

    private var upcomingTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Upcoming Trips", actionText: "See All") {
                showTripsList = true
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trips) { trip in
                        tripCard(trip: trip)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.bottom, 24)
    }

    private var recommendedHousingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recommended Housing", actionText: "See All") {
                if let nextTrip {
                    selectedTripForHousing = nextTrip
                }
            }

            VStack(spacing: 12) {
                ForEach(housingSpots.prefix(3)) { spot in
                    recommendedHousingRow(spot: spot)
                }
            }

            Button(action: {
                showCreateSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add new recommendation")
                        .font(.app(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.5), lineWidth: 1.2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 8)
    }

    private var findRoommatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Find Roommates", actionText: "See All") {}

            VStack(spacing: 12) {
                ForEach(roommates.prefix(4)) { roommate in
                    roommateListRow(roommate: roommate)
                }
            }
        }
    }

    private func sectionHeader(title: String, actionText: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            Button(action: action) {
                Text(actionText)
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .buttonStyle(.plain)
        }
    }

    private func tripCard(trip: Trip) -> some View {
        let countdown = daysUntil(trip.startDate)
        let avatarImages = data.users.map(\.image).prefix(5)
        let dateLabel = "\(shortDate(trip.startDate)) - \(shortDate(trip.endDate))"
        let statusText = tripStatusText(start: trip.startDate, end: trip.endDate)

        return VStack(spacing: 0) {
                            ZStack {
                AsyncImage(url: URL(string: trip.imageUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.white
                    }
                }
                .frame(width: 300, height: 190)
                                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.35), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 100)
                .frame(maxWidth: .infinity, alignment: .bottom)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("🌍 \(trip.destination)")
                            .font(.app(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    Spacer()
                        Text(dateLabel.uppercased())
                            .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                }
                
                    Spacer()

                    HStack(spacing: 8) {
                        avatarStack(images: Array(avatarImages))
                        if statusText == nil {
                            Text("+\(countdown) days")
                                .font(.app(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.18), in: Capsule())
                        }
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
            )

            if let statusText {
                Text(statusText)
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .overlay(
                            Capsule()
                            .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                    .padding(.top, -12)
                    .frame(maxWidth: 300, alignment: .center)
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func recommendedHousingRow(spot: HousingSpot) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: spot.image)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.title)
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(spot.type)
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: -6) {
                avatarStack(images: Array(data.users.prefix(3).map(\.image)))
                Text("\(max(20, Int(spot.rating * 50)))+")
                    .font(.app(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6), in: Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            selectedHousingSpot = spot
            selectedRoommate = nil
        }
    }

    private func roommateListRow(roommate: Roommate) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: roommate.image)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                            } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(roommate.name), \(roommate.age)")
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Move in \(roommate.moveIn)")
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                onMessageRoommate?(roommate)
            }) {
                Text("Say hello 👋")
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                                .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.appAccent.opacity(0.6), lineWidth: 1.2)
                    )
                    }
                    .buttonStyle(.plain)
                }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedRoommate = roommate
            selectedHousingSpot = nil
        }
    }

    private func avatarStack(images: [String]) -> some View {
        HStack(spacing: -8) {
            ForEach(Array(images.prefix(4).enumerated()), id: \.offset) { _, imageUrl in
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(width: 26, height: 26)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }

    private var nextTrip: Trip? {
        trips.sorted { $0.startDate < $1.startDate }.first
    }

    private func daysUntil(_ date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(days, 0)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func tripStatusText(start: Date, end: Date) -> String? {
        let now = Date()
        if now >= start && now <= end {
            return "Happening now"
        }
        return nil
    }

    private struct Trip: Identifiable {
        let id = UUID()
        let destination: String
        let startDate: Date
        let endDate: Date
        let imageUrl: String
    }

    private struct CreateTripView: View {
        let onCreate: (Trip) -> Void
        let onClose: () -> Void

        @State private var searchText = ""
        @State private var selectedDestination: String? = nil
        @State private var startDate = Date()
        @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        @StateObject private var locationSearcher = TripLocationSearcher()
        @FocusState private var isSearchFocused: Bool

        var body: some View {
            NavigationStack {
                VStack(spacing: 16) {
                    HStack {
                        Text("✈️ New trip")
                            .font(.app(size: 24, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 34, height: 34)
                                .background(Color(.systemGray6), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Destination")
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        if let selected = selectedDestination {
                            // Selected destination display
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.appAccent)
                                Text(selected)
                                    .font(.app(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button(action: {
                                    selectedDestination = nil
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            // Search field
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                TextField("Search city or country", text: $searchText)
                                    .focused($isSearchFocused)
                                    .onChange(of: searchText) { _, newValue in
                                        locationSearcher.search(query: newValue)
                                    }
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        // Search results
                        if selectedDestination == nil && !locationSearcher.results.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(locationSearcher.results, id: \.self) { result in
                                        Button(action: {
                                            let title = result.title
                                            let subtitle = result.subtitle
                                            selectedDestination = subtitle.isEmpty ? title : "\(title), \(subtitle)"
                                            searchText = ""
                                            isSearchFocused = false
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(Color.appAccent)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title)
                                                        .font(.app(size: 15, weight: .medium))
                                                        .foregroundStyle(.primary)
                                                    if !result.subtitle.isEmpty {
                                                        Text(result.subtitle)
                                                            .font(.app(size: 13))
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if result != locationSearcher.results.last {
                                            Divider()
                                                .padding(.leading, 46)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dates")
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }

                    Button(action: createTrip) {
                        Text("Add trip")
                            .font(.app(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canCreate ? Color.appAccent : Color(.systemGray4), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreate)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(.systemBackground))
        }

        private var canCreate: Bool {
            selectedDestination != nil
        }

        private func createTrip() {
            guard let destination = selectedDestination else { return }
            let newTrip = Trip(
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                imageUrl: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80"
            )
            onCreate(newTrip)
        }
    }


    private struct UpcomingTripsListView: View {
        @Binding var trips: [Trip]
        let onClose: () -> Void

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(trips) { trip in
                            UpcomingTripRow(trip: trip) {
                                trips.removeAll { $0.id == trip.id }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("My Trips")
                            .font(.app(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onClose) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color(.systemGray6), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
        }
    }

    private struct UpcomingTripRow: View {
        let trip: Trip
        let onDelete: () -> Void
        @State private var showDeletePopover = false
        private var dateLabel: String {
            "\(shortDate(trip.startDate)) - \(shortDate(trip.endDate))"
        }
        private var destinationTitle: String {
            trip.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        private var destinationSubtitle: String {
            let components = trip.destination.split(separator: ",")
            if components.count >= 2 {
                return components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Destination"
            }
            return "Destination"
        }

        var body: some View {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: trip.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                } else {
                            Color(.systemGray5)
                        }
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    LinearGradient(
                        colors: [.black.opacity(0.4), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 90)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(destinationTitle)
                            .font(.app(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Text(destinationSubtitle)
                            .font(.app(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(14)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(dateLabel)
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4), in: Capsule())
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                Button(action: { showDeletePopover = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.45), in: Circle())
                }
                .popover(isPresented: $showDeletePopover, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(role: .destructive, action: {
                            showDeletePopover = false
                            onDelete()
                        }) {
                            Label("Delete trip", systemImage: "trash")
                                .font(.app(size: 14, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .presentationCompactAdaptation(.popover)
                }
                .padding(.trailing, 12)
                .padding(.top, 12)
            }
            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        }

        private func shortDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    /// Vue globe terrestre pour la map Trips. Pastilles rouges = villes. Petits pins jaunes avec emoji = spots par catégorie (🍹🍕🍵🎡🏠).
    private struct TripsGlobeView: UIViewRepresentable {
        static let styleURL = "mapbox://styles/thochw/cmkbqgty5004901rxgct4a0z6"
        var targetCoordinate: CLLocationCoordinate2D?
        var targetZoom: Double
        var cities: [CityWithRecommendations]
        var spots: [HousingSpot] = []
        var cameraBottomPadding: CGFloat = 0
        var onCityTap: ((CityWithRecommendations) -> Void)?
        var onSpotTap: ((HousingSpot) -> Void)?

        private static let fullGlobeCenter = CLLocationCoordinate2D(latitude: 20, longitude: -50)
        private static let fullGlobeZoom: Double = 0.5

        /// Catégories, emojis et couleurs pour les pins
        private static let categoryEmojis: [String: String] = [
            "bars": "🍹",
            "restaurants": "🍕",
            "cafes": "🍵",
            "activities": "🎡",
            "housing": "🏠",
        ]

        /// Couleurs des pins = fond pastel des pills (meta.tint.opacity(0.18) sur blanc)
        private static let categoryColors: [String: UIColor] = [
            "bars":        UIColor(red: 254/255.0, green: 234/255.0, blue: 216/255.0, alpha: 1), // #feead8
            "restaurants": UIColor(red: 1, green: 217/255.0, blue: 224/255.0, alpha: 1),         // #ffd9e0
            "cafes":       UIColor(red: 218/255.0, green: 245/255.0, blue: 225/255.0, alpha: 1), // #daf5e1
            "activities":  UIColor(red: 247/255.0, green: 218/255.0, blue: 249/255.0, alpha: 1), // #f7daf9
            "housing":     UIColor(red: 0.88, green: 0.92, blue: 1.00, alpha: 1),               // pastel blue (Housing)
        ]

        private static func spotCategoryId(for type: String) -> String {
            let raw = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if raw.contains("restaurant") { return "restaurants" }
            if raw.contains("cafe") { return "cafes" }
            if raw.contains("bar") { return "bars" }
            if raw.contains("activity") { return "activities" }
            return "housing"
        }

        /// Pin goutte d'eau (cercle complet + pointe en bas) avec emoji et couleur
        static func categoryPinImage(emoji: String, color: UIColor, height: CGFloat = 48) -> UIImage {
            let circleDiameter: CGFloat = height * 0.70
            let tipHeight: CGFloat = height * 0.30
            let padding: CGFloat = 4                       // espace pour l'ombre
            let borderWidth: CGFloat = 3.0
            let totalW = circleDiameter + padding * 2
            let totalH = circleDiameter + tipHeight + padding * 2
            let centerX = totalW / 2
            let circleCenter = CGPoint(x: centerX, y: padding + circleDiameter / 2)
            let radius = circleDiameter / 2

            // Angle où le cercle rejoint la pointe (~140° et ~40°)
            let tipAngle: CGFloat = .pi * 0.38             // ouverture de la pointe
            let leftAngle: CGFloat = .pi / 2 + tipAngle    // ~130°
            let rightAngle: CGFloat = .pi / 2 - tipAngle   // ~50°
            let tipPoint = CGPoint(x: centerX, y: padding + circleDiameter + tipHeight - 2)

            func makeDropPath(r: CGFloat, center: CGPoint, tip: CGPoint) -> UIBezierPath {
                let path = UIBezierPath()
                // Arc : du côté droit en bas, autour du haut, jusqu'au côté gauche en bas
                path.addArc(withCenter: center, radius: r, startAngle: rightAngle, endAngle: leftAngle, clockwise: false)
                // Lignes vers la pointe
                path.addLine(to: tip)
                path.close()
                return path
            }

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalW, height: totalH))
            return renderer.image { ctx in
                let gc = ctx.cgContext

                // Ombre
                gc.saveGState()
                gc.setShadow(offset: CGSize(width: 0, height: 2), blur: 5, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                let outerPath = makeDropPath(r: radius, center: circleCenter, tip: tipPoint)
                UIColor.white.setFill()
                outerPath.fill()
                gc.restoreGState()

                // Intérieur couleur
                let innerRadius = radius - borderWidth
                let innerTip = CGPoint(x: centerX, y: tipPoint.y - borderWidth * 1.5)
                let innerPath = makeDropPath(r: innerRadius, center: circleCenter, tip: innerTip)
                color.setFill()
                innerPath.fill()

                // Emoji centré dans le cercle
                let fontSize: CGFloat = circleDiameter * 0.42
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize),
                ]
                let str = emoji as NSString
                let textSize = str.size(withAttributes: attrs)
                let textRect = CGRect(
                    x: circleCenter.x - textSize.width / 2,
                    y: circleCenter.y - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                str.draw(in: textRect, withAttributes: attrs)
            }
        }

        static func redPillImage(size: CGFloat = 18) -> UIImage {
            let whiteRingWidth: CGFloat = 4
            let totalSize = size + whiteRingWidth * 2
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalSize, height: totalSize))
            return renderer.image { ctx in
                let rect = CGRect(origin: .zero, size: CGSize(width: totalSize, height: totalSize))
                let innerRect = CGRect(x: whiteRingWidth, y: whiteRingWidth, width: size, height: size)
                UIColor.white.setFill()
                ctx.cgContext.fillEllipse(in: rect)
                UIColor(red: 1, green: 0.23, blue: 0.36, alpha: 1).setFill()
                ctx.cgContext.fillEllipse(in: innerRect)
            }
        }

        func makeUIView(context: Context) -> MapboxMaps.MapView {
            let styleURI = MapboxMaps.StyleURI(rawValue: Self.styleURL) ?? .standard
            let options = MapboxMaps.MapInitOptions(styleURI: styleURI)
            let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: options)
            mapView.mapboxMap.setCamera(to: MapboxMaps.CameraOptions(
                center: Self.fullGlobeCenter,
                padding: UIEdgeInsets(top: 0, left: 0, bottom: cameraBottomPadding, right: 0),
                zoom: Self.fullGlobeZoom,
                bearing: 0,
                pitch: 0
            ))
            try? mapView.mapboxMap.setProjection(MapboxMaps.StyleProjection(name: .globe))
            mapView.ornaments.options.scaleBar.visibility = .hidden
            mapView.mapboxMap.onStyleLoaded.observeNext { _ in
                var atmosphere = MapboxMaps.Atmosphere()
                atmosphere.horizonBlend = .constant(0.05) // halo lumineux très léger autour de la planète
                atmosphere.spaceColor = .constant(MapboxMaps.StyleColor(UIColor(red: 8/255.0, green: 15/255.0, blue: 42/255.0, alpha: 1))) // bleu nuit intense
                atmosphere.starIntensity = .constant(0.7) // espace plus vivant
                try? mapView.mapboxMap.setAtmosphere(atmosphere)
                context.coordinator.addPOILayerIfNeeded(mapView: mapView)
                context.coordinator.setupAnnotationManagerIfNeeded(mapView: mapView)
            }.store(in: &context.coordinator.cancelables)
            return mapView
        }

        func updateUIView(_ uiView: MapboxMaps.MapView, context: Context) {
            context.coordinator.setupAnnotationManagerIfNeeded(mapView: uiView)
            context.coordinator.onCityTap = onCityTap
            context.coordinator.onSpotTap = onSpotTap
            context.coordinator.updateCityAnnotations(cities: cities)
            context.coordinator.updateSpotAnnotations(spots: spots)

            let coordinate: CLLocationCoordinate2D
            let zoom: Double
            if let target = targetCoordinate {
                coordinate = target
                zoom = targetZoom
            } else {
                coordinate = Self.fullGlobeCenter
                zoom = Self.fullGlobeZoom
            }

            let last = context.coordinator.lastTarget
            let sameTarget = last?.latitude == coordinate.latitude && last?.longitude == coordinate.longitude
            let sameZoom = context.coordinator.lastZoom == zoom
            guard !(sameTarget && sameZoom) else { return }
            context.coordinator.lastTarget = coordinate
            context.coordinator.lastZoom = zoom
            let target = MapboxMaps.CameraOptions(
                center: coordinate,
                padding: UIEdgeInsets(top: 0, left: 0, bottom: cameraBottomPadding, right: 0),
                zoom: zoom,
                bearing: 0,
                pitch: 0
            )
            uiView.camera.ease(to: target, duration: 1.6, curve: .easeInOut, completion: nil)
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        final class Coordinator {
            var cancelables = Set<AnyCancelable>()
            var lastTarget: CLLocationCoordinate2D? = nil
            var lastZoom: Double? = nil
            var lastCities: [CityWithRecommendations] = []
            var lastSpots: [HousingSpot] = []
            var onCityTap: ((CityWithRecommendations) -> Void)?
            var onSpotTap: ((HousingSpot) -> Void)?
            private weak var mapView: MapboxMaps.MapView?
            private var cityAnnotationManager: MapboxMaps.PointAnnotationManager?
            private var spotAnnotationManager: MapboxMaps.PointAnnotationManager?
            private static let cityImageName = "loopa_red_pill"
            private static let spotImagePrefix = "loopa_spot_pin_"
            private var didAddCityImage = false
            private var didAddSpotImages = false
            private var didAddPOILayer = false

            func addPOILayerIfNeeded(mapView: MapboxMaps.MapView) {
                guard !didAddPOILayer else { return }
                var layer = MapboxMaps.SymbolLayer(id: "app-poi-globe", source: "composite")
                layer.sourceLayer = "poi_label"
                layer.filter = Exp(.match) {
                    Exp(.get) { "class" }
                    "commercial"; true
                    "recreation"; true
                    "landmark"; true
                    false
                }
                layer.textField = .expression(Exp(.get) { "name" })
                layer.textSize = .constant(12)
                layer.textColor = .constant(MapboxMaps.StyleColor(.darkGray))
                try? mapView.mapboxMap.addLayer(layer)
                didAddPOILayer = true
            }

            func setupAnnotationManagerIfNeeded(mapView: MapboxMaps.MapView) {
                self.mapView = mapView
                guard cityAnnotationManager == nil else { return }
                if !didAddCityImage {
                    let img = TripsGlobeView.redPillImage()
                    try? mapView.mapboxMap.addImage(img, id: Self.cityImageName, sdf: false)
                    didAddCityImage = true
                }
                cityAnnotationManager = mapView.annotations.makePointAnnotationManager()
                spotAnnotationManager = mapView.annotations.makePointAnnotationManager()
                applyCityAnnotations()
            }

            private func ensureSpotImagesAdded() {
                guard let mapView = mapView, !didAddSpotImages else { return }
                for (catId, emoji) in TripsGlobeView.categoryEmojis {
                    let color = TripsGlobeView.categoryColors[catId] ?? .systemGray
                    let img = TripsGlobeView.categoryPinImage(emoji: emoji, color: color)
                    let id = Self.spotImagePrefix + catId
                    try? mapView.mapboxMap.addImage(img, id: id, sdf: false)
                }
                didAddSpotImages = true
            }

            func updateCityAnnotations(cities: [CityWithRecommendations]) {
                lastCities = cities
                applyCityAnnotations()
            }

            func updateSpotAnnotations(spots: [HousingSpot]) {
                lastSpots = spots
                applySpotAnnotations()
            }

            private func applyCityAnnotations() {
                guard let manager = cityAnnotationManager else { return }
                if !didAddCityImage, let mapView = mapView {
                    let img = TripsGlobeView.redPillImage()
                    try? mapView.mapboxMap.addImage(img, id: Self.cityImageName, sdf: false)
                    didAddCityImage = true
                }
                let img = TripsGlobeView.redPillImage()
                manager.annotations = lastCities.map { city in
                    var ann = MapboxMaps.PointAnnotation(coordinate: city.coordinate)
                    ann.image = .init(image: img, name: Self.cityImageName)
                    ann.tapHandler = { [weak self] _ in
                        self?.onCityTap?(city)
                        return true
                    }
                    return ann
                }
            }

            private func applySpotAnnotations() {
                guard let manager = spotAnnotationManager, let mapView = mapView else { return }
                ensureSpotImagesAdded()
                manager.annotations = lastSpots.compactMap { spot in
                    let catId = TripsGlobeView.spotCategoryId(for: spot.type)
                    guard let emoji = TripsGlobeView.categoryEmojis[catId] else { return nil }
                    let color = TripsGlobeView.categoryColors[catId] ?? .systemGray
                    let imageId = Self.spotImagePrefix + catId
                    let img = TripsGlobeView.categoryPinImage(emoji: emoji, color: color)
                    var ann = MapboxMaps.PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: spot.lat, longitude: spot.lng))
                    ann.image = .init(image: img, name: imageId)
                    ann.tapHandler = { [weak self] _ in
                        self?.onSpotTap?(spot)
                        return true
                    }
                    return ann
                }
            }
        }
    }

    // MARK: - Explore + Trips combined (globe + cities list → city zoom + pills + recommended places)
    private struct ExploreTripsMapView: View {
        let cities: [CityWithRecommendations]
        let spots: [HousingSpot]
        let avatarImages: [String]
        @Binding var hideTabBar: Bool
        let onClose: () -> Void
        var showBackButton: Bool = true

        enum SheetState { case collapsed, partial, full }

        @State private var selectedCity: CityWithRecommendations? = nil
        @State private var selectedMarkerCity: CityWithRecommendations? = nil
        @State private var sheetState: SheetState = .partial
        @State private var sheetDrag: CGFloat = 0
        @State private var showCityPicker = false
        @State private var selectedPlaceCategory: String? = nil // "bars" | "restaurants" | "cafes" | "activities" | "housing"
        enum CityDetailTab: String, CaseIterable { case spots = "Spot"; case housing = "Housing" }
        @State private var cityDetailTab: CityDetailTab = .spots
        @State private var selectedSpotForDetail: HousingSpot? = nil
        @State private var markerBlurbExpanded: Bool = false
        @State private var markerSheetDrag: CGFloat = 0
        @State private var expandedMarkerCity: CityWithRecommendations? = nil
        @State private var markerSheetDetent: PresentationDetent = .fraction(0.43)
        @State private var globeTarget: CLLocationCoordinate2D? = nil
        @State private var globeZoom: Double = 0.5
        @State private var searchText: String = ""
        @StateObject private var tripLocationSearcher = TripLocationSearcher()
        @FocusState private var isSearchFocused: Bool
        @Namespace private var segmentNamespace
        @State private var showCityDetailFilterSheet = false
        // Spot filters
        @State private var spotMinRecommendations: Int = 1
        // Housing filters
        @State private var cityDetailBudgetMin: Int = 0
        @State private var cityDetailBudgetMax: Int = 2500
        @State private var cityDetailHousingType: String = "All"
        @State private var cityDetailAvailableFrom: Date? = nil
        @State private var cityDetailScrollMinY: CGFloat = 0
        @State private var cityDetailMinRating: Int? = nil // nil = All, 1...5 = minimum stars
        @State private var housingFilterSearchText: String = ""
        @State private var cityDetailAvailabilityNow: Bool? = nil // nil = no filter, true = Now, false = Later
        @State private var showAddPinSheet = false
        private enum AddPinSheetContent { case place, housing }
        @State private var addPinSheetContent: AddPinSheetContent = .place
        @State private var housingListingCoordinate = CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35)

        private let placeCategories: [(id: String, emoji: String, label: String)] = [
            ("bars", "🍹", "Bars"),
            ("restaurants", "🍕", "Restaurants"),
            ("cafes", "🍵", "Cafes"),
            ("activities", "🎡", "Activities"),
            ("housing", "🏠", "Housing"),
        ]

        /// Spots à afficher sur le globe (pins par catégorie) — uniquement quand une ville est sélectionnée
        private var spotsToShowOnGlobe: [HousingSpot] {
            guard selectedCity != nil else { return [] }
            return cityDetailFilteredSpots
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    TripsGlobeView(
                        targetCoordinate: globeTarget,
                        targetZoom: globeZoom,
                        cities: cities,
                        spots: spotsToShowOnGlobe,
                        cameraBottomPadding: geometry.size.height / 4,
                        onCityTap: { city in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                selectedMarkerCity = city
                                selectedCity = nil
                                selectedPlaceCategory = nil
                                expandedMarkerCity = nil
                                markerSheetDrag = 0
                                globeTarget = city.coordinate
                                sheetState = .partial
                            }
                        },
                        onSpotTap: { spot in
                            selectedSpotForDetail = spot
                        }
                    )
                    .ignoresSafeArea()

                    if showBackButton && selectedCity == nil && selectedMarkerCity == nil && sheetState != .full {
                    VStack {
                            HStack {
                                Button(action: onClose) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 36, height: 36)
                                        .background(Color.white.opacity(0.9), in: Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                                }
                                .buttonStyle(.plain)
                        Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            Spacer()
                        }
                    }

                    if selectedCity != nil && sheetState != .full {
                        VStack {
                            HStack {
                                Button(action: backToInitialView) {
                                    Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 36, height: 36)
                                        .background(Color.white.opacity(0.9), in: Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, max(6, geometry.safeAreaInsets.top - 46))

                            Spacer()
                        }
                        .overlay(alignment: .top) {
                            if let city = selectedCity {
                                Button(action: { showCityPicker = true }) {
                                    HStack(spacing: 6) {
                                        Text(city.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.black)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.black.opacity(0.7))
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(Color.white.opacity(0.9), in: Capsule())
                                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, max(6, geometry.safeAreaInsets.top - 46))
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }

                    VStack {
                        if selectedCity == nil && selectedMarkerCity == nil && sheetState != .full {
                            exploreSearchBar
                            .padding(.horizontal, 20)
                                .padding(.top, max(0, geometry.safeAreaInsets.top - 64))
                            if !tripLocationSearcher.results.isEmpty && isSearchFocused {
                                exploreSearchResults
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.25), value: sheetState)

                    // Marker city sheet presented natively (same animation as "Choisir une ville")
                    if selectedMarkerCity == nil {
                        // MARK: - Liquid Glass bottom sheet (offset-based, GPU-driven)
                        partialSheet(geometry: geometry)
                            .frame(height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom, alignment: .top)
                            .offset(y: sheetOffsetY(geometry: geometry))
                            .compositingGroup()  // flatten material + children into one composited layer
                    }

                    // Bouton + au-dessus de la bottom sheet, à droite (ajouter un pin) — visible quand une ville est sélectionnée
                    if selectedCity != nil {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: { showAddPinSheet = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 48, height: 48)
                                        .background(Color.appAccent, in: Circle())
                                        .shadow(color: Color.appAccent.opacity(0.4), radius: 8, y: 4)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 20)
                                .padding(.bottom, geometry.size.height * 0.53 - 24)
                            }
                        }
                        .allowsHitTesting(true)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $showAddPinSheet) {
                Group {
                    switch addPinSheetContent {
                    case .place:
                        CreatePlaceView(
                            onSelectHousing: {
                                housingListingCoordinate = selectedCity?.coordinate ?? CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35)
                                var t = Transaction()
                                t.disablesAnimations = true
                                withTransaction(t) { addPinSheetContent = .housing }
                            }
                        )
                    case .housing:
                        CreateHousingListingView(
                            activeTab: .constant(HousingTab.spots),
                            coordinate: housingListingCoordinate,
                            onCreateSpot: { _ in
                                showAddPinSheet = false
                                addPinSheetContent = .place
                            },
                            onCreateRoommate: { _ in },
                            onClose: {
                                showAddPinSheet = false
                                addPinSheetContent = .place
                            }
                        )
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
            }
            .sheet(item: $selectedSpotForDetail) { spot in
                HousingDetailSheet(spot: spot, onClose: { selectedSpotForDetail = nil })
            }
            .sheet(isPresented: $showCityPicker) {
                cityPickerSheet
            }
            .sheet(item: $selectedMarkerCity) { city in
                markerCitySheetContent(city: city, selectedDetent: $markerSheetDetent) {
                    selectedMarkerCity = nil
                } onExplore: {
                    selectedMarkerCity = nil
                        selectedCity = city
                    globeTarget = city.coordinate
                    globeZoom = 9
                    sheetState = .full
                }
            }
            .sheet(isPresented: $showCityDetailFilterSheet) {
                cityDetailFilterSheetContent
            }
            .onChange(of: selectedCity) { _, new in
                hideTabBar = (new != nil || selectedMarkerCity != nil)
                if new != nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        sheetState = .partial
                    }
                }
            }
            .onChange(of: selectedMarkerCity) { _, new in
                hideTabBar = (selectedCity != nil || new != nil)
                markerBlurbExpanded = false
                markerSheetDrag = 0
                if new != nil {
                    markerSheetDetent = markerSheetClosedDetent
                }
                if new == nil {
                    expandedMarkerCity = nil
                }
            }
            .onAppear {
                hideTabBar = (selectedCity != nil || selectedMarkerCity != nil)
            }
        }

        /// Computes the sheet's Y offset with rubber-banding at edges.
        private func sheetOffsetY(geometry: GeometryProxy) -> CGFloat {
            let partialH = geometry.size.height * (selectedCity == nil ? 0.32 : 0.40)
            let floatingBottomGap: CGFloat = selectedCity != nil ? 12 : 0
            let partialY = geometry.size.height - partialH - floatingBottomGap
            let fullY: CGFloat = -geometry.safeAreaInsets.top
            let baseY: CGFloat = sheetState == .full ? fullY : partialY
            let rawY = baseY + sheetDrag

            if rawY < fullY {
                return fullY - (fullY - rawY) * 0.15       // rubber-band top
            } else if rawY > partialY {
                return partialY + (rawY - partialY) * 0.15 // rubber-band bottom
            }
            return rawY
        }

        /// 0 = partial position, 1 = fully expanded. Tracks live drag.
        private func sheetFraction(geometry: GeometryProxy) -> CGFloat {
            let partialH = geometry.size.height * (selectedCity == nil ? 0.32 : 0.40)
            let floatingBottomGap: CGFloat = selectedCity != nil ? 12 : 0
            let partialY = geometry.size.height - partialH - floatingBottomGap
            let fullY: CGFloat = -geometry.safeAreaInsets.top
            let currentY = sheetOffsetY(geometry: geometry)
            let fraction = 1.0 - (currentY - fullY) / max(1, partialY - fullY)
            return min(1, max(0, fraction))
        }

        private func backToInitialView() {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selectedCity = nil
                selectedMarkerCity = nil
                selectedPlaceCategory = nil
                sheetState = .partial
                globeTarget = nil
                globeZoom = 0.5
                searchText = ""
                tripLocationSearcher.results = []
            }
            isSearchFocused = false
        }

        private var cityPickerSheet: some View {
            NavigationStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Text("Choose a city")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 16)

                        ForEach(cities) { city in
                            Button(action: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    selectedCity = city
                                    globeTarget = city.coordinate
                                    globeZoom = 9
                                    showCityPicker = false
                                }
                            }) {
                                HStack(spacing: 14) {
                                    cityImageView(for: city, fallback: Color(.systemGray5))
                                        .frame(width: 52, height: 52)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(city.name)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("\(city.recommendationCount) recommendations")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Change city")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showCityPicker = false
                        }
                        .font(.system(size: 16, weight: .medium))
                    }
                }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }

        private var togglePill: some View {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    switch sheetState {
                    case .collapsed: sheetState = .partial
                    case .partial: sheetState = .collapsed
                    case .full: sheetState = .partial
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: sheetState == .full ? "map.fill" : "list.bullet")
                        .font(.system(size: 14, weight: .semibold))
                    Text(sheetState == .full ? "Map" : "Show list")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "222222"), in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }

        private var exploreSearchBar: some View {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search for a place")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    TextField("", text: $searchText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .focused($isSearchFocused)
                        .onChange(of: searchText) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                tripLocationSearcher.results = []
            } else {
                                tripLocationSearcher.search(query: newValue)
                            }
                        }
                }
                Spacer()
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        tripLocationSearcher.results = []
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular.tint(Color.white.opacity(0.85)), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5))
            .environment(\.colorScheme, .light)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }

        private var exploreSearchResults: some View {
            VStack(spacing: 0) {
                ForEach(tripLocationSearcher.results, id: \.self) { result in
                    Button(action: {
                        let title = result.title
                        let subtitle = result.subtitle
                        let query = subtitle.isEmpty ? title : "\(title), \(subtitle)"
                        searchText = query
                        isSearchFocused = false
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCity = nil
                            tripLocationSearcher.results = []
                        }
                        let geocoder = CLGeocoder()
                        geocoder.geocodeAddressString(query) { placemarks, _ in
                            guard let coordinate = placemarks?.first?.location?.coordinate else { return }
                            withAnimation(.easeInOut(duration: 0.8)) {
                                globeTarget = coordinate
                                globeZoom = 9
                            }
                        }
                    }) {
        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if result != tripLocationSearcher.results.last {
                        Divider()
                    }
                }
            }
            .glassEffect(.regular.tint(Color.white.opacity(0.85)), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5))
            .environment(\.colorScheme, .light)
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }

        private func partialSheet(geometry: GeometryProxy) -> some View {
            let frac = sheetFraction(geometry: geometry)
            let topPad = 10 + frac * (geometry.safeAreaInsets.top - 2)  // 10 → safeArea+8

            let sheetDragGesture = DragGesture(minimumDistance: 6, coordinateSpace: .global)
                .onChanged { value in
                    guard abs(value.translation.height) > abs(value.translation.width) else { return }
                    var t = Transaction()
                    t.animation = nil
                    withTransaction(t) {
                        if selectedCity != nil && value.translation.height < 0 {
                            sheetDrag = 0
                            } else {
                            sheetDrag = value.translation.height
                        }
                    }
                }
                .onEnded { value in
                    guard abs(value.translation.height) > abs(value.translation.width) else {
                        sheetDrag = 0
                        return
                    }
                    if selectedCity != nil {
                        withAnimation(.interpolatingSpring(stiffness: 200, damping: 24)) {
                            sheetDrag = 0
                            sheetState = .partial
                        }
                        return
                    }
                    let velocity = value.predictedEndTranslation.height - value.translation.height
                    let speed = abs(velocity)
                    let oldState = sheetState
                    var newState = sheetState
                    if value.translation.height < -50 || velocity < -500 {
                        newState = .full
                    } else if (value.translation.height > 50 || velocity > 500) && sheetState == .full {
                        newState = .partial
                    }
                    let stiffness: Double = speed > 800 ? 280 : 200
                    let damping: Double = speed > 800 ? 28 : 24
                    withAnimation(.interpolatingSpring(stiffness: stiffness, damping: damping)) {
                        sheetDrag = 0
                        sheetState = newState
                    }
                    if newState != oldState {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

            return VStack(spacing: 0) {
                // Header area only: drag handle + title/search — sheet drag applies here so list can scroll
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 36, height: 5)
                        .padding(.top, topPad)
                        .padding(.bottom, 4)

                    HStack {
                        Button(action: {
                            withAnimation(.interpolatingSpring(stiffness: 200, damping: 24)) {
                                sheetState = .partial
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.06), in: Circle())
                        }
                        .buttonStyle(.plain)
            Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 36 * frac)
                    .opacity(frac)
                    .offset(y: -6)
                    .clipped()

                    if selectedCity == nil {
                        VStack(spacing: 6) {
                            Text("Cities")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .frame(height: 60 * (1 - frac))
                        .opacity(1 - frac)
                        .clipped()

                        exploreSearchBar
                            .padding(.horizontal, 20)
                            .frame(height: 62 * frac)
                            .opacity(frac)
                            .allowsHitTesting(frac > 0.5)
                            .clipped()

                        if frac > 0.5 && !tripLocationSearcher.results.isEmpty && isSearchFocused {
                            exploreSearchResults
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .contentShape(Rectangle())
                .highPriorityGesture(sheetDragGesture)

                if selectedCity == nil {
                    ScrollView(.vertical, showsIndicators: false) {
                        citiesListContent
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 56)
                    }
                    .scrollDisabled(sheetState == .collapsed) // Allow scroll when sheet is open (partial or full)
                } else {
                    cityDetailContent(geometry: geometry)
                        .padding(.bottom, 14)
                }
            }
            .frame(
                width: selectedCity != nil ? min(geometry.size.width - 28, 560) : geometry.size.width,
                alignment: .center
            )
            .frame(
                height: selectedCity != nil ? geometry.size.height * 0.40 : nil,
                alignment: .top
            )
            .environment(\.colorScheme, .light)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.15), radius: 20, y: -6)
        }

        private func markerCityFilteredSpots(for city: CityWithRecommendations) -> [HousingSpot] {
            let cityLocation = CLLocation(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
            let citySpots = spots.filter { spot in
                let spotLocation = CLLocation(latitude: spot.lat, longitude: spot.lng)
                return cityLocation.distance(from: spotLocation) <= 120_000
            }

            let source = citySpots.isEmpty ? spots : citySpots

            guard let selectedPlaceCategory else {
                return source
            }

            return source.filter { spot in
                let type = spot.type.lowercased()
                switch selectedPlaceCategory {
                case "bars":
                    return type.contains("bar")
                case "restaurants":
                    return type.contains("restaurant")
                case "cafes":
                    return type.contains("cafe")
                case "activities":
                    return type.contains("activity")
                case "housing":
                    return type.contains("room") || type.contains("place") || type.contains("housing")
                default:
                    return true
                }
            }
        }

        private func markerCityDetailContent(geometry: GeometryProxy, city: CityWithRecommendations) -> some View {
            VStack(spacing: 12) {
                            Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        selectedMarkerCity = nil
                        selectedCity = city
                        globeTarget = city.coordinate
                        globeZoom = 9
                        sheetState = .full
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Explore this city")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccent, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }

        private struct CityInsight {
            let country: String
            let blurb: String
            let vibe: String
            let bestFor: String
        }

        private func cityInsight(for city: CityWithRecommendations) -> CityInsight {
            switch city.name.lowercased() {
            case "bali":
                return CityInsight(
                    country: "Indonesia",
                    blurb: "Island destination known for temples, beaches, and rice terraces.",
                    vibe: "Relaxed tropical vibe",
                    bestFor: "Surf, wellness, sunsets"
                )
            case "montreal":
                return CityInsight(
                    country: "Canada",
                    blurb: "Creative city mixing French charm, food culture, and festivals.",
                    vibe: "Urban and cultural",
                    bestFor: "Nightlife, food, neighborhoods"
                )
            case "barcelona":
                return CityInsight(
                    country: "Spain",
                    blurb: "Mediterranean city with Gaudi architecture and beach energy.",
                    vibe: "Sunny and social",
                    bestFor: "Architecture, tapas, beach"
                )
            case "new york":
                return CityInsight(
                    country: "United States",
                    blurb: "Fast-paced metropolis with iconic skyline and diverse districts.",
                    vibe: "Dynamic and nonstop",
                    bestFor: "Food, culture, city life"
                )
            case "paris":
                return CityInsight(
                    country: "France",
                    blurb: "Classic European capital with monuments, cafes, and style.",
                    vibe: "Elegant and walkable",
                    bestFor: "Museums, cafes, landmarks"
                )
            default:
                return CityInsight(
                    country: "Destination",
                    blurb: "A great city to explore with curated recommendations.",
                    vibe: "Local favorites",
                    bestFor: "Food, places, experiences"
                )
            }
        }

        private func nearbySpots(for city: CityWithRecommendations) -> [HousingSpot] {
            let cityLocation = CLLocation(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
            return spots.filter { spot in
                CLLocation(latitude: spot.lat, longitude: spot.lng).distance(from: cityLocation) <= 120_000
            }
        }

        /// Image URLs for the marker city sheet: main city image + nearby spot images (max 12).
        private func markerCityImageUrls(for city: CityWithRecommendations) -> [String] {
            var urls = [city.imageUrl]
            for spot in nearbySpots(for: city) {
                if urls.count >= 12 { break }
                if !urls.contains(spot.image) { urls.append(spot.image) }
            }
            return urls
        }

        private func markerCitySquareImage(url: String, fallback: Color) -> some View {
            Group {
                if url.hasPrefix("http://") || url.hasPrefix("https://") {
                    AsyncImage(url: URL(string: url)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(fallback)
                        }
                    }
                } else {
                    Image(cityAssetName(from: url))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        private func markerCityPhotoStripAndBlurb(city: CityWithRecommendations) -> some View {
            let insight = cityInsight(for: city)
            let imageUrls = markerCityImageUrls(for: city)

            return VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(imageUrls, id: \.self) { url in
                            markerCitySquareImage(url: url, fallback: Color(.systemGray4))
                        }
                    }
                    .padding(.trailing, 20)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.blurb)
                        .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                        .lineLimit(markerBlurbExpanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { markerBlurbExpanded.toggle() } }) {
                        Text(markerBlurbExpanded ? "Show less" : "Show more")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        private func markerCityOverviewCard(city: CityWithRecommendations) -> some View {
            markerCityPhotoStripAndBlurb(city: city)
        }

        private let markerSheetClosedDetent = PresentationDetent.fraction(0.43)

        /// Marker city sheet — un seul contenu scrollable, le déplier révèle le reste
        private func markerCitySheetContent(
            city: CityWithRecommendations,
            selectedDetent: Binding<PresentationDetent>,
            onClose: @escaping () -> Void,
            onExplore: @escaping () -> Void
        ) -> some View {
            markerCitySheetUnifiedContent(city: city, onClose: onClose, onExplore: onExplore)
                .background(Color.white)
                .presentationDetents([markerSheetClosedDetent, .large], selection: selectedDetent)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }

        /// Contenu unifié : tout dans un ScrollView, déplier la sheet révèle naturellement Information, Guides, etc.
        private func markerCitySheetUnifiedContent(
            city: CityWithRecommendations,
            onClose: @escaping () -> Void,
            onExplore: @escaping () -> Void
        ) -> some View {
            let facts = markerCityFacts(for: city)
            let images = markerCityImageUrls(for: city)
            let guides = Array((nearbySpots(for: city).isEmpty ? spots : nearbySpots(for: city)).prefix(4))

            return VStack(spacing: 0) {
                // Header fixe
                HStack {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray5), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Text(city.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray5), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Tout le contenu dans un seul ScrollView — déplier révèle le reste
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Button(action: onExplore) {
                            HStack(spacing: 8) {
                                Text("Explore this city")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appAccent, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 12) {
                            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                                VStack(alignment: .center, spacing: 4) {
                                    Text(fact.label)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.black)
                                    HStack(spacing: 6) {
                                        Text(fact.emoji)
                                            .font(.system(size: 16))
                                        Text(fact.value)
                                            .font(.system(size: 15, weight: .semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(images, id: \.self) { imageUrl in
                                    markerCitySheetImageThumb(url: imageUrl)
                                        .frame(width: 200, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        .frame(height: 150)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Information")
                                .font(.system(size: 20, weight: .bold))
                            Text(markerCityLongDescription(for: city))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let wikiURL = markerCityWikipediaURL(for: city) {
                                Link("More on Wikipedia", destination: wikiURL)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }

                        if !guides.isEmpty {
                            Text("Guides")
                                .font(.system(size: 20, weight: .bold))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(guides) { spot in
                                    markerCityGuideCard(spot: spot)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }

        private func markerCitySheetImageThumb(url: String) -> some View {
            Group {
                if url.hasPrefix("http://") || url.hasPrefix("https://") {
                    AsyncImage(url: URL(string: url)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color(.systemGray4)
                                .overlay(ProgressView())
                        }
                    }
                } else {
                    Image(cityAssetName(from: url))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
        }

        private func markerCityExpandedSheet(city: CityWithRecommendations) -> some View {
            let facts = markerCityFacts(for: city)
            let images = markerCityImageUrls(for: city)
            let guides = Array((nearbySpots(for: city).isEmpty ? spots : nearbySpots(for: city)).prefix(4))

            return VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.black.opacity(0.22))
                    .frame(width: 44, height: 6)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                HStack {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemGray5), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { expandedMarkerCity = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemGray5), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)

                Text(city.name)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.top, 2)
                    .padding(.bottom, 20)

                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            expandedMarkerCity = nil
                            selectedMarkerCity = nil
                            selectedCity = city
                            globeTarget = city.coordinate
                            globeZoom = 9
                            sheetState = .full
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Explore this city")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appAccent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 12) {
                            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                                VStack(alignment: .center, spacing: 4) {
                                    Text(fact.label)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.black)
                                    HStack(spacing: 6) {
                                        Text(fact.emoji)
                                            .font(.system(size: 18))
                                        Text(fact.value)
                                            .font(.system(size: 17, weight: .semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(images, id: \.self) { imageUrl in
                                    markerCitySquareImage(url: imageUrl, fallback: Color(.systemGray4))
                                }
                            }
                            .padding(.trailing, 20)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Information")
                                .font(.system(size: 24, weight: .bold))
                            Text(markerCityLongDescription(for: city))
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let wikiURL = markerCityWikipediaURL(for: city) {
                                Link("More on Wikipedia", destination: wikiURL)
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }

                        if !guides.isEmpty {
                            Text("Guides")
                                .font(.system(size: 24, weight: .bold))

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(guides) { spot in
                                    markerCityGuideCard(spot: spot)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGray6))
            .environment(\.colorScheme, .light)
        }

        private func markerCityGuideCard(spot: HousingSpot) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: spot.image)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(height: 132)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(spot.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(recommendationCategory(for: spot.type).label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }

        private func markerCityFacts(for city: CityWithRecommendations) -> [(emoji: String, label: String, value: String)] {
            let cityLocation = CLLocation(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
            let nearby = spots.filter { spot in
                CLLocation(latitude: spot.lat, longitude: spot.lng).distance(from: cityLocation) <= 120_000
            }
            func categoryId(for type: String) -> String? {
                let raw = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if raw.contains("restaurant") { return "restaurants" }
                if raw.contains("cafe") { return "cafes" }
                if raw.contains("bar") { return "bars" }
                if raw.contains("activity") { return "activities" }
                if raw.contains("room") || raw.contains("place") || raw.contains("housing") { return "housing" }
                return "housing"
            }
            var counts: [String: Int] = [:]
            for spot in nearby {
                if let id = categoryId(for: spot.type) {
                    counts[id, default: 0] += 1
                }
            }
            let restaurants = counts["restaurants", default: 0] + counts["cafes", default: 0]
            let logements = counts["housing", default: 0]
            let bars = counts["bars", default: 0]
            let activites = counts["activities", default: 0]
            return [
                ("🍕", "Restaurants", "\(restaurants)"),
                ("🏠", "Housing", "\(logements)"),
                ("🍹", "Bars", "\(bars)"),
                ("🎯", "Activities", "\(activites)"),
            ]
        }

        private func markerCityLongDescription(for city: CityWithRecommendations) -> String {
            switch city.name.lowercased() {
            case "paris":
                return "Paris is the capital of France and a major global city. Its heritage, neighbourhoods and culture make it an unmissable destination."
            case "lisbon":
                return "Lisbon is built on seven hills along the Tagus. The city combines historic architecture, local cuisine and lively nightlife."
            case "montreal":
                return "Montreal is a bilingual metropolis known for its festivals, food scene and creative neighbourhoods."
            case "new york":
                return "New York is one of the world's most influential cultural and economic centres, with a unique urban energy."
            case "tokyo":
                return "Tokyo blends tradition and innovation, from historic temples to modern districts and world-class cuisine."
            case "barcelona":
                return "Barcelona is a vibrant Mediterranean city known for its architecture, beaches and welcoming atmosphere."
            case "bali":
                return "Bali is an island destination famous for its temples, beaches, rice terraces and wellness culture."
            default:
                return "A great city to explore with curated recommendations."
            }
        }

        private func markerCityWikipediaURL(for city: CityWithRecommendations) -> URL? {
            let name = city.name.replacingOccurrences(of: " ", with: "_")
            return URL(string: "https://en.wikipedia.org/wiki/\(name)")
        }

        /// Counts spots near the city by category (housing, food, drinks, etc.) for the card recap.
        private func citySpotCounts(for city: CityWithRecommendations) -> [(id: String, emoji: String, label: String, count: Int)] {
            let cityLocation = CLLocation(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
            let nearby = spots.filter { spot in
                CLLocation(latitude: spot.lat, longitude: spot.lng).distance(from: cityLocation) <= 120_000
            }
            func categoryId(for type: String) -> String? {
                let raw = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if raw.contains("restaurant") { return "restaurants" }
                if raw.contains("cafe") { return "cafes" }
                if raw.contains("bar") { return "bars" }
                if raw.contains("activity") { return "activities" }
                if raw.contains("room") || raw.contains("place") || raw.contains("housing") { return "housing" }
                return "housing"
            }
            var counts: [String: Int] = [:]
            for spot in nearby {
                if let id = categoryId(for: spot.type) {
                    counts[id, default: 0] += 1
                }
            }
            return placeCategories.compactMap { cat in
                let n = counts[cat.id] ?? 0
                return (cat.id, cat.emoji, cat.label, n)
            }.filter { $0.count > 0 }
        }

        private var citiesListContent: some View {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 14) {
                    ForEach(cities) { city in
                    Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                selectedCity = city
                                globeTarget = city.coordinate
                                globeZoom = 9
                            }
                        }) {
                            cityCardView(city: city)
                    }
                    .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }

        private func cityCardView(city: CityWithRecommendations) -> some View {
            ZStack {
                cityImageView(for: city, fallback: Color(.systemGray5))
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.4), Color.black.opacity(0.0), Color.black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(city.name.uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }

        /// Pills de catégories visibles selon le tab actif (en Housing, on n’affiche pas la pill Housing)
        private var visiblePlaceCategories: [(id: String, emoji: String, label: String)] {
            if cityDetailTab == .housing {
                return [] // pas de pill en mode Housing
            }
            return placeCategories.filter { $0.id != "housing" }
        }

        /// Spots filtrés selon le tab actif, la catégorie et les filtres (recos / budget, type, date)
        private var cityDetailFilteredSpots: [HousingSpot] {
            guard let city = selectedCity else { return [] }
            let allNearby = markerCityFilteredSpots(for: city)
            let byTab: [HousingSpot]
            if cityDetailTab == .housing {
                byTab = allNearby.filter { spot in
                    let t = spot.type.lowercased()
                    return t.contains("room") || t.contains("place") || t.contains("housing") || t.contains("entire") || t.contains("private")
                }
            } else {
                let filtered = allNearby.filter { spot in
                    let t = spot.type.lowercased()
                    return !(t.contains("room") || t.contains("place") || t.contains("housing") || t.contains("entire") || t.contains("private"))
                }
                byTab = filtered.isEmpty ? allNearby : filtered
            }
            // Apply Spot filters: minimum number of recommendations
            if cityDetailTab == .spots {
                return byTab.filter { recommendationAvatars(for: $0).count >= spotMinRecommendations }
            }
            // Apply Housing filters: budget, type, minimum rating
            return byTab.filter { spot in
                if spot.price < cityDetailBudgetMin || spot.price > cityDetailBudgetMax { return false }
                switch cityDetailHousingType {
                case "Room":
                    if !spot.type.lowercased().contains("room") { return false }
                case "Entire place":
                    if !(spot.type.lowercased().contains("entire") || spot.type.lowercased().contains("place")) { return false }
                default: break
                }
                if let minR = cityDetailMinRating, Int(spot.rating) < minR { return false }
                if let now = cityDetailAvailabilityNow {
                    if now {
                        if !spot.isAvailableNow { return false }
                    } else {
                        if spot.isAvailableNow { return false }
                        if let from = cityDetailAvailableFrom, let avail = spot.availableDate, avail > from { return false } // pas dispo avant la date choisie
                    }
                }
                return true
            }
        }

        private struct ScrollContentMinYKey: PreferenceKey {
            static var defaultValue: CGFloat { 0 }
            static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
        }

        private func cityDetailPillsView() -> some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(visiblePlaceCategories, id: \.id) { cat in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlaceCategory = selectedPlaceCategory == cat.id ? nil : cat.id
                            }
                        }) {
                            HStack(spacing: 5) {
                                Text(cat.emoji)
                                    .font(.system(size: 13))
                                Text(cat.label)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedPlaceCategory == cat.id ? Color.appAccent : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)
            }
        }

        private func cityDetailContent(geometry: GeometryProxy) -> some View {
            let horizontalPadding: CGFloat = 32
            let contentWidth = geometry.size.width - horizontalPadding * 2
            let showStickyPills = !visiblePlaceCategories.isEmpty && cityDetailScrollMinY < -52
            return ZStack(alignment: .top) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Toggle Spot / Housing + filtre (disparaissent au scroll)
                        ZStack(alignment: .center) {
                            HStack(spacing: 0) {
                                ForEach(CityDetailTab.allCases, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            cityDetailTab = tab
                                            selectedPlaceCategory = nil
                                        }
                                    }) {
                                        Text(tab.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(cityDetailTab == tab ? .white : Color(.systemGray))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(
                                                Group {
                                                    if cityDetailTab == tab {
                                                        Capsule()
                                                            .fill(Color.appAccent)
                                                            .matchedGeometryEffect(id: "segment", in: segmentNamespace)
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(2)
                            .background(Color(.systemGray5).opacity(0.5), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))

                            HStack {
                                Spacer(minLength: 0)
                                Button(action: { showCityDetailFilterSheet = true }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Color(.systemGray))
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, horizontalPadding)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 8)

                        // Pills dans le scroll (Bars, Restaurants, etc.)
                        if !visiblePlaceCategories.isEmpty {
                            cityDetailPillsView()
                                .padding(.top, 4)
                                .padding(.bottom, 0)
                        }

                        // Liste de lieux empilés verticalement
                        VStack(spacing: 10) {
                            ForEach(cityDetailFilteredSpots) { spot in
                                recommendedPlaceRow(
                                    spot: spot,
                                    cardWidth: contentWidth
                                )
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(
                                key: ScrollContentMinYKey.self,
                                value: g.frame(in: .named("cityDetailScroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "cityDetailScroll")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onPreferenceChange(ScrollContentMinYKey.self) { cityDetailScrollMinY = $0 }

                // Header sticky : pills seules quand on a scrollé (toggle + filtre disparus)
                if showStickyPills {
                    cityDetailPillsView()
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.08))
                                .frame(height: 1),
                            alignment: .bottom
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private func recommendedPlaceRow(spot: HousingSpot, cardWidth: CGFloat? = nil) -> some View {
            let meta = recommendationCategory(for: spot.type)
            let recommenders = recommendationAvatars(for: spot)
            let peopleCount = max(Int(spot.rating * 50), recommenders.count)

            return HStack(spacing: 12) {
                AsyncImage(url: URL(string: spot.image)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [meta.tint.opacity(0.95), Color.appAccent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: meta.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(meta.label.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(meta.tint.opacity(0.95))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(meta.tint.opacity(0.18), in: Capsule())

                    Text(spot.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        HStack(spacing: -6) {
                            ForEach(Array(recommenders.prefix(3).enumerated()), id: \.offset) { _, imageUrl in
                                AsyncImage(url: URL(string: imageUrl)) { phase in
                                    if let image = phase.image {
                                        image.resizable()
                            } else {
                                        Color(.systemGray5)
                                    }
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            }
                        }

                        Text("Recommended by \(peopleCount)+")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: cardWidth, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .onTapGesture { selectedSpotForDetail = spot }
        }

        private var cityDetailFilterSheetContent: some View {
            NavigationStack {
                Group {
                    if cityDetailTab == .spots {
                        spotFilterContent
                            .navigationTitle("Filters")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        showCityDetailFilterSheet = false
                                    }
                                    .foregroundStyle(Color.appAccent)
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Show \(cityDetailFilteredSpots.count) results") {
                                        showCityDetailFilterSheet = false
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.appAccent)
                                }
                            }
                    } else {
                        housingFilterContent
                            .navigationBarHidden(true)
                    }
                }
            }
        }

        private var spotFilterContent: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("👥")
                                .font(.system(size: 22))
                            Text("Number of recommendations")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        Text("Show only spots recommended by at least this many people.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach([1, 2, 3], id: \.self) { count in
                                let label = count == 3 ? "3+" : "\(count)"
                                let isSelected = spotMinRecommendations == count
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        spotMinRecommendations = count
                                    }
                                }) {
                                    Text("\(label)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(isSelected ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            isSelected ? Color.appAccent : Color(.systemGray6),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
        }

        private var housingFilterContent: some View {
            let budgetMinDouble = Binding(
                get: { Double(cityDetailBudgetMin) },
                set: { cityDetailBudgetMin = Int(min(2500, max(0, $0))) }
            )
            let budgetMaxDouble = Binding(
                get: { Double(cityDetailBudgetMax) },
                set: { cityDetailBudgetMax = Int(min(2500, max(0, $0))) }
            )
            return VStack(spacing: 0) {
                // Header : Close (X) | Find your place | Reset
                HStack(spacing: 12) {
                    Button(action: { showCityDetailFilterSheet = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.appAccent, in: Circle())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(.systemGray))
                        TextField("Find your place", text: $housingFilterSearchText)
                            .font(.system(size: 16, weight: .regular))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(maxWidth: .infinity)

                    Button("Reset") {
                        cityDetailBudgetMin = 0
                        cityDetailBudgetMax = 2500
                        cityDetailHousingType = "All"
                        cityDetailMinRating = nil
                        cityDetailAvailabilityNow = nil
                        cityDetailAvailableFrom = nil
                        housingFilterSearchText = ""
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Type of housing — selected = black outline, white background
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary)
                                Text("Type of housing")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            Text("What kind of place are you looking for?")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 0) {
                                ForEach([("All", "All types"), ("Room", "Room"), ("Entire place", "Entire place")], id: \.0) { value, label in
                                    let isSelected = cityDetailHousingType == value
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            cityDetailHousingType = value
                                        }
                                    }) {
                                        Text(label)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                isSelected ? Color.white : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .strokeBorder(isSelected ? Color(hex: "222222") : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    if value == "Room" {
                                        Rectangle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: 1)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            .padding(4)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // Monthly budget — slider + min/max pills
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary)
                                Text("Monthly budget")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            Text("Select your budget range.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            BudgetRangeSliderView(
                                minValue: budgetMinDouble,
                                maxValue: budgetMaxDouble,
                                range: 0...2500,
                                step: 50
                            )
                            .frame(height: 44)
                            HStack(spacing: 12) {
                                Text("\(cityDetailBudgetMin) $CA")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Spacer()
                                Text(cityDetailBudgetMax >= 2500 ? "2,500+ $CA" : "\(cityDetailBudgetMax) $CA")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        // Minimum rating — All (red) + 1+ à 5+ avec étoiles
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.yellow)
                                Text("Minimum rating")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            Text("Only show highly-rated places.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            cityDetailMinRating = nil
                                        }
                                    }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 20))
                                            Text("All")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundStyle(cityDetailMinRating == nil ? .white : .primary)
                                        .frame(width: 60, height: 70)
                                        .background(
                                            cityDetailMinRating == nil ? Color.appAccent : Color.white,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(cityDetailMinRating == nil ? Color.clear : Color(.systemGray5), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    ForEach(1...5, id: \.self) { rating in
                                        let isSelected = cityDetailMinRating == rating
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                cityDetailMinRating = rating
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                HStack(spacing: 2) {
                                                    ForEach(0..<rating, id: \.self) { _ in
                                                        Image(systemName: "star.fill")
                                                            .font(.system(size: 10))
                                                            .foregroundStyle(isSelected ? .white : .yellow)
                                                    }
                                                }
                                                Text("\(rating)+")
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .frame(width: 60, height: 70)
                                            .background(
                                                isSelected ? Color.appAccent : Color.white,
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(isSelected ? Color.clear : Color(.systemGray5), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Availability — When do you need the place? (Now / Later)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary)
                                Text("Availability")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            Text("When do you need the place?")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            VStack(spacing: 10) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        cityDetailAvailabilityNow = true
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Text("💃")
                                            .font(.system(size: 22))
                                        Text("Now")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(cityDetailAvailabilityNow == true ? Color.appAccent : Color(.systemGray4), lineWidth: cityDetailAvailabilityNow == true ? 2 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        cityDetailAvailabilityNow = false
                                        if cityDetailAvailableFrom == nil {
                                            cityDetailAvailableFrom = Date()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.primary)
                                        Text("Later")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(cityDetailAvailabilityNow == false ? Color.appAccent : Color(.systemGray4), lineWidth: cityDetailAvailabilityNow == false ? 2 : 1)
                                    )
                                }
                                .buttonStyle(.plain)

                                // Calendrier quand "Later" est sélectionné
                                if cityDetailAvailabilityNow == false {
                                    DatePicker(
                                        "Date",
                                        selection: Binding(
                                            get: { cityDetailAvailableFrom ?? Date() },
                                            set: { cityDetailAvailableFrom = $0 }
                                        ),
                                        in: Date()...,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.graphical)
                                    .tint(Color.appAccent)
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }

                // Bouton sticky en bas : Show X results
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 1)
                    Button(action: { showCityDetailFilterSheet = false }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Show \(cityDetailFilteredSpots.count) results")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "222222"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.white)
            }
        }

        private func recommendationCategory(for type: String) -> (label: String, icon: String, tint: Color) {
            let raw = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            if raw.contains("restaurant") {
                return ("Restaurant", "fork.knife", Color.pink)
            }
            if raw.contains("cafe") {
                return ("Cafes", "cup.and.saucer.fill", Color.green)
            }
            if raw.contains("bar") {
                return ("Bars", "wineglass.fill", Color.orange)
            }
            if raw.contains("activity") {
                return ("Activities", "sparkles", Color.purple)
            }
            if raw.contains("room") || raw.contains("place") || raw.contains("housing") {
                return ("Housing", "house.fill", Color.blue)
            }
            return ("Housing", "house.fill", Color.blue)
        }

        private func recommendationAvatars(for spot: HousingSpot) -> [String] {
            var unique: [String] = []

            let candidates = [spot.recommenderImg] + avatarImages
            for avatar in candidates where !avatar.isEmpty {
                if !unique.contains(avatar) {
                    unique.append(avatar)
                }
            }

            return unique
        }

        private func fullScreenSheet(geometry: GeometryProxy) -> some View {
            VStack(spacing: 0) {
                HStack {
                            Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            sheetState = .partial
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if let city = selectedCity {
                        Text(city.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Cities")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if selectedCity == nil {
                    fullScreenCitiesList
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(spots) { spot in
                                recommendedPlaceRow(spot: spot)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.colorScheme, .dark)
            .background(Color.black)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 100 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { sheetState = .partial }
                        }
                    }
            )
        }

        private var fullScreenCitiesList: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Choose a city to discover recommendations")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ForEach(cities) { city in
                        cityGuideCard(city: city)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                    selectedCity = city
                                    globeTarget = city.coordinate
                                    globeZoom = 9
                                    sheetState = .partial
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }

        private func cityGuideCard(city: CityWithRecommendations) -> some View {
            ZStack(alignment: .bottomLeading) {
                cityImageView(for: city, fallback: Color(.systemGray4))
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.3), .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text(city.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(city.recommendationCount) recommendations")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }

                    HStack(spacing: 8) {
                        Text("See recommendations")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.white, in: Capsule())
                }
                .padding(20)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }

        @ViewBuilder
        private func cityImageView(for city: CityWithRecommendations, fallback: Color) -> some View {
            let rawName = city.imageUrl
            if rawName.hasPrefix("http://") || rawName.hasPrefix("https://") {
                AsyncImage(url: URL(string: rawName)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                        Rectangle()
                            .fill(fallback)
                    }
                }
            } else {
                Image(cityAssetName(from: rawName))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }

        private func cityAssetName(from rawName: String) -> String {
            switch rawName {
            case "logan-armstrong":
                return "logan-armstrong-hVhfqhDYciU-unsplash-edited-MOBILE-HEADER"
            case "stock-photo-skyline":
                return "stock-photo-skyline-of-paris-with-eiffel-tower-at-sunset-in-paris-france-eiffel-tower-is-one-of-the-most-752725282"
            default:
                return rawName
            }
        }
    }

    private struct RecommendedHousingMapView: View {
        let trip: Trip
        let spots: [HousingSpot]
        let avatarImages: [String]
        let onClose: () -> Void
        var showBackButton: Bool = true

        enum SheetState {
            case collapsed
            case partial
            case full
        }

        @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        )
        @State private var housingViewport: MapboxMaps.Viewport = .camera(center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), zoom: 10, bearing: 0, pitch: 0)
        @State private var hasAnimated = false
        @State private var tripCoordinate: CLLocationCoordinate2D? = nil
        @State private var currentDestination: String
        @State private var tripSearchText: String
        @StateObject private var tripLocationSearcher = TripLocationSearcher()
        @FocusState private var isTripSearchFocused: Bool
        @State private var globeTarget: CLLocationCoordinate2D? = nil
        @State private var globeZoom: Double = 0.8
        @State private var sheetState: SheetState = .partial
        @State private var sheetDrag: CGFloat = 0   // real-time drag offset for Liquid Glass-smooth tracking
        @State private var showFilterSheet = false
        @State private var selectedSpotForDetail: HousingSpot? = nil
        @State private var selectedPOI: TappedPOI? = nil
        
        // Filter states
        @State private var selectedHousingType: String = "All" // "All" | "Room" | "Entire place"
        @State private var budgetMinValue: Double = 0
        @State private var budgetMaxValue: Double = 2500 // range 0...2500, max shows "2500+"
        @State private var budgetMinInput: String = "0"
        @State private var budgetMaxInput: String = "2500"
        @FocusState private var minBudgetFocused: Bool
        @FocusState private var maxBudgetFocused: Bool
        @State private var selectedRatingFilters: Set<Int> = []
        @State private var availabilityFilterNow: Bool? = nil // nil = no filter, true = Now, false = Later
        @State private var selectedArrivalDate: Date? = nil // used when Later is selected
        
        // Type of housing: 3 options for horizontal segment
        private let housingTypeOptions: [(id: String, label: String)] = [
            ("All", "All types"),
            ("Room", "Room"),
            ("Entire place", "Entire place")
        ]
        
        private let priceOptionsWithEmoji: [(id: String, label: String, emoji: String)] = [
            ("All", "All prices", "💫"),
            ("$0-500", "Budget", "💚"),
            ("$500-1000", "Affordable", "💙"),
            ("$1000-1500", "Mid-range", "💜"),
            ("$1500+", "Premium", "💎")
        ]

        private var filteredSpots: [HousingSpot] {
            spots.filter { spot in
                // Type filter: All = all, Room = spot.type == "Room", Entire place = spot.type != "Room"
                let typeMatch: Bool
                switch selectedHousingType {
                case "All": typeMatch = true
                case "Room": typeMatch = spot.type == "Room"
                case "Entire place": typeMatch = spot.type != "Room"
                default: typeMatch = true
                }
                
                // Price filter: spot in [min, max] range
                let priceMatch = Double(spot.price) >= budgetMinValue && Double(spot.price) <= budgetMaxValue
                
                // Rating filter: if empty, show all; otherwise check if rating matches any selected
                let ratingMatch: Bool
                if selectedRatingFilters.isEmpty {
                    ratingMatch = true
                        } else {
                    ratingMatch = selectedRatingFilters.contains { minRating in
                        Int(spot.rating) >= minRating
                    }
                }
                
                // Availability filter: nil = all, true = Now only, false = Later (by selectedArrivalDate)
                let availabilityMatch: Bool
                switch availabilityFilterNow {
                case nil: availabilityMatch = true
                case true?: availabilityMatch = spot.isAvailableNow
                case false?:
                    let date = selectedArrivalDate ?? Date()
                    availabilityMatch = spot.availableDate != nil && spot.availableDate! <= date
                }
                
                return typeMatch && priceMatch && ratingMatch && availabilityMatch
            }
        }

        private var budgetChipText: String {
            let maxStr = Int(budgetMaxValue) >= 2500 ? "2500+ $CA" : "\(Int(budgetMaxValue)) $CA"
            return "\(Int(budgetMinValue)) - \(maxStr)"
        }

        init(trip: Trip, spots: [HousingSpot], avatarImages: [String], onClose: @escaping () -> Void, showBackButton: Bool = true) {
            self.trip = trip
            self.spots = spots
            self.avatarImages = avatarImages
            self.onClose = onClose
            self.showBackButton = showBackButton
            _currentDestination = State(initialValue: trip.destination)
            _tripSearchText = State(initialValue: trip.destination)
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Globe terrestre (vue complète du globe)
                    TripsGlobeView(
                        targetCoordinate: globeTarget,
                        targetZoom: globeZoom,
                        cities: [],
                        onCityTap: nil
                    )
                        .offset(y: -98)
                        .ignoresSafeArea()
                        .opacity(sheetState == .full ? 0 : 1)
                        .animation(.easeInOut(duration: 0.35), value: sheetState)

                    // Back button (only when not full screen list and showBackButton)
                    if showBackButton && sheetState != .full {
                        VStack {
                            HStack {
                                Button(action: onClose) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 36, height: 36)
                                        .background(Color.white.opacity(0.9), in: Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                                }
                                .buttonStyle(.plain)
                                Spacer()
            }
            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Trip search bar
                    VStack {
                        tripSearchBar
                            .padding(.horizontal, 20)
                            .padding(.top, max(0, geometry.safeAreaInsets.top - 64))
                        if !tripLocationSearcher.results.isEmpty && isTripSearchFocused {
                            tripSearchResults
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        Spacer()
                    }

                    // Bottom sheet or full list
                    VStack(spacing: 0) {
                        if sheetState == .full {
                            fullScreenList(geometry: geometry)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        } else if sheetState == .partial {
                            Spacer()
                            partialSheet(geometry: geometry)
                                .frame(maxHeight: geometry.size.height * 0.42)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: sheetState)

                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .sheet(item: $selectedSpotForDetail) { spot in
                HousingDetailSheet(spot: spot, onClose: { selectedSpotForDetail = nil })
            }
            .onAppear {
                if globeTarget == nil {
                    resolveTripCoordinate { coordinate in
                        globeTarget = coordinate
                        globeZoom = 0.9
                    }
                }
            }
        }

        private var togglePill: some View {
                            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    switch sheetState {
                    case .collapsed:
                        sheetState = .partial
                    case .partial:
                        sheetState = .collapsed
                    case .full:
                        sheetState = .partial
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: sheetState == .full ? "map.fill" : "list.bullet")
                        .font(.system(size: 14, weight: .semibold))
                    Text(sheetState == .full ? "Map" : "Show list")
                        .font(.app(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "222222"), in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .opacity(sheetState == .partial ? 0 : 1)
        }

        private var tripSearchBar: some View {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
                TextField("Search city or country", text: $tripSearchText)
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .focused($isTripSearchFocused)
                    .onChange(of: tripSearchText) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            currentDestination = trip.destination
                            tripCoordinate = nil
                            tripLocationSearcher.results = []
                            resolveTripCoordinate { coordinate in
                                applyTripViewport(coordinate: coordinate, zoomedOut: true)
                                globeTarget = coordinate
                                globeZoom = 0.9
                            }
                        } else {
                            tripLocationSearcher.search(query: newValue)
                        }
                    }
                Spacer()
                if !tripSearchText.isEmpty {
                    Button(action: {
                        tripSearchText = ""
                        tripLocationSearcher.results = []
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
                }
                .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .glassEffect(
                .regular.tint(.black),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        }

        private var tripSearchResults: some View {
                        VStack(spacing: 0) {
                ForEach(tripLocationSearcher.results, id: \.self) { result in
                                Button(action: {
                        let title = result.title
                        let subtitle = result.subtitle
                        let destination = subtitle.isEmpty ? title : "\(title), \(subtitle)"
                        currentDestination = destination
                        tripSearchText = destination
                        tripCoordinate = nil
                        resolveTripCoordinate { coordinate in
                            applyTripViewport(coordinate: coordinate, zoomedOut: true)
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tripLocationSearcher.results = []
                        }
                        isTripSearchFocused = false
                                }) {
                                    HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                                        VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                                .font(.app(size: 15, weight: .medium))
                                                .foregroundStyle(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.app(size: 12, weight: .medium))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                        .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
                                
                    if result != tripLocationSearcher.results.last {
                                    Divider()
                    }
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
        }

        private func partialSheet(geometry: GeometryProxy) -> some View {
            VStack(spacing: 0) {
                // Drag handle (Liquid Glass style)
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                // Dates + Filters on same line
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(tripDateLabel)
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showFilterSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Filters")
                                .font(.app(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                // Active filter chips (only if filters are applied)
                if selectedHousingType != "All" || budgetMinValue > 0 || budgetMaxValue < 2500 || !selectedRatingFilters.isEmpty || availabilityFilterNow != nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                            if selectedHousingType != "All" {
                                filterChip(text: selectedHousingType == "Room" ? "Room" : "Entire place", onRemove: { selectedHousingType = "All" })
                            }
                            if budgetMinValue > 0 || budgetMaxValue < 2500 {
                                filterChip(text: budgetChipText, onRemove: { budgetMinValue = 0; budgetMaxValue = 2500 })
                            }
                            ForEach(Array(selectedRatingFilters), id: \.self) { rating in
                                filterChip(text: "\(rating)+ ⭐", onRemove: { selectedRatingFilters.remove(rating) })
                            }
                            if availabilityFilterNow == true {
                                filterChip(text: "💃 Now", onRemove: { availabilityFilterNow = nil })
                            }
                            if availabilityFilterNow == false, let d = selectedArrivalDate {
                                filterChip(text: "🗓️ \(d.formatted(date: .abbreviated, time: .omitted))", onRemove: { availabilityFilterNow = nil; selectedArrivalDate = nil })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // List header
                HStack {
                    Text("Recommended Housing")
                        .font(.app(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            zoomOutToTrip()
                            sheetState = .full
                        }
                    }) {
                        Text("See all")
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                // List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredSpots) { spot in
                            recommendedHousingRow(spot: spot)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 220)
                .padding(.bottom, 20)
                    }
                }
            }
            .padding(.bottom, geometry.safeAreaInsets.bottom)
            .frame(maxWidth: .infinity)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .glassEffect(
                .regular.tint(.black),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: -6)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sheetDrag = value.translation.height
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                            sheetDrag = 0
                            if value.translation.height < -50 || velocity < -500 {
                                sheetState = .full
                            } else if (value.translation.height > 50 || velocity > 500) && sheetState == .full {
                                sheetState = .partial
                            }
                        }
                    }
            )
        }

        private func fullScreenList(geometry: GeometryProxy) -> some View {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            zoomInToTrip()
                            sheetState = .partial
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray6), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(tripTitle)
                        .font(.app(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray6), in: Circle())
                    }
                    .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Active filters
                if selectedHousingType != "All" || budgetMinValue > 0 || budgetMaxValue < 2500 || !selectedRatingFilters.isEmpty || availabilityFilterNow != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if selectedHousingType != "All" {
                                filterChip(text: selectedHousingType == "Room" ? "Room" : "Entire place", onRemove: { selectedHousingType = "All" })
                            }
                            if budgetMinValue > 0 || budgetMaxValue < 2500 {
                                filterChip(text: budgetChipText, onRemove: { budgetMinValue = 0; budgetMaxValue = 2500 })
                            }
                            ForEach(Array(selectedRatingFilters), id: \.self) { rating in
                                filterChip(text: "\(rating)+ ⭐", onRemove: { selectedRatingFilters.remove(rating) })
                            }
                            if availabilityFilterNow == true {
                                filterChip(text: "💃 Now", onRemove: { availabilityFilterNow = nil })
                            }
                            if availabilityFilterNow == false, let d = selectedArrivalDate {
                                filterChip(text: "🗓️ \(d.formatted(date: .abbreviated, time: .omitted))", onRemove: { availabilityFilterNow = nil; selectedArrivalDate = nil })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)
                }

                // Results count
                HStack {
                    Text("\(filteredSpots.count) results")
                        .font(.app(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Full list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredSpots) { spot in
                            recommendedHousingRow(spot: spot)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 100 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                sheetState = .partial
                            }
                        }
                    }
            )
        }

        private func filterChip(text: String, onRemove: @escaping () -> Void) -> some View {
            HStack(spacing: 6) {
                Text(text)
                    .font(.app(size: 13, weight: .semibold))
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.appAccent, in: Capsule())
        }

        private var filterSheet: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Type filter - Horizontal segment (3 options on one line)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("🏠")
                                    .font(.system(size: 22))
                                Text("Type of housing")
                                    .font(.app(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("What kind of place are you looking for?")
                                .font(.app(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 0) {
                                ForEach(housingTypeOptions, id: \.id) { option in
                                    let isSelected = selectedHousingType == option.id
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedHousingType = option.id
                                        }
                                    }) {
                                        Text(option.label)
                                            .font(.app(size: 14, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                isSelected ? Color.white : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .strokeBorder(
                                                        isSelected ? Color(hex: "222222") : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                            .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                                    if option.id != housingTypeOptions.last?.id {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 1)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            .padding(4)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
                            )
                        }

                        // Separator with style
                        HStack {
                            Rectangle()
                                .fill(Color(hex: "ebebeb"))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        // Price filter - Range slider with histogram + Min/Max pills
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("💰")
                                    .font(.system(size: 22))
                                Text("Monthly budget")
                                    .font(.app(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("Select your budget range")
                                .font(.app(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)

                            budgetRangeSliderWithHistogram
                        }
                        
                        // Separator
                        HStack {
                            Rectangle()
                                .fill(Color(hex: "ebebeb"))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)
                        
                        // Rating filter - Stars visual
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("⭐")
                                    .font(.system(size: 22))
                                Text("Minimum rating")
                                    .font(.app(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("Only show highly-rated places")
                                .font(.app(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // All option
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedRatingFilters.removeAll()
                                        }
                                    }) {
                                        VStack(spacing: 6) {
                                            Text("✨")
                                                .font(.system(size: 24))
                                            Text("All")
                                                .font(.app(size: 13, weight: .semibold))
                                        }
                                        .foregroundStyle(selectedRatingFilters.isEmpty ? .white : .primary)
                                        .frame(width: 60, height: 70)
                                        .background(
                                            selectedRatingFilters.isEmpty ? Color.appAccent : Color.white,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(
                                                    selectedRatingFilters.isEmpty ? Color.clear : Color(.systemGray5),
                                                    lineWidth: 1
                                                )
                                        )
                    }
                    .buttonStyle(.plain)
                                    
                                    ForEach(1...5, id: \.self) { rating in
                                        let isSelected = selectedRatingFilters.contains(rating)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if isSelected {
                                                    selectedRatingFilters.remove(rating)
                                                } else {
                                                    selectedRatingFilters.insert(rating)
                                                }
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                HStack(spacing: 2) {
                                                    ForEach(0..<rating, id: \.self) { _ in
                                                        Image(systemName: "star.fill")
                                                            .font(.system(size: rating > 3 ? 8 : 10))
                                                            .foregroundStyle(isSelected ? .white : .yellow)
                                                    }
                                                }
                                                Text("\(rating)+")
                                                    .font(.app(size: 13, weight: .semibold))
                                            }
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .frame(width: 60, height: 70)
                                            .background(
                                                isSelected ? Color.appAccent : Color.white,
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(
                                                        isSelected ? Color.clear : Color(.systemGray5),
                                                        lineWidth: 1
                                                    )
                                            )
                    }
                    .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Separator
                        HStack {
                            Rectangle()
                                .fill(Color(hex: "ebebeb"))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)
                        
                        // Availability filter - Now / Later
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("📅")
                                    .font(.system(size: 22))
                                Text("Availability")
                                    .font(.app(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("When do you need the place?")
                                .font(.app(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 10) {
                                // 💃 Now
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        availabilityFilterNow = true
                                        selectedArrivalDate = nil
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Text("💃")
                                            .font(.system(size: 20))
                                        Text("Now")
                                            .font(.app(size: 15, weight: .semibold))
                                            .foregroundStyle(availabilityFilterNow == true ? .white : .primary)
                                        Spacer()
                                        if availabilityFilterNow == true {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        availabilityFilterNow == true ? Color.appAccent : Color.white,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                availabilityFilterNow == true ? Color.clear : Color(.systemGray5),
                                                lineWidth: 1
                                            )
                                    )
                    }
                    .buttonStyle(.plain)
                                
                                // 🗓️ Later + date picker
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        availabilityFilterNow = false
                                        if selectedArrivalDate == nil { selectedArrivalDate = Date() }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Text("🗓️")
                                            .font(.system(size: 20))
                                        Text("Later")
                                            .font(.app(size: 15, weight: .semibold))
                                            .foregroundStyle(availabilityFilterNow == false ? .white : .primary)
                                        Spacer()
                                        if availabilityFilterNow == false {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        availabilityFilterNow == false ? Color.appAccent : Color.white,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                availabilityFilterNow == false ? Color.clear : Color(.systemGray5),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if availabilityFilterNow == false {
                                    DatePicker(
                                        "Choose date",
                                        selection: Binding(
                                            get: { selectedArrivalDate ?? Date() },
                                            set: { selectedArrivalDate = $0 }
                                        ),
                                        in: Date()...,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.graphical)
                                    .tint(Color.appAccent)
                .padding(.horizontal, 4)
        .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
        .background(Color(.systemBackground))
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()
                        Button(action: { showFilterSheet = false }) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Show \(filteredSpots.count) results")
                                    .font(.app(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "222222"), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .background(.ultraThinMaterial)
                }
                .navigationTitle("🔍 Find your place")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showFilterSheet = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedHousingType = "All"
                                budgetMinValue = 0
                                budgetMaxValue = 2500
                                selectedRatingFilters.removeAll()
                                availabilityFilterNow = nil
                                selectedArrivalDate = nil
                            }
                        }) {
                            Text("Reset")
                                .font(.app(size: 15, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        
        private let budgetRange: ClosedRange<Double> = 0...2500
        private let budgetStep: Double = 50
        
        private var budgetRangeSliderWithHistogram: some View {
            VStack(alignment: .leading, spacing: 4) {
                // Range slider with two thumbs (no histogram)
                BudgetRangeSliderView(
                    minValue: $budgetMinValue,
                    maxValue: $budgetMaxValue,
                    range: budgetRange,
                    step: budgetStep
                )
                .frame(height: 44)
                
                // Min / Max pills below – tappable, editable
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Minimum")
                            .font(.app(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        budgetPillField(
                            value: $budgetMinValue,
                            input: $budgetMinInput,
                            isFocused: $minBudgetFocused,
                            isMax: false
                        )
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Maximum")
                            .font(.app(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        budgetPillField(
                            value: $budgetMaxValue,
                            input: $budgetMaxInput,
                            isFocused: $maxBudgetFocused,
                            isMax: true
                        )
                    }
                }
            }
            .padding(.vertical, 0)
            .onChange(of: budgetMinValue) { _, newVal in
                if !minBudgetFocused { budgetMinInput = "\(Int(newVal))" }
            }
            .onChange(of: budgetMaxValue) { _, newVal in
                if !maxBudgetFocused { budgetMaxInput = "\(Int(newVal))" }
            }
        }
        
        private func budgetPillField(value: Binding<Double>, input: Binding<String>, isFocused: FocusState<Bool>.Binding, isMax: Bool) -> some View {
            ZStack(alignment: .leading) {
                if isFocused.wrappedValue {
                    HStack(spacing: 2) {
                        TextField("0", text: input)
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .keyboardType(.numberPad)
                            .focused(isFocused)
                            .frame(minWidth: 40)
                        Text("$CA")
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                } else {
                    Text("\(Int(value.wrappedValue))\(isMax && Int(value.wrappedValue) >= 2500 ? "+" : "") $CA")
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture { input.wrappedValue = "\(Int(value.wrappedValue))"; isFocused.wrappedValue = true }
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color(.systemGray5), lineWidth: 1))
            .onChange(of: input.wrappedValue) { _, newStr in
                let parsed = Int(newStr.filter { $0.isNumber })
                let clamped: Double
                if isMax {
                    let v = Double(min(max(parsed ?? 0, Int(budgetMinValue)), 2500))
                    value.wrappedValue = v
                } else {
                    let v = Double(max(min(parsed ?? 0, Int(budgetMaxValue)), 0))
                    value.wrappedValue = v
                }
            }
            .onSubmit { isFocused.wrappedValue = false }
        }
        
        // Keep old compatibility
        private var typeOptions: [String] { housingTypeOptions.map { $0.id } }
        private var priceOptions: [String] { priceOptionsWithEmoji.map { $0.id } }
        
        private func recommendedHousingRow(spot: HousingSpot) -> some View {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: spot.image)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.title)
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(spot.type)
                        .font(.app(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: -6) {
                    avatarStack(images: avatarImages)
                    Text("\(max(20, Int(spot.rating * 50)))+")
                        .font(.app(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6), in: Capsule())
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture {
                selectedSpotForDetail = spot
            }
        }

        private func avatarStack(images: [String]) -> some View {
            HStack(spacing: -8) {
                ForEach(Array(images.prefix(3).enumerated()), id: \.offset) { _, imageUrl in
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Color(.systemGray5)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
        }

        private var tripTitle: String {
            destinationParts.first ?? currentDestination
        }

        private var tripSubtitle: String {
            if destinationParts.count > 1 {
                return destinationParts[1]
            }
            return "Destination"
        }

        private var destinationParts: [String] {
            currentDestination.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        private var tripDateLabel: String {
            "\(shortDate(trip.startDate)) - \(shortDate(trip.endDate))"
        }

        private func shortDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }

        private func animateToTrip() {
            guard !hasAnimated else { return }
            hasAnimated = true

            resolveTripCoordinate { coordinate in
                applyTripViewport(coordinate: coordinate, zoomedOut: false)
            }
        }

        private func zoomOutToTrip() {
            resolveTripCoordinate { coordinate in
                applyTripViewport(coordinate: coordinate, zoomedOut: true)
            }
        }

        private func zoomInToTrip() {
            resolveTripCoordinate { coordinate in
                applyTripViewport(coordinate: coordinate, zoomedOut: false)
            }
        }

        private func resolveTripCoordinate(_ completion: @escaping (CLLocationCoordinate2D) -> Void) {
            if let cached = tripCoordinate {
                completion(cached)
                return
            }
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(currentDestination) { placemarks, _ in
                let coordinate = placemarks?.first?.location?.coordinate
                    ?? CLLocationCoordinate2D(latitude: -8.4095, longitude: 115.1889)
                tripCoordinate = coordinate
                completion(coordinate)
            }
        }

        private func applyTripViewport(coordinate: CLLocationCoordinate2D, zoomedOut: Bool) {
            let targetCenter = zoomedOut
                ? coordinate
                : CLLocationCoordinate2D(
                    latitude: coordinate.latitude - 0.035,
                    longitude: coordinate.longitude
                )
            let targetSpan = zoomedOut
                ? MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                : MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            withAnimation(.easeInOut(duration: 0.8)) {
                region.center = targetCenter
                region.span = targetSpan
            }
            syncHousingViewport(center: targetCenter, span: targetSpan, animated: true)
            globeTarget = coordinate
            globeZoom = zoomedOut ? 1.2 : 1.6
        }

        private func syncHousingViewport(animated: Bool) {
            syncHousingViewport(center: region.center, span: region.span, animated: animated)
        }

        private func syncHousingViewport(center: CLLocationCoordinate2D, span: MKCoordinateSpan, animated: Bool) {
        let nextViewport = MapboxMaps.Viewport.camera(
                center: center,
                zoom: mapboxZoom(from: span),
            bearing: 0,
            pitch: 0
        )
        if animated {
                withViewportAnimation(.default(maxDuration: 0.8)) {
                    housingViewport = nextViewport
            }
        } else {
                housingViewport = nextViewport
            }
        }
    }

    private func tabIcon(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "house.fill"
        case .roommates:
            return "person.2.fill"
        }
    }

    private func tabLabel(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "🏠 Housing"
        case .roommates:
            return "👋 Roommates"
        }
    }

    private struct HousingTabLabel: View {
        let text: String
        let isActive: Bool
        @State private var textWidth: CGFloat = 0

        var body: some View {
            VStack(spacing: 6) {
                Text(text)
                    .font(.app(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { textWidth = proxy.size.width }
                                .onChange(of: proxy.size.width) { _, newValue in
                                    textWidth = newValue
                                }
                        }
                    )

                Capsule()
                    .fill(isActive ? Color.appAccent : Color.clear)
                    .frame(width: textWidth, height: 3)
            }
            .padding(.bottom, 6)
        }
    }

    private var housingMapContent: some View {
        ZStack(alignment: .top) {
            MapboxMaps.MapReader { proxy in
                MapboxMaps.Map(initialViewport: MapboxMaps.Viewport.camera(center: mapRegion.center, zoom: mapboxZoom(from: mapRegion.span), bearing: 0, pitch: 0)) {
                    // POI layer: tous les POI (commercial, recreation, landmark, etc.) – pas de filtre pour ne rien exclure
                    MapboxMaps.SymbolLayer(id: "app-poi-commercial-recreation-landmark", source: "composite")
                        .sourceLayer("poi_label")
                        .textField(Exp(.get) { "name" })
                        .textSize(12)
                        .textColor(MapboxMaps.StyleColor(.darkGray))
                    MapboxMaps.ForEvery(mapItems) { item in
                        MapboxMaps.MapViewAnnotation(coordinate: item.coordinate) {
                            Button(action: {
                                if let spot = item.spot {
                                    selectedHousingSpot = spot
                                    selectedRoommate = nil
                                } else if let roommate = item.roommate {
                                    selectedRoommate = roommate
                                    selectedHousingSpot = nil
                                }
                            }) {
                        VStack(spacing: 4) {
                            Image(systemName: item.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Color.appAccent, in: Circle())
                            Text(item.title)
                                        .font(.app(size: 10, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white, in: Capsule())
                        }
                    }
                            .buttonStyle(.plain)
                }
                    }
                    MapboxMaps.TapInteraction { context in
                        handlePOITap(context: context, map: proxy.map)
                        return false
                    }
                }
                .mapStyle(MapboxMaps.MapStyle.appStyle)
                .ornamentOptions(MapboxMaps.OrnamentOptions(scaleBar: MapboxMaps.ScaleBarViewOptions(visibility: .hidden)))
                .ignoresSafeArea(edges: .bottom)
                .id(activeTab)
            }

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
        .sheet(item: $selectedPOI) { (poi: TappedPOI) in
            POIDetailSheetView(poi: poi, onDismiss: { selectedPOI = nil })
        }
    }

    private var mapFilters: [String] {
        switch activeTab {
        case .spots:
            return ["Studio", "Private room", "Entire place"]
        case .roommates:
            return ["Pet friendly", "Quiet", "Social"]
        }
    }
    
    private func handlePOITap(context: MapboxMaps.InteractionContext, map: MapboxMaps.MapboxMap?) {
        guard let map = map else { return }
        let options = MapboxMaps.RenderedQueryOptions(layerIds: ["app-poi-commercial-recreation-landmark"], filter: nil)
        _ = map.queryRenderedFeatures(with: context.point, options: options) { result in
            guard let features = try? result.get(),
                  let first = features.first(where: { $0.queriedFeature.sourceLayer == "poi_label" }) ?? features.first,
                  let poi = TappedPOI.from(queriedFeature: first) else { return }
            DispatchQueue.main.async {
                selectedPOI = poi
            }
        }
    }

    private func mapFilterChip(icon: String? = nil, text: String, isSelected: Bool = false) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
            Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
            }
            Text(text)
                .font(.app(size: 13, weight: .semibold))
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
        let spot: HousingSpot?
        let roommate: Roommate?
    }

    private var mapItems: [MapItem] {
        switch activeTab {
        case .spots:
            return housingSpots.map {
                MapItem(
                    id: "spot-\($0.id)",
                    title: $0.title,
                    coordinate: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng),
                    icon: "house.fill",
                    spot: $0,
                    roommate: nil
                )
            }
        case .roommates:
            return roommates.map {
                MapItem(
                    id: "roommate-\($0.id)",
                    title: $0.name,
                    coordinate: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng),
                    icon: "person.fill",
                    spot: nil,
                    roommate: $0
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
                .background(Color.white)
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
                                .font(.app(size: 12, weight: .semibold))
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
                .font(.app(size: 22, weight: .bold))
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
                .font(.app(size: 13, weight: .semibold))
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
                                    .font(.app(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Popular option")
                                    .font(.app(size: 12, weight: .medium))
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
                .font(.app(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            if activeTab == .roommates {
                Text("How many roommates?")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                chipGrid(options: roommatesRanges, selection: $selectedRoommatesRange, allowsMultiple: true)

                Text("Roommate preference")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                chipGrid(options: roommatesGenders, selection: $selectedRoommatesGender, allowsMultiple: true)
                } else {
                Text("Type of place")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                chipGrid(options: housingTypes, selection: $selectedWhat, allowsMultiple: true)
            }
        }
    }

    private var budgetStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Budget")
                .font(.app(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            chipGrid(options: budgetRanges, selection: $selectedBudget, allowsMultiple: true)
        }
    }

    private var actionBar: some View {
        HStack {
            Button(action: resetAll) {
                Text("Clear all")
                    .font(.app(size: 14, weight: .semibold))
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
                        .font(.app(size: 15, weight: .semibold))
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
            .font(.app(size: 12, weight: .semibold))
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
                        .font(.app(size: 14, weight: .semibold))
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
            return "Housing recommendations"
        case .roommates:
            return "Find roommates"
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
        }
    }
}

private struct CreateHousingListingView: View {
    @Binding var activeTab: HousingTab
    let coordinate: CLLocationCoordinate2D
    let onCreateSpot: (HousingSpot) -> Void
    let onCreateRoommate: (Roommate) -> Void
    let onClose: () -> Void

    @State private var selectedTab: HousingTab

    @State private var housingTitle = ""
    @State private var housingDescription = ""
    @State private var housingPrice = ""
    @State private var housingPeriod = ""
    @State private var housingType = "Apartment"
    @State private var housingRating: Int = 0
    @State private var housingAddress = ""
    @State private var housingAvailability: Date = Date()
    @State private var housingAvailabilityStatus: String? = nil
    @State private var selectedContactMethod: ContactMethod? = nil
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var housingBadgesSelected: Set<String> = []
    @State private var housingBadgesCustom = ""
    private let housingTypeOptions: [(value: String, label: String)] = [
        (value: "Apartment", label: "🏢 Apartment"),
        (value: "House", label: "🏠 House"),
        (value: "Student residence", label: "🎓 Student residence"),
        (value: "Room", label: "🛏️ Room")
    ]
    @StateObject private var addressSearchCompleter: AddressSearchCompleter
    @FocusState private var addressFieldFocused: Bool

    @State private var roommateName = ""
    @State private var roommateAge = ""
    @State private var roommateBudget = ""
    @State private var roommateLocation = ""
    @State private var roommateMoveIn = ""
    @State private var roommateTags = ""
    @State private var currentStep = 0
    @State private var housingWelcomeRegion: MKCoordinateRegion

    private enum ContactMethod {
        case phone
        case email
    }

    init(
        activeTab: Binding<HousingTab>,
        coordinate: CLLocationCoordinate2D,
        onCreateSpot: @escaping (HousingSpot) -> Void,
        onCreateRoommate: @escaping (Roommate) -> Void,
        onClose: @escaping () -> Void
    ) {
        _activeTab = activeTab
        _selectedTab = State(initialValue: activeTab.wrappedValue)
        _addressSearchCompleter = StateObject(wrappedValue: AddressSearchCompleter(center: coordinate))
        _housingWelcomeRegion = State(initialValue: MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)))
        self.coordinate = coordinate
        self.onCreateSpot = onCreateSpot
        self.onCreateRoommate = onCreateRoommate
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if selectedTab == .spots && currentStep == 0 {
                    // First step: full-screen "Create nearby" style (map + type cards + Continue)
                    housingWelcomeStepContent
            } else {
                    VStack(spacing: 0) {
                        closeButton

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    formContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                            .id(currentStep)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentStep)
                        }
                        .background(Color.white)

                        actionBar
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                closeButtonOverlay
            }
            .navigationBarHidden(true)
        }
    }

    private var closeButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedTab == .spots ? "New housing recommendation" : "Find roommates")
                        .font(.app(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                }
                .padding(.top, 12)

            Spacer()
            }
            
            HStack(alignment: .center, spacing: 10) {
                stepIndicator
            }
        }
                    .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, 6)
    }

    private var closeButtonOverlay: some View {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                .background(Color(.systemGray5), in: Circle())
            }
            .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.trailing, 20)
    }

    // MARK: - First step: "Add housing tip" (map with blur + example listings ranking + Continue)
    private static let welcomeExampleListings: [(title: String, price: Int, type: String, rank: Int)] = [
        ("Sunny Studio in Plateau", 1200, "Apartment", 1),
        ("Cozy room near metro", 650, "Room", 2),
        ("Loft with terrace", 1850, "Apartment", 3)
    ]

    private var housingWelcomeStepContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Title & subtitle – centered
                    VStack(spacing: 8) {
                        Text("Add housing tip 🌎")
                            .font(.app(size: 24, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        Text("Recommend a place to stay. This will help other travelers to find the perfect place; Thank you!")
                            .font(.app(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 72)
                    .padding(.bottom, 20)

                    // Mapbox map with blur/fade at edges + user location (blue circle)
                    ZStack(alignment: .center) {
                        MapboxMaps.Map(initialViewport: MapboxMaps.Viewport.camera(center: housingWelcomeRegion.center, zoom: 12, bearing: 0, pitch: 0)) {
                            MapboxMaps.SymbolLayer(id: "app-poi-welcome", source: "composite")
                                .sourceLayer("poi_label")
                                .textField(Exp(.get) { "name" })
                                .textSize(12)
                                .textColor(MapboxMaps.StyleColor(.darkGray))
                        }
                            .mapStyle(MapboxMaps.MapStyle.appStyle)
                            .ornamentOptions(MapboxMaps.OrnamentOptions(scaleBar: MapboxMaps.ScaleBarViewOptions(visibility: .hidden)))
                            .frame(height: 220)
                            .allowsHitTesting(false)
                        // Fade at edges: vertical gradient
                        VStack(spacing: 0) {
                            LinearGradient(colors: [Color.white.opacity(0.92), Color.clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 50)
                            Spacer()
                            LinearGradient(colors: [Color.clear, Color.white.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                                .frame(height: 50)
                        }
                        .allowsHitTesting(false)
                        // Fade at edges: horizontal gradient
                        HStack(spacing: 0) {
                            LinearGradient(colors: [Color.white.opacity(0.88), Color.clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 40)
                            Spacer()
                            LinearGradient(colors: [Color.clear, Color.white.opacity(0.88)], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 40)
                        }
                        .allowsHitTesting(false)
                        // User location pin
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(Color.blue.opacity(0.25))
                                .frame(width: 44, height: 44)
                            Circle()
                                .strokeBorder(Color.blue, lineWidth: 2)
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // Example housing listings (ranking: different sizes + perspective, non-selectable)
                    housingWelcomeExampleListingsStack
                        .padding(.top, 28)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
            .background(Color.white)

            // Continue button
            Button(action: nextStep) {
                Text("Continue")
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 34)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var housingWelcomeExampleListingsStack: some View {
        ZStack(alignment: .bottom) {
            // Escalier: 3e (plus étroit, derrière) → 2e → 1er (plus large, premier plan). Le 2e dépasse pour que son texte soit lisible.
            ForEach(Array(Self.welcomeExampleListings.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let item = pair.element
                // 1er plan = plus large (1.0), 2e = 0.92, 3e = 0.84
                let scale: CGFloat = index == 0 ? 1.0 : (index == 1 ? 0.92 : 0.84)
                // Décalage vers le haut : 2e carte bien visible (texte lisible), 3e reste en retrait
                let yOffset: CGFloat = index == 0 ? 0 : (index == 1 ? -58 : -28)
                housingWelcomeExampleCard(title: item.title, price: item.price, type: item.type, rank: item.rank)
                    .scaleEffect(scale)
                    .offset(y: yOffset)
                    .zIndex(Double(2 - index)) // index 0 devant (zIndex 2), index 2 derrière (zIndex 0)
            }
        }
        .frame(height: 210)
    }

    private func housingWelcomeExampleCard(title: String, price: Int, type: String, rank: Int) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(rank == 1 ? "🏠" : (rank == 2 ? "🛏️" : "✨"))
                        .font(.system(size: 24))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("$\(price)/mo · \(type)")
                    .font(.app(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("#\(rank)")
                .font(.app(size: 12, weight: .bold))
                .foregroundStyle(Color.appAccent)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    @ViewBuilder
    private var formContent: some View {
        switch selectedTab {
        case .spots:
            housingForm
        case .roommates:
            roommatesForm
        }
    }

    private var housingForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch currentStep {
            case 0:
                EmptyView() // Step 0 = welcome (map + cards), shown in housingWelcomeStepContent
            case 1:
                VStack(spacing: 18) {
                    housingBasicsFields
                }
            case 2:
                housingDetailsFields
            default:
                housingExtrasFields
            }
        }
    }

    private var roommatesForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch currentStep {
            case 0:
                VStack(spacing: 18) {
                    roommateBasicsFields
                }
            default:
                roommateExtrasFields
            }
        }
    }

    @ViewBuilder
    private var housingBasicsFields: some View {
        formFieldSection(icon: "pencil.line", title: "Title") {
            styledTextField("Give your place a name", text: $housingTitle)
        }

        formFieldSection(icon: "dollarsign.circle.fill", title: "Price") {
            HStack(spacing: 12) {
                    HStack(spacing: 8) {
                    Text("$")
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    TextField("0", text: $housingPrice)
                        .keyboardType(.numberPad)
                        .font(.app(size: 16, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6).opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(maxWidth: .infinity)

                Text("/")
                    .font(.app(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)

                periodPicker
            }
        }

        formFieldSection(icon: "building.2.fill", title: "Type of place") {
            styledPicker(selection: $housingType, options: housingTypeOptions)
        }

        formFieldSection(icon: "mappin.and.ellipse", title: "Location") {
            addressAutocompleteField
        }
    }

    private func formFieldSection<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            content()
        }
    }

    private func styledTextField(
        _ placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .font(.app(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6).opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func styledPicker(
        selection: Binding<String>,
        options: [(value: String, label: String)]
    ) -> some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button(action: { selection.wrappedValue = option.value }) {
                    HStack {
                        Text(option.label)
                        if selection.wrappedValue == option.value {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            let selectedLabel = options.first(where: { $0.value == selection.wrappedValue })?.label ?? selection.wrappedValue
            HStack {
                Text(selectedLabel.isEmpty ? "Select type" : selectedLabel)
                    .font(.app(size: 16, weight: .medium))
                    .foregroundStyle(selectedLabel.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6).opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var housingDetailsFields: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rating")
                    .font(.app(size: 19, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
            Button(action: {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    housingRating = star
                                }
                            }) {
                                Image(systemName: star <= housingRating ? "star.fill" : "star")
                                    .font(.system(size: 28, weight: .regular))
                                    .foregroundStyle(star <= housingRating ? .yellow : Color(.systemGray4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    if housingRating > 0 {
                        Text(ratingEmoji(for: housingRating))
                            .font(.system(size: 26))
                    }
                }
            }

            contactMethodSection

            VStack(alignment: .leading, spacing: 12) {
                Text("Next availability")
                    .font(.app(size: 19, weight: .semibold))
                    .foregroundStyle(.black)

                HStack(spacing: 14) {
                    ForEach(["Currently living here", "Already left"], id: \.self) { status in
        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                housingAvailabilityStatus = (housingAvailabilityStatus == status) ? nil : status
                            }
                        }) {
                            Text(status)
                                .font(.app(size: 13, weight: .medium))
                                .foregroundStyle(housingAvailabilityStatus == status ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    housingAvailabilityStatus == status ? Color.appAccent : Color(.systemGray6),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if housingAvailabilityStatus == "Currently living here" {
                    HStack {
                        Text("Leaving on")
                            .font(.app(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)

                        Spacer()

                        DatePicker("", selection: $housingAvailability, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
                            .tint(Color.appAccent)
                    }
                } else if housingAvailabilityStatus == "Already left" {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                        Text("Available now")
                            .font(.app(size: 14, weight: .medium))
                            .foregroundStyle(.green)
                        Spacer()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var housingExtrasFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.app(size: 19, weight: .semibold))
                .foregroundStyle(.black)
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
                    Text("Describe your experience")
                        .font(.app(size: 13, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
            }

        VStack(alignment: .leading, spacing: 8) {
            Text("Photos")
                .font(.app(size: 19, weight: .semibold))
                .foregroundStyle(.black)

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: 10,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                    Text(selectedImages.isEmpty ? "Select photos" : "\(selectedImages.count) photo\(selectedImages.count > 1 ? "s" : "") selected")
                        .font(.app(size: 15, weight: .medium))
                        .foregroundStyle(selectedImages.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
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
        .buttonStyle(.plain)
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task {
                    selectedImages.removeAll()
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                }
            }

            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Button(action: {
                                    selectedImages.remove(at: index)
                                    if index < selectedPhotoItems.count {
                                        selectedPhotoItems.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white, Color.black.opacity(0.6))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }

            VStack(alignment: .leading, spacing: 8) {
                Text("Badges")
                .font(.app(size: 19, weight: .semibold))
                .foregroundStyle(.black)
            
            // Display custom badges (not in predefined options) that are selected
            if !selectedCustomBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedCustomBadges, id: \.self) { badge in
                            HStack(spacing: 6) {
                                Text("✨ \(badge)")
                                    .font(.app(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        _ = housingBadgesSelected.remove(badge)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appAccent, in: Capsule())
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            
            badgeQuinconceScroll(options: housingBadgeOptions, selection: $housingBadgesSelected)
            formTextField("Add custom badge", text: $housingBadgesCustom)
            badgeSuggestionRow
        }
    }

    private var addressAutocompleteField: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("Address", text: $housingAddress)
                    .focused($addressFieldFocused)
                    .onChange(of: housingAddress) { _, newValue in
                        addressSearchCompleter.search(query: newValue)
                    }

                if !housingAddress.isEmpty {
                    Button(action: {
                        housingAddress = ""
                        addressSearchCompleter.clear()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            )

            if addressFieldFocused && !addressSearchCompleter.results.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(addressSearchCompleter.results, id: \.self) { suggestion in
                            Button(action: {
                                let title = suggestion.title
                                let subtitle = suggestion.subtitle
                                housingAddress = subtitle.isEmpty ? title : "\(title), \(subtitle)"
                                addressSearchCompleter.clear()
                                addressFieldFocused = false
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.appAccent)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                            .font(.app(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.app(size: 12, weight: .regular))
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white)
                            }
                            .buttonStyle(.plain)

                            if suggestion != addressSearchCompleter.results.last {
                                Divider()
                                    .padding(.leading, 38)
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                .padding(.top, 56)
            }
        }
    }

    private var contactMethodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to contact the owner")
                .font(.app(size: 19, weight: .semibold))
                .foregroundStyle(.black)

            VStack(spacing: 10) {
                contactOptionRow(
                    emoji: "📞",
                    title: "Phone number",
                    method: .phone,
                    text: $contactPhone
                )
                contactOptionRow(
                    emoji: "✉️",
                    title: "Email address",
                    method: .email,
                    text: $contactEmail
                )
            }
        }
    }

    private func contactOptionRow(
        emoji: String,
        title: String,
        method: ContactMethod,
        text: Binding<String>
    ) -> some View {
        let isSelected = selectedContactMethod == method

        return HStack(spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedContactMethod = isSelected ? nil : method
                }
            }) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.appAccent.opacity(0.2) : Color(.systemGray6), in: Circle())
            }
            .buttonStyle(.plain)

            TextField(title, text: text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )

            Spacer()
        }
    }

    private var hasContactInfo: Bool {
        let phone = contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return !phone.isEmpty || !email.isEmpty
    }

    private var badgeSuggestion: (title: String, emoji: String)? {
        let trimmed = housingBadgesCustom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()

        if lower.contains("furnish") {
            return (title: "Furnished", emoji: "🛋️")
        }
        if lower.contains("metro") || lower.contains("subway") {
            return (title: "Near metro", emoji: "🚇")
        }
        if lower.contains("utilit") || lower.contains("bill") {
            return (title: "Utilities included", emoji: "💡")
        }
        if lower.contains("pet") {
            return (title: "Pet friendly", emoji: "🐾")
        }
        if lower.contains("quiet") || lower.contains("calm") {
            return (title: "Quiet", emoji: "🤫")
        }
        if lower.contains("balcony") || lower.contains("terrace") {
            return (title: "Balcony", emoji: "🌿")
        }
        if lower.contains("wifi") || lower.contains("internet") {
            return (title: "Wi‑Fi", emoji: "📶")
        }
        if lower.contains("parking") {
            return (title: "Parking", emoji: "🅿️")
        }
        if lower.contains("gym") {
            return (title: "Gym", emoji: "🏋️")
        }
        if lower.contains("view") {
            return (title: "Great view", emoji: "🌅")
        }

        let titled = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        return (title: titled, emoji: "✨")
    }

    private var badgeSuggestionRow: some View {
        Group {
            if let suggestion = badgeSuggestion,
               !housingBadgesSelected.contains(suggestion.title) {
                HStack(spacing: 10) {
                    Text("\(suggestion.emoji) \(suggestion.title)")
                        .font(.app(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6), in: Capsule())

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            housingBadgesSelected.insert(suggestion.title)
                            housingBadgesCustom = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                    }

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var roommateBasicsFields: some View {
            formTextField("Name", text: $roommateName)
            HStack(spacing: 12) {
                formTextField("Age", text: $roommateAge, keyboard: .numberPad)
                formTextField("Budget", text: $roommateBudget, keyboard: .numberPad)
            }
            formTextField("Location", text: $roommateLocation)
    }

    @ViewBuilder
    private var roommateExtrasFields: some View {
            formTextField("Move-in date", text: $roommateMoveIn)
            formTextField("Tags (comma separated)", text: $roommateTags)
        }

    private var totalSteps: Int {
        selectedTab == .spots ? 4 : 2
    }

    private var stepTitles: [String] {
        selectedTab == .spots
            ? ["📍 Area & type", "🏠 Basics", "⭐ Details", "📸 Media & badges"]
            : ["👋 Basics", "📅 Move-in & tags"]
    }

    private var stepSubtitles: [String] {
        selectedTab == .spots
            ? [
                "Choose your area and type of place.",
                "Just the essentials to start.",
                "Add trust & availability details.",
                "Make it shine with photos."
            ]
            : [
                "Quick profile essentials.",
                "Timing and tags to match."
            ]
    }

    private var stepTitle: String {
        stepTitles[min(currentStep, stepTitles.count - 1)]
    }

    private var stepSubtitle: String {
        stepSubtitles[min(currentStep, stepSubtitles.count - 1)]
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.appAccent : Color.black.opacity(0.1))
                    .frame(width: index == currentStep ? 28 : 12, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var isLastStep: Bool {
        currentStep >= totalSteps - 1
    }

    private var canProceedCurrentStep: Bool {
        if isLastStep {
            return canPublish
        }
        return canAdvance
    }

    private var canAdvance: Bool {
        switch selectedTab {
        case .spots:
            if currentStep == 0 {
                return true // Welcome step: Continue always enabled
            }
            if currentStep == 1 {
                return !housingTitle.isEmpty
                    && Int(housingPrice) != nil
                    && !housingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if currentStep == 2 {
                return housingRating > 0
                    && hasContactInfo
                    && housingAvailabilityStatus != nil
            }
            if currentStep == 3 {
                return !housingDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !selectedImages.isEmpty
                    && !housingBadgesSelected.isEmpty
            }
            return true
        case .roommates:
            if currentStep == 0 {
                return !roommateName.isEmpty && Int(roommateAge) != nil && Int(roommateBudget) != nil && !roommateLocation.isEmpty
            }
            if currentStep == 1 {
                return !roommateMoveIn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !roommateTags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        }
    }

    private func nextStep() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func previousStep() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep = max(currentStep - 1, 0)
        }
    }


    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: previousStep) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Back")
                        .font(.app(size: 14, weight: .semibold))
                }
                            .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.7), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(currentStep == 0)
            .opacity(currentStep == 0 ? 0 : 1)

            Spacer()

                    Button(action: {
                if isLastStep {
                    handleCreate()
                } else {
                    nextStep()
                }
            }) {
                HStack(spacing: 8) {
                    Text(isLastStep ? "Publish" : "Next")
                            .font(.app(size: 16, weight: .semibold))
                    Image(systemName: isLastStep ? "checkmark" : "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                            .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    canProceedCurrentStep ? Color.appAccent : Color(.systemGray5),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
            .disabled(!canProceedCurrentStep)
                    }
                    .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.black.opacity(0.06)),
            alignment: .top
        )
    }

    private var canPublish: Bool {
        switch selectedTab {
        case .spots:
            return !housingTitle.isEmpty
                && Int(housingPrice) != nil
                && !housingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && housingRating > 0
                && hasContactInfo
                && housingAvailabilityStatus != nil
                && !housingDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !selectedImages.isEmpty
                && !housingBadgesSelected.isEmpty
        case .roommates:
            return !roommateName.isEmpty && Int(roommateAge) != nil && Int(roommateBudget) != nil && !roommateLocation.isEmpty
                && !roommateMoveIn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !roommateTags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func handleCreate() {
        switch selectedTab {
        case .spots:
            let trimmedAddress = housingAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            let addressValue = trimmedAddress.isEmpty ? nil : trimmedAddress
            let contactValue: String? = {
                let phone = contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
                if !phone.isEmpty {
                    return phone
                }
                let email = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                return email.isEmpty ? nil : email
            }()
            let isAvailableNow = housingAvailabilityStatus != "Currently living here"
            let availableDate = housingAvailabilityStatus == "Currently living here" ? housingAvailability : nil

            let customBadges = housingBadgesCustom
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let allBadges = Array(housingBadgesSelected) + customBadges
            // Note: In a production app, selected images would be uploaded to a server
            // For now, using placeholder URLs
            let photos = selectedImages.isEmpty
                ? ["https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80"]
                : selectedImages.enumerated().map { index, _ in
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80&v=\(index)"
                }
            let spot = HousingSpot(
                id: Int(Date().timeIntervalSince1970),
                title: housingTitle,
                description: housingDescription.isEmpty ? "No description yet." : housingDescription,
                price: Int(housingPrice) ?? 0,
                currency: "$",
                period: housingPeriod.isEmpty ? "mo" : housingPeriod,
                image: photos.first ?? "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80",
                photos: photos,
                badges: allBadges.isEmpty ? ["Furnished", "Near metro"] : allBadges,
                rating: 4.8,
                recommender: "You",
                recommenderImg: "https://i.pravatar.cc/150?u=you",
                lat: coordinate.latitude,
                lng: coordinate.longitude,
                type: housingType,
                address: addressValue,
                contact: contactValue,
                availableDate: availableDate,
                isAvailableNow: isAvailableNow
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
        }
        onClose()
    }

    private func tabLabel(for tab: HousingTab) -> String {
        switch tab {
        case .spots:
            return "Housing recommendations"
        case .roommates:
            return "Find roommates"
        }
    }

    private func ratingLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }

    private func ratingEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😡"
        case 2: return "😕"
        case 3: return "🙂"
        case 4: return "😄"
        case 5: return "🤩"
        default: return ""
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

    private func formPicker(_ title: String, selection: Binding<String>, options: [(value: String, label: String)]) -> some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button(option.label) { selection.wrappedValue = option.value }
            }
        } label: {
            let selectedLabel = options.first(where: { $0.value == selection.wrappedValue })?.label ?? selection.wrappedValue
            HStack(spacing: 6) {
                Text("\(title):")
                    .foregroundStyle(.black)
                Text(selectedLabel)
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
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

    private var periodPicker: some View {
        Menu {
            ForEach(["mo", "week", "day"], id: \.self) { option in
                Button(option) { housingPeriod = option }
            }
        } label: {
            HStack(spacing: 6) {
                Text(housingPeriod.isEmpty ? "mo" : housingPeriod)
                    .font(.app(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6).opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var housingBadgeOptions: [String] {
        [
            "Furnished", "Near metro", "Utilities included", "Pet friendly", "Quiet", "Balcony",
            "Great view", "Parking", "Wi‑Fi", "Washing machine", "Air conditioning", "Garden",
            "Pool", "Workspace"
        ]
    }
    
    private var selectedCustomBadges: [String] {
        Array(housingBadgesSelected).filter { !housingBadgeOptions.contains($0) }.sorted()
    }

    private func badgeQuinconceScroll(options: [String], selection: Binding<Set<String>>) -> some View {
        let rowSpacing: CGFloat = 10
        let itemSpacing: CGFloat = 10
        
        let row0 = options.enumerated().filter { $0.offset % 3 == 0 }.map(\.element)
        let row1 = options.enumerated().filter { $0.offset % 3 == 1 }.map(\.element)
        let row2 = options.enumerated().filter { $0.offset % 3 == 2 }.map(\.element)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: rowSpacing) {
                HStack(spacing: itemSpacing) {
                    ForEach(row0, id: \.self) { option in
                        badgeChip(option: option, selection: selection)
                    }
                }
                HStack(spacing: itemSpacing) {
                    ForEach(row1, id: \.self) { option in
                        badgeChip(option: option, selection: selection)
                    }
                }
                HStack(spacing: itemSpacing) {
                    ForEach(row2, id: \.self) { option in
                        badgeChip(option: option, selection: selection)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .frame(height: 3 * (44 + rowSpacing) - rowSpacing)
    }
    
    private func badgeChip(option: String, selection: Binding<Set<String>>) -> some View {
        Button(action: {
                    if selection.wrappedValue.contains(option) {
                        selection.wrappedValue.remove(option)
                    } else {
                        selection.wrappedValue.insert(option)
                    }
                }) {
            Text(badgeDisplayText(option))
                .font(.app(size: 13, weight: .semibold))
                        .foregroundStyle(selection.wrappedValue.contains(option) ? .white : .primary)
                .lineLimit(1)
                .padding(.horizontal, 14)
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

    
    private func housingSpotCard(spot: HousingSpot) -> some View {
        let featureLine = ([spot.type] + Array(spot.badges.prefix(2))).joined(separator: " • ")
        return Button(action: {
            selectedHousingSpot = spot
            selectedRoommate = nil
        }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
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
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("Traveler favorite")
                        .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .padding(12)
                }
                .overlay(alignment: .bottom) {
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { index in
                        Circle()
                                .fill(index == 0 ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 10)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.title)
                            .font(.app(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(featureLine)
                            .font(.app(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                }
                
                Spacer()
                
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", spot.rating))
                            .font(.app(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }

                Text(spot.description)
                    .font(.app(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                            .lineLimit(2)
                        
                HStack(spacing: 6) {
                            Text("\(spot.currency)\(spot.price)")
                        .font(.app(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                            Text("/\(spot.period)")
                    .font(.app(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func roommateCard(roommate: Roommate) -> some View {
        Button(action: {
            selectedRoommate = roommate
            selectedHousingSpot = nil
        }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    AsyncImage(url: URL(string: roommate.image)) { phase in
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
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("Roommate request")
                        .font(.app(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .padding(12)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(roommate.name), \(roommate.age)")
                            .font(.app(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                            Text(roommate.location)
                                .font(.app(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Text("Move in \(roommate.moveIn)")
                        .font(.app(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.appAccent.opacity(0.12), in: Capsule())
                }

                if !roommate.tags.isEmpty {
                        HStack(spacing: 6) {
                        ForEach(roommate.tags.prefix(3), id: \.self) { tag in
                            cardTag(text: tag)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func cardTag(text: String) -> some View {
        Text(text)
            .font(.app(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray6), in: Capsule())
                            }
    
}

// MARK: - Budget Range Slider (two thumbs, track colored between)
private struct BudgetRangeSliderView: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    let step: Double
    
    @State private var dragStartMin: Double?
    @State private var dragStartMax: Double?
    
    private let thumbSize: CGFloat = 24
    private let trackHeight: CGFloat = 2
    
    private var rangeWidth: Double { range.upperBound - range.lowerBound }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let usable = w - thumbSize
            let minX = valueToX(minValue, width: w)
            let maxX = valueToX(maxValue, width: w)
            ZStack(alignment: .leading) {
                // Background track (light gray)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: trackHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, thumbSize / 2)
                
                // Active segment (red/pink between thumbs)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.appAccent)
                    .frame(width: max(0, maxX - minX), height: trackHeight)
                    .offset(x: thumbSize / 2 + minX)
                
                // Min thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .offset(x: minX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                if dragStartMin == nil { dragStartMin = minValue }
                                let deltaVal = Double(g.translation.width / usable) * rangeWidth
                                let newVal = (dragStartMin ?? minValue) + deltaVal
                                minValue = min(max(range.lowerBound, newVal.rounded(to: step)), maxValue - step)
                            }
                            .onEnded { _ in dragStartMin = nil }
                    )
                
                // Max thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .offset(x: maxX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                if dragStartMax == nil { dragStartMax = maxValue }
                                let deltaVal = Double(g.translation.width / usable) * rangeWidth
                                let newVal = (dragStartMax ?? maxValue) + deltaVal
                                maxValue = max(min(range.upperBound, newVal.rounded(to: step)), minValue + step)
                            }
                            .onEnded { _ in dragStartMax = nil }
                    )
            }
            .frame(height: thumbSize)
        }
    }
    
    private func valueToX(_ value: Double, width: CGFloat) -> CGFloat {
        let usable = width - thumbSize
        return CGFloat((value - range.lowerBound) / rangeWidth) * usable
    }
}

private extension Double {
    func rounded(to step: Double) -> Double {
        (self / step).rounded() * step
    }
}

// MARK: - Housing Detail Sheet (preview en bas → plein écran au drag)
private struct HousingDetailSheet: View {
    let spot: HousingSpot
    let onClose: () -> Void

    private static let previewDetent = PresentationDetent.fraction(0.48)

    @State private var showPhotoGallery = false
    @State private var selectedPhotoIndex = 0
    @State private var selectedDetent: PresentationDetent = previewDetent

    var body: some View {
        Group {
            if selectedDetent == Self.previewDetent {
                spotPreviewContent
            } else {
                spotFullContent
            }
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([Self.previewDetent, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .sheet(isPresented: $showPhotoGallery) {
            PhotoGalleryView(photos: spot.photos.isEmpty ? [spot.image] : spot.photos, selectedIndex: $selectedPhotoIndex)
        }
    }

    /// Vue compacte : header, actions, infos clés, galerie avec overlay
    private var spotPreviewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header : Share | Nom + Catégorie | Close
                HStack {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(spacing: 2) {
                        Text(spot.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(spot.type)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Boutons d'action : temps trajet | Appeler | Site web
                HStack(spacing: 12) {
                    actionButton(icon: "tram.fill", label: "7 min")
                    actionButton(icon: "phone.fill", label: "Appeler")
                    actionButton(icon: "safari", label: "Site web")
                }
                .padding(.horizontal, 20)

                // Infos clés : Horaires | Notes | Distance
                HStack(spacing: 16) {
                    infoBlock(label: "Horaires", value: spot.isAvailableNow ? "Ouvert" : "Fermé", valueColor: spot.isAvailableNow ? .primary : .red)
                    infoBlock(label: "\(Int(spot.rating * 20)) notes", value: "\(Int(spot.rating * 20)) %", valueColor: .primary, icon: "hand.thumbsup.fill")
                    infoBlock(label: "Distance", value: "—", valueColor: .primary, icon: "figure.walk")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)

                // Galerie images
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array((spot.photos.isEmpty ? [spot.image] : spot.photos).prefix(4).enumerated()), id: \.offset) { idx, url in
                            Button(action: { selectedPhotoIndex = idx; showPhotoGallery = true }) {
                                AsyncImage(url: URL(string: url)) { phase in
                                    if let img = phase.image {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Color(.systemGray5)
                                    }
                                }
                                .frame(width: 160, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 120)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func actionButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func infoBlock(label: String, value: String, valueColor: Color, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 12, weight: .semibold)) }
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(valueColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Vue plein écran : hero + contenu détaillé
    private var spotFullContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroImageSection(width: geometry.size.width)
                            .onTapGesture {
                                selectedPhotoIndex = 0
                                showPhotoGallery = true
                            }

                        contentCard
                            .offset(y: -28)
                    }
                }
                .ignoresSafeArea(edges: .top)

                bottomBar
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 34, height: 34)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
        }
    }
    
    private func heroImageSection(width: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
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
            .frame(width: width, height: 320)
            .clipped()
            
            Text("\(max(1, spot.photos.count))/\(max(1, spot.photos.count))")
                .font(.app(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6), in: Capsule())
                .padding(16)
        }
    }
    
    private var contentCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                titleSection
                divider
                statsRow
                divider
                recommenderSection
                divider
                featuredBadgeSection
                descriptionSection
                featuresSection
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 18, y: -6)
    }
    
    private var titleSection: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                Text("🏠")
                    .font(.system(size: 18))
                Text(spot.title)
                    .font(.app(size: 22, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Text("\(spot.type) · \(spot.address ?? "Location")")
                .font(.app(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if !spot.badges.isEmpty {
                Text(spot.badges.prefix(3).joined(separator: " · "))
                    .font(.app(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            // Rating section - centered in left half
            VStack(spacing: 4) {
                Text(String(format: "%.1f", spot.rating))
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < Int(spot.rating) ? "star.fill" : "star")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 1, height: 44)
            
            // Traveler favorite section - centered in right half
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("🏆")
                        .font(.system(size: 14))
                    Text("Traveler")
                        .font(.app(size: 11, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("🏆")
                        .font(.system(size: 14))
                }
                Text("favorite")
                    .font(.app(size: 11, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
    
    private var recommenderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended by")
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.black)
            
            HStack(spacing: 12) {
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
                .frame(width: 46, height: 46)
                        .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended by: \(spot.recommender)")
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                    HStack(spacing: 6) {
                        Text("✓")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(4)
                            .background(Color.green.opacity(0.15), in: Circle())
                        Text("Verified member")
                            .font(.app(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 16)
    }
    
    private var featuredBadgeSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("🏆")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 6) {
                Text("This home is a traveler favorite")
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                Text("Highly rated for comfort, cleanliness, and location.")
                    .font(.app(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About this place")
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.black)
            Text(spot.description)
                .font(.app(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What this place offers")
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.black)
            
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(spot.badges, id: \.self) { badge in
                    Text(badgeDisplayText(badge))
                        .font(.app(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6).opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Availability")
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(spot.isAvailableNow ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(spot.isAvailableNow ? "Available now" : "Available \(formatAvailabilityDate(spot.availableDate))")
                        .font(.app(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Contact")
                        .font(.app(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.appAccent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
            .overlay(
            Rectangle()
                .fill(Color(.systemGray4).opacity(0.5))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray4).opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }
    
    private func formatAvailabilityDate(_ date: Date?) -> String {
        guard let date else { return "soon" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

private struct PhotoGalleryView: View {
    let photos: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: URL(string: url)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else if phase.error != nil {
                            Color(.systemGray5)
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.6), in: Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - Roommate Detail Sheet
private struct RoommateDetailSheet: View {
    let roommate: Roommate
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    roommateHero
                    roommateHeader
                    roommateInfoCards
                    roommateDescription
                    roommateTags
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private var roommateHero: some View {
                AsyncImage(url: URL(string: roommate.image)) { phase in
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
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
                
    private var roommateHeader: some View {
                VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(roommate.name), \(roommate.age)")
                        .font(.app(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(roommate.location)
                            .font(.app(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            moveInPill
        }
    }

    private var roommateInfoCards: some View {
            VStack(spacing: 12) {
            infoCard(
                title: "Budget",
                subtitle: "Monthly target",
                systemImage: "banknote.fill",
                value: "$\(roommate.budget)"
            )
            infoCard(
                title: "Location",
                subtitle: "Preferred area",
                systemImage: "mappin.and.ellipse",
                value: roommate.location
            )
        }
    }

    private var roommateTags: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.app(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            if roommate.tags.isEmpty {
                Text("👋🙂 Friendly & respectful\n🏡✨ Looking for a cozy shared place\n🧹🫧 Clean habits and good vibes\n📍🗺️ Open to nearby neighborhoods\n🤝😊 Easy to live with")
                    .font(.app(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(roommate.tags, id: \.self) { tag in
                        Text("\(emojiForRoommateTag(tag)) \(tag)")
                            .font(.app(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                            .background(Color(.systemGray6), in: Capsule())
                    }
                }
            }
        }
    }

    private var roommateDescription: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description")
                .font(.app(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            Text("✨ Friendly and easy-going roommate looking for a respectful shared space. 🧹 Clean habits, open communication, and good vibes.")
                .font(.app(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }

    private var moveInPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appAccent)
            Text("Move in \(roommate.moveIn)")
                .font(.app(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: Capsule())
    }

    private func infoCard(title: String, subtitle: String, systemImage: String, value: String) -> some View {
                HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.12))
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
                    
                    Spacer()
                    
            Text(value)
                .font(.app(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func emojiForRoommateTag(_ tag: String) -> String {
        switch tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "student":
            return "🎓"
        case "non-smoker", "nonsmoker":
            return "🚭"
        case "quiet":
            return "🤫"
        case "professional":
            return "💼"
        case "pet friendly", "pet-friendly":
            return "🐾"
        case "social":
            return "🥳"
        case "remote worker", "remote":
            return "🧑‍💻"
        case "clean":
            return "🧼"
        case "flexible":
            return "🔁"
        case "lgbtq+ friendly", "lgbtq+":
            return "🏳️‍🌈"
        case "vegetarian":
            return "🥗"
        case "early riser":
            return "🌅"
        case "artist":
            return "🎨"
        default:
            return "✨"
        }
    }
}

private func emojiForBadge(_ badge: String) -> String {
    switch badge.lowercased() {
    case "furnished":
        return "🛋️"
    case "near metro":
        return "🚇"
    case "utilities included":
        return "💡"
    case "pet friendly":
        return "🐾"
    case "quiet":
        return "🤫"
    case "balcony":
        return "🌿"
    case "great view":
        return "🌅"
    case "parking":
        return "🅿️"
    case "wi‑fi", "wifi", "wi-fi":
        return "📶"
    case "washing machine":
        return "🧺"
    case "air conditioning":
        return "❄️"
    case "garden":
        return "🌳"
    case "pool":
        return "🏊"
    case "workspace":
        return "💻"
    default:
        return "✨"
    }
}

private func badgeDisplayText(_ badge: String) -> String {
    let hasEmoji = badge.unicodeScalars.contains {
        $0.properties.isEmojiPresentation || $0.properties.isEmoji
    }
    if hasEmoji {
        return badge
    }
    return "\(emojiForBadge(badge)) \(badge)"
}

// MARK: - Trip Location Searcher
private class TripLocationSearcher: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter to show only cities and countries (results with geographic context)
        results = completer.results.filter { result in
            // Keep results that look like cities/countries (have subtitle or are single locations)
            !result.title.contains("#") && !result.title.contains("Street") && !result.title.contains("Road") && !result.title.contains("Ave")
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

// MARK: - Address Search Completer
private class AddressSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    init(center: CLLocationCoordinate2D) {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }

    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
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
