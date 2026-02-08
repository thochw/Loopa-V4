//
//  MainTabView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit

extension Color {
    static let appAccent = Color(hex: "fe3c5d")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .explore
    @State private var hideExploreTabBar = false
    @State private var selectedUser: User?
    @State private var selectedChat: Chat?
    @State private var chatInitialMessage: String? = nil
    @State private var chatBeforeProfile: Chat? = nil  // Track chat when viewing profile from chat
    @State private var showCelebration = false
    @State private var preselectedCreateType: CreateGroupEventView.CreationType? = nil
    private let data = AppData.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView(
                hideTabBar: $hideExploreTabBar,
                onMessageRoommate: { roommate in
                    let chat = chatForRoommate(roommate)
                    chatInitialMessage = "Hello 👋"
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = .chats
                        selectedChat = chat
                    }
                }
            )
            .toolbar(hideExploreTabBar ? .hidden : .visible, for: .tabBar)
            .tabItem { Label("Explore", systemImage: "globe.americas") }
            .tag(AppTab.explore)

            FriendsGroupsView(
                variant: .travelers,
                onProfileClick: { user in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedUser = user
                    }
                },
                onAddGroupClick: { createType in
                    if let type = createType, type == .group {
                        preselectedCreateType = .group
                    }
                },
                onJoinGroupChat: { _ in }
            )
            .tabItem { Label("Friends", systemImage: "person.2") }
            .tag(AppTab.map)

            ChatsListView { chat in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedChat = chat
                }
            }
            .tabItem { Label("DMs", systemImage: "bubble.left.and.bubble.right") }
            .tag(AppTab.chats)
        }
        .tint(Color.appAccent)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: Binding(
            get: { selectedUser != nil },
            set: { if !$0 { selectedUser = nil } }
        )) {
            if let user = selectedUser {
                ProfileView(user: user, onBack: {
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                        selectedUser = nil
                        if let chat = chatBeforeProfile {
                            selectedChat = chat
                            chatBeforeProfile = nil
                        }
                    }
                }, onMessage: { user in
                    let chat = chatForUser(user)
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                        selectedUser = nil
                        chatBeforeProfile = nil
                        selectedChat = chat
                    }
                })
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedChat != nil },
            set: { if !$0 { selectedChat = nil; chatInitialMessage = nil } }
        )) {
            if let chat = selectedChat {
                ChatDetailView(chat: chat, onBack: {
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                        selectedChat = nil
                        chatInitialMessage = nil
                    }
                }, initialMessage: chatInitialMessage, onProfileClick: {
                    if chat.type == .dm {
                        let user = userFromChat(chat)
                        withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                            chatBeforeProfile = chat
                            selectedChat = nil
                            chatInitialMessage = nil
                            selectedUser = user
                        }
                    }
                })
            }
        }
        .sheet(item: $preselectedCreateType) { type in
            CreateGroupEventView(
                showCelebration: $showCelebration,
                preselectedType: type
            )
            .presentationDetents([.fraction(0.65)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .safeAreaPadding(.top, 120)
            .safeAreaPadding(.bottom, 400) // Space from bottom of iPhone
        }
        .celebrationOverlay(show: $showCelebration)
    }
    
    private func chatForUser(_ user: User) -> Chat {
        if let existing = data.chats.first(where: {
            $0.type == .dm &&
            ($0.title.caseInsensitiveCompare(user.name) == .orderedSame || $0.image == user.image)
        }) {
            return existing
        }

        return Chat(
            id: 1000 + user.id,
            title: user.name,
            image: user.image,
            message: "Say hi to \(user.name)",
            time: "Now",
            unread: false,
            type: .dm
        )
    }

    private func chatForGroup(_ group: Explore) -> Chat {
        if let existing = data.chats.first(where: {
            $0.type == .group &&
            ($0.title.caseInsensitiveCompare(group.title) == .orderedSame || $0.image == group.image)
        }) {
            return existing
        }

        return Chat(
            id: 2000 + group.id,
            title: group.title,
            image: group.image,
            message: "Joined \(group.title)",
            time: "Now",
            unread: false,
            type: .group
        )
    }

    private func chatForRoommate(_ roommate: Roommate) -> Chat {
        if let existing = data.chats.first(where: {
            $0.type == .dm &&
            ($0.title.caseInsensitiveCompare(roommate.name) == .orderedSame || $0.image == roommate.image)
        }) {
            return existing
        }

        return Chat(
            id: 3000 + roommate.id,
            title: roommate.name,
            image: roommate.image,
            message: "Start a conversation",
            time: "Now",
            unread: false,
            type: .dm
        )
    }

    private func userFromChat(_ chat: Chat) -> User {
        // Try to find an existing user that matches the chat
        if let existing = data.users.first(where: {
            $0.name.caseInsensitiveCompare(chat.title) == .orderedSame || $0.image == chat.image
        }) {
            return existing
        }

        // Create a user from the chat info
        return User(
            id: chat.id,
            name: chat.title,
            distance: "Nearby",
            flag: "🌍",
            image: chat.image,
            online: true,
            lng: -73.5673,
            lat: 45.5017,
            lifestyle: nil
        )
    }
}
