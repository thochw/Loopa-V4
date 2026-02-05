//
//  ChatsListView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit

enum ChatFilter: String, CaseIterable {
    case all = "All"
    case dms = "DMs"
    case plans = "Plans"
}

struct ChatsListView: View {
    let onChatClick: (Chat) -> Void
    
    @State private var selectedFilter: ChatFilter = .all
    private let data = AppData.shared
    
    private var filteredChats: [Chat] {
        switch selectedFilter {
        case .all:
            return data.chats
        case .dms:
            return data.chats.filter { $0.type == .dm }
        case .plans:
            return data.chats.filter { $0.type == .group }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            HStack {
                Text("Chats")
                    .font(.app(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Requests Badge
                    Button(action: {}) {
                        Text("0 Requests")
                            .font(.app(size: 13, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Color.appAccent.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Search Button
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(
                                Color.white,
                                in: Circle()
                            )
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .padding(.bottom, 20)
            
            // Enhanced Tabs with Liquid Glass
            HStack(spacing: 0) {
                ForEach(ChatFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.app(size: 14, weight: .semibold))
                            .foregroundStyle(selectedFilter == filter ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedFilter == filter ? Color.appAccent : Color.clear,
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Enhanced Chat List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredChats.enumerated()), id: \.element.id) { index, chat in
                        VStack(spacing: 0) {
                            chatRow(chat: chat)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        onChatClick(chat)
                                    }
                                }

                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background(Color.white)
    }
    
    private func chatRow(chat: Chat) -> some View {
        HStack(spacing: 16) {
        // Enhanced Avatar
        chatAvatarView(
            image: chat.image,
            placeholderSystemName: chat.type == .group ? "person.3.fill" : "person.circle.fill"
        )
        .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(chat.title)
                        .font(.app(size: 15, weight: chat.unread ? .semibold : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(chat.time)
                        .font(.app(size: 13, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
                
                HStack(alignment: .center, spacing: 8) {
                    Text(chat.message)
                        .font(.app(size: 15, weight: chat.unread ? .medium : .regular))
                        .foregroundStyle(chat.unread ? .primary : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if chat.unread {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func chatAvatarView(image: String, placeholderSystemName: String) -> some View {
        if let url = URL(string: image), url.scheme != nil {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Image(systemName: placeholderSystemName)
                        .foregroundStyle(.secondary)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                } else {
                    ProgressView()
                        .tint(.secondary)
                }
            }
        } else if let uiImage = UIImage(named: image) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: placeholderSystemName)
                .foregroundStyle(.secondary)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}
