//
//  AppData.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import Foundation
import CoreLocation

// MARK: - Sample Data
class AppData {
    static let shared = AppData()
    
    /// Cities with number of recommendations (for Explore + Trips combined view)
    let citiesWithRecommendations: [CityWithRecommendations] = [
        CityWithRecommendations(name: "Bali", coordinate: CLLocationCoordinate2D(latitude: -8.4095, longitude: 115.1889), recommendationCount: 24, imageUrl: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80"),
        CityWithRecommendations(name: "Montreal", coordinate: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673), recommendationCount: 18, imageUrl: "https://images.unsplash.com/photo-1551884170-09fb70a3a2ed?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80"),
        CityWithRecommendations(name: "Paris", coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), recommendationCount: 31, imageUrl: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80"),
        CityWithRecommendations(name: "Barcelona", coordinate: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734), recommendationCount: 15, imageUrl: "https://images.unsplash.com/photo-1583422409516-2895a77efded?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80"),
        CityWithRecommendations(name: "Lisbon", coordinate: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393), recommendationCount: 12, imageUrl: "https://images.unsplash.com/photo-1555881400-74d7acaacd8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80"),
        CityWithRecommendations(name: "Tokyo", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), recommendationCount: 22, imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80"),
    ]
    
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
        Roommate(id: 2, name: "Mia", age: 26, budget: 1300, location: "Mile End", image: "https://i.pravatar.cc/150?u=mia-friendly", tags: ["Professional", "Pet friendly", "Social"], lat: 45.5150, lng: -73.5900, moveIn: "ASAP"),
        Roommate(id: 3, name: "Jordan", age: 28, budget: 1100, location: "Plateau Mont-Royal", image: "https://i.pravatar.cc/150?u=jordan", tags: ["Remote worker", "Clean", "Flexible"], lat: 45.5200, lng: -73.5800, moveIn: "Oct 1st"),
        Roommate(id: 4, name: "Sam", age: 22, budget: 800, location: "Griffintown", image: "https://i.pravatar.cc/150?u=sam", tags: ["Student", "LGBTQ+ friendly", "Vegetarian"], lat: 45.4900, lng: -73.5650, moveIn: "ASAP"),
        Roommate(id: 5, name: "Taylor", age: 30, budget: 1200, location: "Outremont", image: "https://i.pravatar.cc/150?u=taylor", tags: ["Professional", "Non-smoker", "Early riser"], lat: 45.5250, lng: -73.6000, moveIn: "Nov 1st"),
        Roommate(id: 6, name: "Riley", age: 25, budget: 950, location: "Villeray", image: "https://i.pravatar.cc/150?u=riley", tags: ["Artist", "Pet friendly", "Social"], lat: 45.5400, lng: -73.6200, moveIn: "Dec 1st")
    ]
    
    let swaps: [HomeSwap] = [
        HomeSwap(id: 1, title: "Modern Loft in Paris", target: "Montreal", dates: "Aug 10 - Aug 25", image: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Pierre", ownerImg: "https://i.pravatar.cc/150?u=pierre", lat: 45.5100, lng: -73.5700, homeType: "Entire home"),
        HomeSwap(id: 2, title: "Beach House in Barcelona", target: "Montreal", dates: "Sept 2024", image: "https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Elena", ownerImg: "https://i.pravatar.cc/150?u=elena", lat: 45.4950, lng: -73.5800, homeType: "Entire home"),
        HomeSwap(id: 3, title: "Cozy Apartment in Lisbon", target: "Montreal", dates: "Oct 15 - Nov 5", image: "https://images.unsplash.com/photo-1484154218962-a197022b5858?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Maria", ownerImg: "https://i.pravatar.cc/150?u=maria", lat: 45.5050, lng: -73.5750, homeType: "1 Bedroom Apt"),
        HomeSwap(id: 4, title: "Tokyo Studio Exchange", target: "Montreal", dates: "Dec 2024 - Jan 2025", image: "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Yuki", ownerImg: "https://i.pravatar.cc/150?u=yuki", lat: 45.5150, lng: -73.5850, homeType: "Studio"),
        HomeSwap(id: 5, title: "Berlin Flat Swap", target: "Montreal", dates: "Jan 10 - Feb 20", image: "https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Lukas", ownerImg: "https://i.pravatar.cc/150?u=lukas", lat: 45.5000, lng: -73.5600, homeType: "2 Bedroom Apt"),
        HomeSwap(id: 6, title: "Amsterdam Canal House", target: "Montreal", dates: "Mar 1 - Mar 15", image: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80", owner: "Sophie", ownerImg: "https://i.pravatar.cc/150?u=sophie", lat: 45.5200, lng: -73.5900, homeType: "Entire home")
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
