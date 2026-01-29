//
//  ChatDetailView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit

struct ChatDetailView: View {
    let chat: Chat
    let onBack: () -> Void
    var initialMessage: String? = nil
    var onProfileClick: (() -> Void)? = nil
    
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isInputFocused: Bool
    @State private var showBlockAlert = false
    @State private var showReportAlert = false
    
    private let data = AppData.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            .ultraThinMaterial,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                
            // Enhanced Avatar - Clickable for DMs
                Button(action: {
                    if chat.type == .dm {
                        onProfileClick?()
                    }
                }) {
                    chatAvatarView(
                        image: chat.image,
                        placeholderSystemName: chat.type == .group ? "person.3.fill" : "person.circle.fill"
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.quaternary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(chat.type == .group)
                
                Button(action: {
                    if chat.type == .dm {
                        onProfileClick?()
                    }
                }) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(chat.title)
                                .font(.app(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            if chat.type == .group {
                                Text("🫶🏼")
                                    .font(.app(size: 16))
                            }
                        }
                        
                        if chat.type == .group {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                Text("80 members")
                                    .font(.app(size: 13, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Online")
                                    .font(.app(size: 13, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(chat.type == .group)
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: {
                        showBlockAlert = true
                    }) {
                        Label("Block user", systemImage: "hand.raised.fill")
                    }
                    
                    Button(role: .destructive, action: {
                        showReportAlert = true
                    }) {
                        Label("Report user", systemImage: "exclamationmark.triangle.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            .ultraThinMaterial,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .padding(.bottom, 12)
            .background(.regularMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundStyle(Color(.separator)),
                alignment: .bottom
            )
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(messages) { message in
                            if message.type == .separator {
                                separatorView(message: message)
                            } else {
                                messageBubble(message: message)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .padding(.bottom, 100)
                }
                .onChange(of: messages.count) { oldValue, newValue in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Type something...", text: $inputText)
                    .font(.app(size: 15))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.isEmpty ? .gray.opacity(0.3) : Color.appAccent)
                }
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 20)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.1)),
                alignment: .top
            )
        }
        .background(Color.white)
        .onAppear {
            loadMessages()
            if let initial = initialMessage {
                inputText = initial
            }
        }
        .alert("Block User", isPresented: $showBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                // Block user action
                onBack()
            }
        } message: {
            Text("Are you sure you want to block \(chat.title)? They won't be able to message you anymore.")
        }
        .alert("Report User", isPresented: $showReportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Report", role: .destructive) {
                // Report user action
            }
        } message: {
            Text("Are you sure you want to report \(chat.title)? Our team will review this account.")
        }
    }
    
    private func loadMessages() {
        messages = data.chatMessages[chat.id] ?? []
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newMessage = ChatMessage(
            id: messages.count + 1,
            sender: "Me",
            senderAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80",
            text: inputText,
            time: "Now",
            color: nil,
            isMe: true
        )
        
        messages.append(newMessage)
        inputText = ""
        isInputFocused = false
    }
    
    private func separatorView(message: ChatMessage) -> some View {
        Text(message.text)
            .font(.app(size: 11, weight: .medium))
            .foregroundColor(.gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
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
    
    @ViewBuilder
    private func messageBubble(message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isMe {
                chatAvatarView(image: message.senderAvatar, placeholderSystemName: "person.circle.fill")
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .offset(y: 24)
            }
            
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
                if !message.isMe {
                    HStack(spacing: 4) {
                        Text(message.sender)
                            .font(.app(size: 11, weight: .bold))
                            .foregroundColor(colorFromString(message.color))
                        Text(message.time)
                            .font(.app(size: 11))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                } else {
                    Text(message.time)
                        .font(.app(size: 11))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if let replyTo = message.replyTo {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(replyTo.sender)
                                .font(.app(size: 11, weight: .bold))
                                .foregroundColor(message.isMe ? .blue.opacity(0.8) : .blue)
                            Text(replyTo.text)
                                .font(.app(size: 11))
                                .foregroundColor(message.isMe ? .white.opacity(0.8) : .gray)
                                .lineLimit(2)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(message.isMe ? Color.blue.opacity(0.5) : Color.blue.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .frame(width: 2)
                                .foregroundColor(message.isMe ? .white.opacity(0.3) : .blue),
                            alignment: .leading
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Text(message.text)
                        .font(.app(size: 15))
                        .foregroundColor(message.isMe ? .white : .black)
                }
                .padding(14)
                .background(message.isMe ? Color.blue : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.clear, lineWidth: 0)
                )
            }
            .frame(maxWidth: .infinity, alignment: message.isMe ? .trailing : .leading)
            .padding(.horizontal, message.isMe ? 16 : 0)
        }
        .frame(maxWidth: .infinity, alignment: message.isMe ? .trailing : .leading)
    }
    
    private func colorFromString(_ color: String?) -> Color {
        guard let color = color else { return .black }
        switch color.lowercased() {
        case "orange": return .orange
        case "pink": return .pink
        case "yellow": return .yellow
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        default: return .black
        }
    }
}
