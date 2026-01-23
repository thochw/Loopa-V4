//
//  AppData.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import Foundation

// MARK: - Sample Data
class AppData {
    static let shared = AppData()
    
    let users: [User] = [
        User(id: 1, name: "Emily", distance: "1 mi", flag: "🇺🇸", image: "IMG_9073", online: true, lng: -73.5700, lat: 45.5030, lifestyle: "backpacking"),
        User(id: 2, name: "Alissa Ma...", distance: "1 mi", flag: "🇬🇧", image: "https://i.pravatar.cc/150?u=alissa", online: true, lng: -73.5600, lat: 45.5000, lifestyle: "digital nomad"),
        User(id: 3, name: "Beatrice", distance: "14 mi", flag: "🇨🇦", image: "https://i.pravatar.cc/150?u=beatrice", online: true, lng: -73.5800, lat: 45.5100, lifestyle: "studying abroad"),
        User(id: 4, name: "John", distance: "0.5 mi", flag: "🇦🇺", image: "https://i.pravatar.cc/150?u=john", online: true, lng: -73.5650, lat: 45.5020, lifestyle: "gap year"),
        User(id: 5, name: "Sarah", distance: "2 mi", flag: "🇩🇪", image: "https://i.pravatar.cc/150?u=sarah", online: true, lng: -73.5550, lat: 45.4950, lifestyle: "living abroad")
    ]
    
    let groups: [Explore] = [
        Explore(id: 1, title: "Cafés, gym, billiard", attendees: 2, image: "https://images.unsplash.com/photo-1570554886111-e80fcca9402d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80", avatars: ["https://i.pravatar.cc/150?u=a", "https://i.pravatar.cc/150?u=b"], lng: -73.5620, lat: 45.5050),
        Explore(id: 2, title: "Weekly hangout, ( art, food, ro...", attendees: 7, image: "https://images.unsplash.com/photo-1511632765486-a01980e01a18?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80", avatars: ["https://i.pravatar.cc/150?u=c", "https://i.pravatar.cc/150?u=d", "https://i.pravatar.cc/150?u=e"], lng: -73.5750, lat: 45.4980)
    ]
    
