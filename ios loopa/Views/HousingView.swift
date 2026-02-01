//
//  HousingView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import MapKit
import PhotosUI
import Combine

enum HousingTab: String, CaseIterable {
    case spots = "Housing"
    case roommates = "Roommates"
}

struct HousingView: View {
    var onMessageRoommate: ((Roommate) -> Void)? = nil
    
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
        VStack(spacing: 0) {
            myTripHeader

            // Enhanced Content with smooth transitions
            ZStack(alignment: .top) {
                if showMapView {
                    housingMapContent
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    Color.white
                        .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            upcomingTripsSection
                            recommendedHousingSection
                            findRoommatesSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                        .background(Color.white)
                    }
                    .background(Color.white)
                    .id(activeTab)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: showMapView)
        }
        .background(Color.white)
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
            } onClose: {
                showCreateSheet = false
            }
        }
        .sheet(isPresented: $showCreateTripSheet) {
            CreateTripView { trip in
                trips.insert(trip, at: 0)
                showCreateTripSheet = false
            } onClose: {
                showCreateTripSheet = false
            }
        }
        .sheet(isPresented: $showTripsList) {
            UpcomingTripsListView(trips: $trips) {
                showTripsList = false
            }
        }
        .sheet(item: $selectedHousingSpot) { spot in
            HousingDetailSheet(spot: spot, onClose: {
                selectedHousingSpot = nil
            })
        }
        .sheet(item: $selectedRoommate) { roommate in
            RoommateDetailSheet(roommate: roommate, onClose: {
                selectedRoommate = nil
            })
        }
        .fullScreenCover(item: $selectedTripForHousing) { trip in
            RecommendedHousingMapView(
                trip: trip,
                spots: housingSpots,
                avatarImages: data.users.map(\.image),
                onClose: { selectedTripForHousing = nil }
            )
        }
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
                .font(.app(size: 19, weight: .bold))
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
                .navigationTitle("My Upcoming Trips")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
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

    private struct RecommendedHousingMapView: View {
        let trip: Trip
        let spots: [HousingSpot]
        let avatarImages: [String]
        let onClose: () -> Void

        enum SheetState {
            case collapsed
            case partial
            case full
        }

        @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        )
        @State private var hasAnimated = false
        @State private var sheetState: SheetState = .partial
        @State private var showFilterSheet = false
        @State private var selectedSpotForDetail: HousingSpot? = nil
        
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

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Map
                    Map(coordinateRegion: $region)
                        .mapStyle(.standard(pointsOfInterest: .excludingAll))
                        .ignoresSafeArea()
                        .onAppear {
                            animateToTrip()
                        }
                        .opacity(sheetState == .full ? 0 : 1)
                        .animation(.easeInOut(duration: 0.35), value: sheetState)

                    // Back button (only when not full screen list)
                    if sheetState != .full {
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
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: sheetState)

                    // Toggle pill at bottom
                    VStack {
                        Spacer()
                        togglePill
                            .padding(.bottom, sheetState == .collapsed ? 40 : 20)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sheetState)
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .sheet(item: $selectedSpotForDetail) { spot in
                HousingDetailSheet(spot: spot, onClose: { selectedSpotForDetail = nil })
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

        private func partialSheet(geometry: GeometryProxy) -> some View {
            VStack(spacing: 12) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)

                // Header - City name centered
                Text(tripTitle)
                    .font(.app(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                
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
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 30, y: -8)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            if value.translation.height > 50 || velocity > 500 {
                                sheetState = .collapsed
                            } else if value.translation.height < -50 || velocity < -500 {
                                sheetState = .full
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
                            sheetState = .partial
                        }
                    }) {
                        Image(systemName: "chevron.left")
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
                                    .font(.app(size: 20, weight: .bold))
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
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        // Price filter - Range slider with histogram + Min/Max pills
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("💰")
                                    .font(.system(size: 22))
                                Text("Monthly budget")
                                    .font(.app(size: 20, weight: .bold))
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
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)
                        
                        // Rating filter - Stars visual
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("⭐")
                                    .font(.system(size: 22))
                                Text("Minimum rating")
                                    .font(.app(size: 20, weight: .bold))
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
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)
                        
                        // Availability filter - Now / Later
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Text("📅")
                                    .font(.system(size: 22))
                                Text("Availability")
                                    .font(.app(size: 20, weight: .bold))
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
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
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
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        
        private let budgetRange: ClosedRange<Double> = 0...2500
        private let budgetStep: Double = 50
        
        private var budgetRangeSliderWithHistogram: some View {
            VStack(alignment: .leading, spacing: 16) {
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
                    VStack(alignment: .leading, spacing: 6) {
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
                    VStack(alignment: .trailing, spacing: 6) {
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
            .padding(.vertical, 4)
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
            destinationParts.first ?? trip.destination
        }

        private var tripSubtitle: String {
            if destinationParts.count > 1 {
                return destinationParts[1]
            }
            return "Destination"
        }

        private var destinationParts: [String] {
            trip.destination.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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

            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(trip.destination) { placemarks, _ in
                let coordinate = placemarks?.first?.location?.coordinate
                    ?? CLLocationCoordinate2D(latitude: -8.4095, longitude: 115.1889)
                withAnimation(.easeInOut(duration: 0.8)) {
                    region.center = CLLocationCoordinate2D(
                        latitude: coordinate.latitude - 0.035,
                        longitude: coordinate.longitude
                    )
                    region.span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                }
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
            Map(coordinateRegion: $mapRegion, annotationItems: mapItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
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
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .ignoresSafeArea(edges: .bottom)
            .id(activeTab)

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

                    // Map with blur/fade at edges + user location (blue circle)
                    ZStack(alignment: .center) {
                        Map(coordinateRegion: $housingWelcomeRegion, interactionModes: [.zoom])
                            .mapStyle(.standard(pointsOfInterest: .excludingAll))
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
    private let trackHeight: CGFloat = 6
    
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

// MARK: - Housing Detail Sheet
private struct HousingDetailSheet: View {
    let spot: HousingSpot
    let onClose: () -> Void
    
    @State private var showPhotoGallery = false
    @State private var selectedPhotoIndex = 0
    
    var body: some View {
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
            .sheet(isPresented: $showPhotoGallery) {
                PhotoGalleryView(photos: spot.photos.isEmpty ? [spot.image] : spot.photos, selectedIndex: $selectedPhotoIndex)
            }
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
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
