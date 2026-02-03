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
    private let avatarURL = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80"
    @State private var showAllGroups = false
    @State private var showAllFriends = false
    @State private var globeTargetCoordinate: CLLocationCoordinate2D? = nil
    @State private var globeAnimationKey = UUID()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "04152E")
                .ignoresSafeArea()

            topBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("profile-scroll")).minY)
                    }
                    .frame(height: 0)

                    globeHeader
                        .frame(height: globeHeight)
                        .clipped()
                        .opacity(globeOpacity)
                        .offset(y: globeYOffset)

                    profileSummary
                    groupsSection
                    friendsSection
                }
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: "profile-scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(hex: "F6F6F8"))

            compactHeader
                .opacity(compactHeaderOpacity)
                .allowsHitTesting(compactHeaderOpacity > 0.1)
        }
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
    }

    private var globeHeader: some View {
        ZStack(alignment: .top) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "04152E"), Color(hex: "0B2D5C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                starField

                GlobeMapView(
                    targetCoordinate: globeTargetCoordinate,
                    animationKey: globeAnimationKey
                )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 2)
                            .blur(radius: 0.2)
                    )
                    .shadow(color: Color.white.opacity(0.6), radius: 18)
                    .frame(width: 320, height: 320)
                    .offset(y: 6)
                    .onAppear {
                        animateGlobeToProfileCountry()
                    }
            }
            .frame(height: 330)
            .clipped()
            .ignoresSafeArea(edges: .top)

            HStack {
                circleIconButton(systemName: "arrow.left", action: onClose)
                Spacer()
                circleIconButton(systemName: "gearshape") {}
            }
            .padding(.horizontal, 20)
            .padding(.top, 38)
        }
    }

    private var topBackground: some View {
        LinearGradient(
            colors: [Color(hex: "04152E"), Color(hex: "0B2D5C")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 520)
        .ignoresSafeArea(edges: .top)
    }

    private var profileSummary: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    Spacer(minLength: 88)
                    statsRow
                }

                HStack(alignment: .center, spacing: 12) {
                    Text(profileName)
                        .font(.app(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    verificationPill

                    Spacer()

                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Text("Edit Profile")
                                .font(.app(size: 14, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    Text(profileFlag)
                        .font(.app(size: 16))
                    Text(profileCountry)
                        .font(.app(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 48)
            .padding(.bottom, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 14, y: 8)

            AsyncImage(url: URL(string: avatarURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
            .scaleEffect(avatarScale)
            .offset(x: 18, y: -44 + avatarYOffset)
        }
        .padding(.horizontal, 16)
        .padding(.top, -40)
    }


    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "0", title: "Groups")
            statCard(value: "1", title: "Trips")
            statCard(value: "1", title: "Visited")
        }
    }

    private var groupsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Groups you Joined")
                    .font(.app(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    showAllGroups = true
                }) {
                    HStack(spacing: 6) {
                        Text("See all")
                            .font(.app(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(data.groups) { group in
                        groupCard(group)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var friendsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Friends")
                    .font(.app(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    showAllFriends = true
                }) {
                    HStack(spacing: 6) {
                        Text("See all")
                            .font(.app(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 52, height: 52)
                    .background(Color.appAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("No Friends Yet")
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("You haven't made any friends")
                        .font(.app(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.appAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 20)
    }

    private var verificationPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .bold))
            Text("Not Verified")
                .font(.app(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .foregroundStyle(Color.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1), in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }

    private var starField: some View {
        ZStack {
            ForEach(starPositions.indices, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: index.isMultiple(of: 3) ? 2 : 1.4, height: index.isMultiple(of: 3) ? 2 : 1.4)
                    .position(starPositions[index])
            }
        }
    }

    private var starPositions: [CGPoint] {
        [
            CGPoint(x: 30, y: 24), CGPoint(x: 90, y: 60), CGPoint(x: 140, y: 18),
            CGPoint(x: 200, y: 46), CGPoint(x: 260, y: 30), CGPoint(x: 320, y: 72),
            CGPoint(x: 40, y: 120), CGPoint(x: 110, y: 140), CGPoint(x: 180, y: 110),
            CGPoint(x: 250, y: 150), CGPoint(x: 320, y: 120), CGPoint(x: 60, y: 200),
            CGPoint(x: 140, y: 210), CGPoint(x: 220, y: 190), CGPoint(x: 300, y: 210),
            CGPoint(x: 20, y: 260), CGPoint(x: 100, y: 260), CGPoint(x: 180, y: 250),
            CGPoint(x: 260, y: 270), CGPoint(x: 330, y: 250)
        ]
    }

    private var avatarScale: CGFloat {
        let progress = scrollProgress
        return 1 - (0.28 * progress)
    }

    private var avatarYOffset: CGFloat {
        let progress = scrollProgress
        return 16 * progress
    }

    private var scrollProgress: CGFloat {
        min(max(-scrollOffset / 220, 0), 1)
    }

    private var globeOpacity: CGFloat {
        1 - scrollProgress
    }

    private var globeYOffset: CGFloat {
        -80 * scrollProgress
    }

    private var globeHeight: CGFloat {
        max(0, 330 * (1 - scrollProgress))
    }

    private var compactHeaderOpacity: CGFloat {
        scrollProgress
    }

    private var compactHeader: some View {
        HStack(spacing: 12) {
            circleIconButton(systemName: "arrow.left", action: onClose)

            AsyncImage(url: URL(string: avatarURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            Text(profileName)
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            circleIconButton(systemName: "gearshape") {}
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }

    private func animateGlobeToProfileCountry() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(profileCountry) { placemarks, _ in
            let coordinate = placemarks?.first?.location?.coordinate
                ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
            globeTargetCoordinate = coordinate
            globeAnimationKey = UUID()
        }
    }

    private func statCard(value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.app(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.app(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private func groupRow(_ group: Explore) -> some View {
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

            avatarStack(group.avatars)
        }
        .padding(.vertical, 8)
    }

    private func friendRow(_ friend: User) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: friend.image)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(friend.flag)
                    .font(.app(size: 13))
            }

            Spacer()

            Text(friend.distance)
                .font(.app(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func groupCard(_ group: Explore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: group.image)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.white
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
                .background(Color.black.opacity(0.6), in: Capsule())
                .padding(8)
            }

            Text(group.title)
                .font(.app(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
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

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct GlobeMapView: UIViewRepresentable {
    let targetCoordinate: CLLocationCoordinate2D?
    let animationKey: UUID

    func makeUIView(context: Context) -> MapView {
        let options = MapInitOptions(styleURI: .standard)
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        mapView.mapboxMap.setCamera(to: .init(center: CLLocationCoordinate2D(latitude: 20, longitude: -50), zoom: 1.35, bearing: 0, pitch: 0))

        try? mapView.mapboxMap.setProjection(StyleProjection(name: .globe))
        mapView.mapboxMap.onStyleLoaded.observeNext { _ in
            try? mapView.mapboxMap.setAtmosphere(Atmosphere())
        }.store(in: &context.coordinator.cancelables)

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        guard let coordinate = targetCoordinate else { return }
        if context.coordinator.lastAnimationKey == animationKey {
            return
        }
        context.coordinator.lastAnimationKey = animationKey
        context.coordinator.animate(to: coordinate, on: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var cancelables = Set<AnyCancelable>()
        var lastAnimationKey: UUID?

        func animate(to coordinate: CLLocationCoordinate2D, on mapView: MapView) {
            let start = CameraOptions(
                center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude - 40),
                zoom: 1.4,
                bearing: 220,
                pitch: 0
            )
            mapView.mapboxMap.setCamera(to: start)

            let target = CameraOptions(
                center: coordinate,
                zoom: 1.9,
                bearing: 260,
                pitch: 0
            )
            mapView.camera.ease(to: target, duration: 1.6, curve: .easeInOut, completion: nil)
        }
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