    let housingSpots: [HousingSpot] = [
        HousingSpot(
            id: 1,
            title: "Sunny Studio in Plateau",
            description: "Bright studio with large windows, fully furnished, close to cafes and metro.",
            price: 1200,
            currency: "$",
            period: "mo",
            image: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            photos: [
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
            ],
            badges: ["Furnished", "Near metro", "Quiet"],
            rating: 4.8,
            recommender: "Sarah",
            recommenderImg: "https://i.pravatar.cc/150?u=sarah",
            lat: 45.5200,
            lng: -73.5800,
            type: "Entire place"
        ),
        HousingSpot(
            id: 2,
            title: "Room in Student Residence",
            description: "Private room in a shared student residence, utilities included.",
            price: 850,
            currency: "$",
            period: "mo",
            image: "https://images.unsplash.com/photo-1555854877-bab0e564b8d5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            photos: [
                "https://images.unsplash.com/photo-1555854877-bab0e564b8d5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
            ],
            badges: ["Student", "Utilities included"],
            rating: 4.2,
            recommender: "John",
            recommenderImg: "https://i.pravatar.cc/150?u=john",
            lat: 45.5050,
            lng: -73.5650,
            type: "Private room"
        )
    ]
    
    let roommates: [Roommate] = [
        Roommate(id: 1, name: "Alex", age: 24, budget: 900, location: "Downtown / Old Port", image: "https://i.pravatar.cc/150?u=alex", tags: ["Student", "Non-smoker", "Quiet"], lat: 45.5000, lng: -73.5600, moveIn: "Sept 1st"),
        Roommate(id: 2, name: "Mia", age: 26, budget: 1300, location: "Mile End", image: "https://i.pravatar.cc/150?u=mia", tags: ["Professional", "Pet friendly", "Social"], lat: 45.5150, lng: -73.5900, moveIn: "ASAP")
    ]
    
    let swaps: [HomeSwap] = [
        HomeSwap(id: 1, title: "Modern Loft in Paris", target: "Montreal", dates: "Aug 10 - Aug 25", image: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Pierre", ownerImg: "https://i.pravatar.cc/150?u=pierre", lat: 45.5100, lng: -73.5700, homeType: "1 Bedroom Apt"),
        HomeSwap(id: 2, title: "Beach House in Barcelona", target: "Montreal", dates: "Sept 2024", image: "https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Elena", ownerImg: "https://i.pravatar.cc/150?u=elena", lat: 45.4950, lng: -73.5800, homeType: "Entire Home")
    ]
    
    let chats: [Chat] = [
        Chat(id: 1, title: "Travel group", image: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80", message: "Anyone in Montreal hosting an igloofest aft...", time: "3:05 PM", unread: true, type: .group),
        Chat(id: 2, title: "Emily", image: "IMG_9073", message: "Hey! Are we still meeting at the cafe?", time: "2:15 PM", unread: false, type: .dm),
        Chat(id: 3, title: "John", image: "https://i.pravatar.cc/150?u=john", message: "Sent you the itinerary for the weekend.", time: "Yesterday", unread: true, type: .dm),
        Chat(id: 4, title: "Bali 2026", image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80", message: "Sarah joined the group!", time: "Yesterday", unread: false, type: .group)
    ]
    
    var chatMessages: [Int: [ChatMessage]] = [
        4: [
            ChatMessage(id: 1, sender: "Annie", senderAvatar: "https://i.pravatar.cc/150?u=annie", text: "And would anyone reccomend any good yoga retreats in uluawatu!!", time: "09:32", color: "orange", isMe: false),
            ChatMessage(id: 2, sender: "Natalie", senderAvatar: "https://i.pravatar.cc/150?u=natalie", text: "I think so maybee", time: "09:51", color: "pink", isMe: false, replyTo: ChatMessage.MessageReply(sender: "Ken", text: "Thank you for your answer, you mean emoney card? I used it from public transport and toll payment also?")),
            ChatMessage(id: 3, sender: "Omurbek", senderAvatar: "https://i.pravatar.cc/150?u=omurbek", text: "Hello👋 anyone here ?", time: "11:18", color: "yellow", isMe: false),
            ChatMessage(id: 4, sender: "", senderAvatar: "", text: "Today", time: "", isMe: false, type: .separator),
            ChatMessage(id: 5, sender: "Gypsy", senderAvatar: "https://i.pravatar.cc/150?u=gypsy", text: "Hi guys anyone keen to go la brisa beach club tonight for sunset and drinks ?", time: "00:32", color: "blue", isMe: false),
            ChatMessage(id: 6, sender: "Ayman", senderAvatar: "https://i.pravatar.cc/150?u=ayman", text: "Let's go", time: "00:33", color: "green", isMe: false),
            ChatMessage(id: 7, sender: "Connor", senderAvatar: "https://i.pravatar.cc/150?u=connor", text: "Savaya tn if anyone interested dm me", time: "07:24", color: "red", isMe: false)
        ],
        1: [
            ChatMessage(id: 1, sender: "Alex", senderAvatar: "https://i.pravatar.cc/150?u=alex", text: "Anyone in Montreal hosting an igloofest afterparty?", time: "3:05 PM", color: "blue", isMe: false)
        ],
        2: [
            ChatMessage(id: 1, sender: "Emily", senderAvatar: "IMG_9073", text: "Hey! Are we still meeting at the cafe?", time: "2:15 PM", color: nil, isMe: false)
        ],
        3: [
            ChatMessage(id: 1, sender: "John", senderAvatar: "https://i.pravatar.cc/150?u=john", text: "Sent you the itinerary for the weekend.", time: "Yesterday", color: nil, isMe: false)
        ]
    ]
    
    private init() {}
}
