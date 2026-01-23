//
//  ProfileEditorView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-20.
//

import SwiftUI

struct ProfileEditorView: View {
    let onClose: () -> Void

    private let data = AppData.shared
    private let profileName = "Thomas"
    private let profileCountry = "France"
    private let profileFlag = "🇫🇷"
    private let daysUntilTrip = 12
    private let tripProgress: CGFloat = 0.72
    private let tripOrigin = "Montréal"
    private let tripDestination = "Paris"
    private let avatarURL = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80"
    @State private var showAllGroups = false
    @State private var showAllFriends = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                profileCard
                heroSection
                groupsSection
                friendsSection
            }
            .padding(.top, 40)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
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

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    colors: [Color.appAccent.opacity(0.9), Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tripOrigin)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            Image(systemName: "airplane")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text(tripDestination)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.95))
                        }
                    }

                    Text("\(daysUntilTrip) days until your next trip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    GeometryReader { proxy in
                        let barWidth = max(0, proxy.size.width)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 8)

                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(20, barWidth * tripProgress), height: 8)
                                .animation(.easeInOut(duration: 0.6), value: tripProgress)

                            Image(systemName: "airplane")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(6)
                                .background(Color.white.opacity(0.25), in: Circle())
                                .offset(x: max(0, barWidth * tripProgress - 10))
                        }
                    }
                    .frame(height: 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                circleIconButton(systemName: "arrow.left", action: onClose)
                Spacer()
                circleIconButton(systemName: "gearshape") {}
            }

            HStack {
                Spacer()
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                Spacer()
            }
            .padding(.top, 4)

            statsRow

            HStack(spacing: 8) {
                Text(profileName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(profileFlag)
                    .font(.system(size: 18))

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                verificationPill
                Spacer()
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 0)
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    showAllGroups = true
                }) {
                    HStack(spacing: 6) {
                        Text("See all")
                            .font(.system(size: 14, weight: .semibold))
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
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private var friendsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Friends")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    showAllFriends = true
                }) {
                    HStack(spacing: 6) {
                        Text("See all")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 52, height: 52)
                    .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("No Friends Yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("You haven't made any friends")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .padding(.horizontal, 16)
    }

    private var verificationPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .bold))
            Text("Not Verified")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .foregroundStyle(Color.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1), in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }

    private func statCard(value: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }

    private func groupCard(_ group: Explore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: group.image)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Joined")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6), in: Capsule())
                .padding(8)
            }

            Text(group.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(height: 40, alignment: .top)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Text("🇮🇩")
                Text("Indonesia")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                avatarStack(group.avatars)
            }
        }
        .padding(12)
        .frame(width: 220, height: 230)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
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
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("\(group.attendees) members")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(action: {}) {
                            Text("Open")
                                .font(.system(size: 13, weight: .semibold))
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
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(friend.flag)
                                .font(.system(size: 13))
                        }

                        Spacer()

                        Button(action: {}) {
                            Text("Message")
                                .font(.system(size: 13, weight: .semibold))
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

