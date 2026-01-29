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
                        .padding(.bottom, 120)
                    }
                    .id(activeTab)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: showMapView)
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
            Text("My trip")
                .font(.app(size: 24, weight: .bold))
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
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            Button(action: action) {
                Text(actionText)
                    .font(.app(size: 14, weight: .semibold))
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

        return ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: trip.imageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemGray5)
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
                        .font(.app(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(dateLabel.uppercased())
                        .font(.app(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(spacing: 8) {
                    avatarStack(images: Array(avatarImages))
                    Text(statusText ?? "+\(countdown) days")
                        .font(.app(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.18), in: Capsule())
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
                        Text("New trip")
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
        
        // Filter states
        @State private var selectedTypeFilters: Set<String> = []
        @State private var selectedPriceFilters: Set<String> = []
        @State private var selectedRatingFilters: Set<Int> = []
        @State private var selectedArrivalDate: Date? = nil
        
        private let typeOptions = ["All", "Apartment", "House", "Student residence", "Room"]
        private let priceOptions = ["All", "$0-500", "$500-1000", "$1000-1500", "$1500+"]
        private let ratingOptions = [0, 1, 2, 3, 4, 5] // 0 = All

        private var filteredSpots: [HousingSpot] {
            spots.filter { spot in
                // Type filter: if empty or contains the spot's type
                let typeMatch = selectedTypeFilters.isEmpty || selectedTypeFilters.contains(spot.type)
                
                // Price filter: if empty, show all; otherwise check if price falls in any selected range
                let priceMatch: Bool
                if selectedPriceFilters.isEmpty {
                    priceMatch = true
                } else {
                    priceMatch = selectedPriceFilters.contains { range in
                        switch range {
                        case "$0-500": return spot.price <= 500
                        case "$500-1000": return spot.price > 500 && spot.price <= 1000
                        case "$1000-1500": return spot.price > 1000 && spot.price <= 1500
                        case "$1500+": return spot.price > 1500
                        default: return false
                        }
                    }
                }
                
                // Rating filter: if empty, show all; otherwise check if rating matches any selected
                let ratingMatch: Bool
                if selectedRatingFilters.isEmpty {
                    ratingMatch = true
                } else {
                    ratingMatch = selectedRatingFilters.contains { minRating in
                        Int(spot.rating) >= minRating
                    }
                }
                
                // Availability filter - show spots available by the selected arrival date
                let availabilityMatch: Bool
                if let arrivalDate = selectedArrivalDate {
                    // Show spots that are available now OR will be available by the arrival date
                    availabilityMatch = spot.isAvailableNow || (spot.availableDate != nil && spot.availableDate! <= arrivalDate)
                } else {
                    availabilityMatch = true
                }
                
                return typeMatch && priceMatch && ratingMatch && availabilityMatch
            }
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

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tripTitle)
                            .font(.app(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(tripSubtitle)
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(tripDateLabel)
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
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

                        ForEach(Array(selectedTypeFilters), id: \.self) { type in
                            filterChip(text: type, onRemove: { selectedTypeFilters.remove(type) })
                        }
                        ForEach(Array(selectedPriceFilters), id: \.self) { price in
                            filterChip(text: price, onRemove: { selectedPriceFilters.remove(price) })
                        }
                        ForEach(Array(selectedRatingFilters), id: \.self) { rating in
                            filterChip(text: "\(rating)+ ⭐", onRemove: { selectedRatingFilters.remove(rating) })
                        }
                        if let arrivalDate = selectedArrivalDate {
                            filterChip(text: "Arrival: \(arrivalDate.formatted(date: .abbreviated, time: .omitted))", onRemove: { selectedArrivalDate = nil })
                        }
                    }
                    .padding(.horizontal, 20)
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
                if !selectedTypeFilters.isEmpty || !selectedPriceFilters.isEmpty || !selectedRatingFilters.isEmpty || selectedArrivalDate != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(selectedTypeFilters), id: \.self) { type in
                                filterChip(text: type, onRemove: { selectedTypeFilters.remove(type) })
                            }
                            ForEach(Array(selectedPriceFilters), id: \.self) { price in
                                filterChip(text: price, onRemove: { selectedPriceFilters.remove(price) })
                            }
                            ForEach(Array(selectedRatingFilters), id: \.self) { rating in
                                filterChip(text: "\(rating)+ ⭐", onRemove: { selectedRatingFilters.remove(rating) })
                            }
                            if let arrivalDate = selectedArrivalDate {
                                filterChip(text: "Arrival: \(arrivalDate.formatted(date: .abbreviated, time: .omitted))", onRemove: { selectedArrivalDate = nil })
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
                    VStack(alignment: .leading, spacing: 32) {
                        // Type filter
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.appAccent)
                                Text("Type of housing")
                                    .font(.app(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                            }

                            VStack(spacing: 12) {
                                ForEach(typeOptions, id: \.self) { option in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if option == "All" {
                                                selectedTypeFilters.removeAll()
                                            } else {
                                                if selectedTypeFilters.contains(option) {
                                                    selectedTypeFilters.remove(option)
                                                } else {
                                                    selectedTypeFilters.insert(option)
                                                }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text(option)
                                                .font(.app(size: 16, weight: .medium))
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            if (option == "All" && selectedTypeFilters.isEmpty) || selectedTypeFilters.contains(option) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(Color.appAccent)
                                            } else {
                                                Circle()
                                                    .strokeBorder(Color(.systemGray4), lineWidth: 2)
                                                    .frame(width: 22, height: 22)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            (option == "All" && selectedTypeFilters.isEmpty) || selectedTypeFilters.contains(option)
                                                ? Color.appAccent.opacity(0.1) 
                                                : Color(.systemGray6),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(
                                                    (option == "All" && selectedTypeFilters.isEmpty) || selectedTypeFilters.contains(option)
                                                        ? Color.appAccent.opacity(0.3) 
                                                        : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Price filter
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.appAccent)
                                Text("Price range/month")
                                    .font(.app(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(priceOptions, id: \.self) { option in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if option == "All" {
                                                selectedPriceFilters.removeAll()
                                            } else {
                                                if selectedPriceFilters.contains(option) {
                                                    selectedPriceFilters.remove(option)
                                                } else {
                                                    selectedPriceFilters.insert(option)
                                                }
                                            }
                                        }
                                    }) {
                                        Text(option)
                                            .font(.app(size: 15, weight: .semibold))
                                            .foregroundStyle(
                                                (option == "All" && selectedPriceFilters.isEmpty) || selectedPriceFilters.contains(option)
                                                    ? .white 
                                                    : .primary
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                (option == "All" && selectedPriceFilters.isEmpty) || selectedPriceFilters.contains(option)
                                                    ? Color.appAccent 
                                                    : Color(.systemGray6),
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Rating filter
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.appAccent)
                                Text("Minimum rating")
                                    .font(.app(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            
                            HStack(spacing: 8) {
                                // All option
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedRatingFilters.removeAll()
                                    }
                                }) {
                                    Text("All")
                                        .font(.app(size: 14, weight: .semibold))
                                        .foregroundStyle(selectedRatingFilters.isEmpty ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedRatingFilters.isEmpty ? Color.appAccent : Color(.systemGray6),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                                
                                ForEach(1...5, id: \.self) { rating in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedRatingFilters.contains(rating) {
                                                selectedRatingFilters.remove(rating)
                                            } else {
                                                selectedRatingFilters.insert(rating)
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("\(rating)")
                                                .font(.app(size: 14, weight: .semibold))
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundStyle(selectedRatingFilters.contains(rating) ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedRatingFilters.contains(rating) ? Color.appAccent : Color(.systemGray6),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Availability filter
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Color.appAccent)
                                    Text("Availability")
                                        .font(.app(size: 18, weight: .bold))
                                        .foregroundStyle(.primary)
                                }
                                Text("When do you plan to arrive?")
                                    .font(.app(size: 14, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 12) {
                                // Any date option
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedArrivalDate = nil
                                    }
                                }) {
                                    HStack {
                                        Text("Any date")
                                            .font(.app(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedArrivalDate == nil {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(Color.appAccent)
                                        } else {
                                            Circle()
                                                .strokeBorder(Color(.systemGray4), lineWidth: 2)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedArrivalDate == nil
                                            ? Color.appAccent.opacity(0.1)
                                            : Color(.systemGray6),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                selectedArrivalDate == nil
                                                    ? Color.appAccent.opacity(0.3)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // Date picker
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Select arrival date")
                                            .font(.app(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { selectedArrivalDate ?? Date() },
                                                set: { selectedArrivalDate = $0 }
                                            ),
                                            in: Date()...,
                                            displayedComponents: .date
                                        )
                                        .labelsHidden()
                                        .tint(Color.appAccent)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedArrivalDate != nil
                                            ? Color.appAccent.opacity(0.1)
                                            : Color(.systemGray6),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                selectedArrivalDate != nil
                                                    ? Color.appAccent.opacity(0.3)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .background(Color(.systemGroupedBackground))
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()
                        Button(action: { showFilterSheet = false }) {
                            Text("Show \(filteredSpots.count) results")
                                .font(.app(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appAccent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showFilterSheet = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reset") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTypeFilters.removeAll()
                                selectedPriceFilters.removeAll()
                                selectedRatingFilters.removeAll()
                                selectedArrivalDate = nil
                            }
                        }
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
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
    @State private var housingContact = ""
    @State private var housingAddress = ""
    @State private var housingAvailability: Date = Date()
    @State private var housingAvailabilityStatus = "Currently living here"
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var housingBadgesSelected: Set<String> = []
    @State private var housingBadgesCustom = ""

    @State private var roommateName = ""
    @State private var roommateAge = ""
    @State private var roommateBudget = ""
    @State private var roommateLocation = ""
    @State private var roommateMoveIn = ""
    @State private var roommateTags = ""

    init(
        activeTab: Binding<HousingTab>,
        coordinate: CLLocationCoordinate2D,
        onCreateSpot: @escaping (HousingSpot) -> Void,
        onCreateRoommate: @escaping (Roommate) -> Void,
        onClose: @escaping () -> Void
    ) {
        _activeTab = activeTab
        _selectedTab = State(initialValue: activeTab.wrappedValue)
        self.coordinate = coordinate
        self.onCreateSpot = onCreateSpot
        self.onCreateRoommate = onCreateRoommate
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    closeButton
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

    private var closeButton: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedTab == .spots ? "New housing recommendation" : "Find roommates")
                    .font(.app(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(selectedTab == .spots ? "Share a place you recommend for people moving to a new city" : "Post that you're looking for roommates")
                    .font(.app(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
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
            formTextField("Title", text: $housingTitle)
            
            HStack(spacing: 8) {
                TextField("Price", text: $housingPrice)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                
                Text("per")
                    .font(.app(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                periodPicker
            }

            formPicker("Type", selection: $housingType, options: ["Apartment", "House", "Student residence", "Room"])
            
            formTextField("Address", text: $housingAddress)
            
            // Rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Rating")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
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
                    
                    Spacer()
                    
                    if housingRating > 0 {
                        Text(ratingLabel(for: housingRating))
                            .font(.app(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
            }
            
            formTextField("Contact (email, phone, or other)", text: $housingContact)
            
            // Availability / When are you leaving
            VStack(alignment: .leading, spacing: 8) {
                Text("Next availability")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 10) {
                    // Status picker
                    HStack(spacing: 10) {
                        ForEach(["Currently living here", "Already left"], id: \.self) { status in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    housingAvailabilityStatus = status
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
                        Spacer()
                    }
                    
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
                    } else {
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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.app(size: 14, weight: .semibold))
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
                            .font(.app(size: 13, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Photos")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
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
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                badgeGrid(options: housingBadgeOptions, selection: $housingBadgesSelected)
                formTextField("Custom badges (comma separated)", text: $housingBadgesCustom)
            }
        }
    }

    private var roommatesForm: some View {
        VStack(alignment: .leading, spacing: 12) {
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


    private var actionBar: some View {
        Button(action: handleCreate) {
            Text("Publish")
                .font(.app(size: 16, weight: .semibold))
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
        }
    }

    private func handleCreate() {
        switch selectedTab {
        case .spots:
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
                    .foregroundStyle(Color.appAccent)
                Text(selection.wrappedValue)
                    .foregroundStyle(Color.appAccent)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
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
                Text(housingPeriod.isEmpty ? "Period" : housingPeriod)
                    .foregroundStyle(Color.appAccent)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
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
                        .font(.app(size: 13, weight: .semibold))
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

// MARK: - Housing Detail Sheet
private struct HousingDetailSheet: View {
    let spot: HousingSpot
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    housingHero
                    housingHeader
                    housingInfoCards
                    housingDescription
                    housingBadges
                    housingRecommender
                    housingPhotos
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

    private var housingHero: some View {
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
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", spot.rating))
                    .font(.app(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(16)
        }
    }

    private var housingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(spot.title)
                .font(.app(size: 24, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Image(systemName: "house.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text(spot.type)
                    .font(.app(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var housingInfoCards: some View {
        VStack(spacing: 12) {
            infoCard(
                title: "Price",
                subtitle: "Per \(spot.period)",
                systemImage: "banknote.fill",
                value: "\(spot.currency)\(spot.price)"
            )
            infoCard(
                title: "Rating",
                subtitle: "User review",
                systemImage: "star.fill",
                value: String(format: "%.1f", spot.rating)
            )
        }
    }

    private var housingDescription: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description")
                .font(.app(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            Text(spot.description)
                .font(.app(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }

    private var housingBadges: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Features")
                .font(.app(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            if spot.badges.isEmpty {
                Text("✨ Cozy, well-located, and fully equipped.")
                    .font(.app(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(spot.badges, id: \.self) { badge in
                        Text(badge)
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

    private var housingRecommender: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended by")
                .font(.app(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

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
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.quaternary, lineWidth: 1))

                Text(spot.recommender)
                .font(.app(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var housingPhotos: some View {
        Group {
            if spot.photos.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Photos")
                        .font(.app(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(spot.photos.enumerated()), id: \.offset) { _, photo in
                                AsyncImage(url: URL(string: photo)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Color(.systemGray5)
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
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
