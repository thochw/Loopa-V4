//
//  ProfileEditorView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-20.
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct ProfileEditorView: View {
    let onClose: () -> Void

    private let data = AppData.shared
    private let profileName = "Thomas"
    private let profileCountry = "France"
    private let profileFlag = "🇫🇷"
    private let profileAbout = "Hey, I'm Thomas! I love meeting travelers nearby. Say hi and share your next destination ✨"
    @State private var showAllGroups = false
    @State private var showAllFriends = false
    @State private var showProfileSettings = false
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeroSection(width: geometry.size.width)
                        profileContentCard
                            .offset(y: -28)
                    }
                }
                .ignoresSafeArea(edges: .top)

            }
            .overlay(alignment: .topTrailing) {
                Button(action: { showProfileSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.top, 8)
            }
            .overlay(alignment: .topLeading) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                }
                .padding(.leading, 20)
                .padding(.top, 8)
            }
        }
        .environment(\.colorScheme, .light)
        .sheet(isPresented: $showAllGroups) {
            AllGroupsListView(groups: data.groups) {
                showAllGroups = false
            }
        }
        .sheet(isPresented: $showAllFriends) {
            AllFriendsListView(friends: data.users) {
                showAllFriends = false
            }
        }
        .sheet(isPresented: $showProfileSettings) {
            ProfileSettingsView()
        }
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startUpdatingLocation()
        }
    }

    private func profileHeroSection(width: CGFloat) -> some View {
        ProfileGlobeView(userCoordinate: locationManager.location?.coordinate)
            .frame(width: width, height: 320)
            .clipped()
    }

    private var profileContentCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                profileStatsRow
                profileDivider
                profileNameAndVerificationRow
                profileLocationRow
                profileDivider
                profileAboutSection
                profileDivider
                groupsSection
                profileDivider
                friendsSection
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

    private var profileStatsRow: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(data.groups.count)")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                Text("Groups")
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 1, height: 44)

            VStack(spacing: 4) {
                Text("1")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                Text("Trips")
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 1, height: 44)

            VStack(spacing: 4) {
                Text("1")
                    .font(.app(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                Text("Visited")
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }

    private var profileNameAndVerificationRow: some View {
        HStack(alignment: .center, spacing: 10) {
            AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

            Text(profileName)
                .font(.app(size: 20, weight: .bold))
                .foregroundStyle(.black)
            Spacer()
            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("Edit Profile")
                        .font(.app(size: 15, weight: .medium))
                        .foregroundStyle(.black)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var profileLocationRow: some View {
        HStack(spacing: 8) {
            Text(profileFlag)
                .font(.system(size: 18))
            Text(profileCountry)
                .font(.app(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var profileAboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.black)
            Text(profileAbout)
                .font(.app(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
    }

    private var profileDivider: some View {
        Rectangle()
            .fill(Color(.systemGray4).opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Groups you Joined")
                    .font(.app(size: 18, weight: .bold))
                    .foregroundStyle(Color(.darkGray))
                Spacer()
                Button(action: {
                    showAllGroups = true
                }) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.app(size: 14, weight: .semibold))
                        Text(">")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(data.groups) { group in
                        groupCard(group)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Friends")
                    .font(.app(size: 18, weight: .bold))
                    .foregroundStyle(Color(.darkGray))
                Spacer()
                Button(action: {
                    showAllFriends = true
                }) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.app(size: 14, weight: .semibold))
                        Text(">")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 14) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.red)
                    .frame(width: 56, height: 56)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Friends Yet")
                        .font(.app(size: 16, weight: .bold))
                        .foregroundStyle(Color(.darkGray))
                    Text("You haven't made any friends")
                        .font(.app(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func groupCard(_ group: Explore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: group.image)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Joined")
                        .font(.app(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.darkGray), in: Capsule())
                .padding(8)
            }

            Text(group.title)
                .font(.app(size: 15, weight: .semibold))
                .foregroundStyle(Color(.darkGray))
                .lineLimit(2)
                .frame(height: 40, alignment: .top)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text("🇮🇩")
                Text("Indonesia")
                    .font(.app(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                avatarStack(group.avatars)
            }
        }
        .padding(12)
        .frame(width: 220, height: 230)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func avatarStack(_ urls: [String]) -> some View {
        HStack(spacing: -10) {
            ForEach(urls.prefix(3), id: \.self) { url in
                AsyncImage(url: URL(string: url)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 22, height: 22)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }

    private func circleIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(Color.white, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile globe (Mapbox)
private struct ProfileGlobeView: UIViewRepresentable {
    static let styleURL = "mapbox://styles/thochw/cmkbqgty5004901rxgct4a0z6"
    var userCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MapboxMaps.MapView {
        let styleURI = MapboxMaps.StyleURI(rawValue: Self.styleURL) ?? .standard
        let options = MapboxMaps.MapInitOptions(styleURI: styleURI)
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: options)
        mapView.mapboxMap.setCamera(to: MapboxMaps.CameraOptions(
            center: CLLocationCoordinate2D(latitude: 20, longitude: -50),
            zoom: 0.5,
            bearing: 0,
            pitch: 0
        ))
        try? mapView.mapboxMap.setProjection(MapboxMaps.StyleProjection(name: .globe))
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.mapboxMap.onStyleLoaded.observeNext { _ in
            try? mapView.mapboxMap.setAtmosphere(MapboxMaps.Atmosphere())
        }.store(in: &context.coordinator.cancelables)
        return mapView
    }

    func updateUIView(_ uiView: MapboxMaps.MapView, context: Context) {
        guard let coordinate = userCoordinate, !context.coordinator.didAnimateToUser else { return }
        context.coordinator.didAnimateToUser = true
        let target = MapboxMaps.CameraOptions(
            center: coordinate,
            zoom: 7,
            bearing: 0,
            pitch: 0
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            uiView.camera.ease(to: target, duration: 5.5, curve: .easeInOut, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var cancelables = Set<AnyCancelable>()
        var didAnimateToUser = false
    }
}

private struct AllGroupsListView: View {
    let groups: [Explore]
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: group.image)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.title)
                                .font(.app(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("\(group.attendees) members")
                                .font(.app(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(action: {}) {
                            Text("Open")
                                .font(.app(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appAccent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Groups you Joined")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }
}

private struct AllFriendsListView: View {
    let friends: [User]
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(friends) { friend in
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: friend.image)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.name)
                                .font(.app(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(friend.flag)
                                .font(.app(size: 13))
                        }

                        Spacer()

                        Button(action: {}) {
                            Text("Message")
                                .font(.app(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appAccent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }
}
