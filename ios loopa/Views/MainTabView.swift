//
//  MainTabView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI

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
    @State private var selectedUser: User?
    @State private var selectedChat: Chat?
    @State private var showCelebration = false
    @State private var preselectedCreateType: CreateGroupEventView.CreationType? = nil
    private let data = AppData.shared
    
    var body: some View {
        ZStack {
            // Main Content with smooth transitions
            if selectedUser != nil {
                ProfileView(user: selectedUser!, onBack: {
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                        selectedUser = nil
                    }
                }, onMessage: { user in
                    let chat = chatForUser(user)
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                        selectedUser = nil
                        selectedChat = chat
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if selectedChat != nil {
                ChatDetailView(chat: selectedChat!) {
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.15)) {
                        selectedChat = nil
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                contentView(for: selectedTab)
                    .id(selectedTab) // Force view refresh on tab change
            }
            
            // Bottom Navigation Bar with safe area support
            if selectedUser == nil && selectedChat == nil {
                VStack {
                    Spacer()
                    bottomNavigationBar
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
    
    @ViewBuilder
    private func contentView(for tab: AppTab) -> some View {
        switch tab {
        case .explore:
            ExploreView(
                variant: .groups,
                onProfileClick: { user in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedUser = user
                    }
                },
                onAddGroupClick: { createType in
                    if let type = createType {
                        if type == .group {
                            preselectedCreateType = .group
                        }
                    }
                },
                onJoinGroupChat: { group in
                    let chat = chatForGroup(group)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedUser = nil
                        selectedTab = .chats
                        selectedChat = chat
                    }
                }
            )
        case .map:
            ExploreView(
                variant: .travelers,
                onProfileClick: { user in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedUser = user
                    }
                },
                onAddGroupClick: { createType in
                    if let type = createType {
                        if type == .group {
                            preselectedCreateType = .group
                        }
                    }
                },
                onJoinGroupChat: { _ in }
            )
        case .housing:
            HousingView()
        case .chats:
            ChatsListView { chat in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedChat = chat
                }
            }
        }
    }
    
    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: iconName(for: tab))
                                .font(.system(size: 22, weight: .bold))
                                .symbolVariant(selectedTab == tab ? .fill : .none)
                                .foregroundStyle(
                                    selectedTab == tab ? Color.appAccent : Color.black
                                )
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                            
                            // Notification badge removed
                        }
                        
                        Text(tabLabel(for: tab))
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundStyle(
                                selectedTab == tab ? Color.appAccent : Color.black
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56) // Increased for text label
                    .contentShape(Rectangle()) // Full button area is tappable
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .glassEffect(.regular.interactive(), in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
    }
    
    private func iconName(for tab: AppTab) -> String {
        switch tab {
        case .explore: return "globe.americas"
        case .map: return "person.2"
        case .housing: return "house"
        case .chats: return "message"
        }
    }
    
    private func tabLabel(for tab: AppTab) -> String {
        switch tab {
        case .explore: return "Explore"
        case .map: return "Friends"
        case .housing: return "Housing"
        case .chats: return "Messages"
        }
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
}
