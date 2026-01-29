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
    private let avatarURL = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80"
    @State private var showAllGroups = false
    @State private var showAllFriends = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerBar
                profileSummary
                groupsSection
                friendsSection
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.white)
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

    private var headerBar: some View {
        HStack {
            circleIconButton(systemName: "arrow.left", action: onClose)
            Spacer()
            circleIconButton(systemName: "gearshape") {}
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(profileName)
                            .font(.app(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(profileFlag)
                            .font(.app(size: 18))
                    }
                    verificationPill
                }

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Text("Edit Profile")
                            .font(.app(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }

            statsRow
        }
        .padding(.horizontal, 20)
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

