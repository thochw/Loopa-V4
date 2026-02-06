//
//  AppModels.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import Foundation
import CoreLocation

// MARK: - City with recommendation count (Explore + Trips)
struct CityWithRecommendations: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let recommendationCount: Int
    let imageUrl: String

    static func == (lhs: CityWithRecommendations, rhs: CityWithRecommendations) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tab Enum
enum AppTab: String, CaseIterable {
    case explore = "explore"
    case map = "map"
    case chats = "chats"
}

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: Int
    let name: String
    let distance: String
    let flag: String
    let image: String
    let online: Bool
    let lng: Double
    let lat: Double
    let lifestyle: String? // Optional lifestyle filter
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// MARK: - Explore Model
struct Explore: Identifiable, Codable {
    let id: Int
    let title: String
    let attendees: Int
    let image: String
    let avatars: [String]
    let lng: Double
    let lat: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// MARK: - Housing Spot Model
struct HousingSpot: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String
    let price: Int
    let currency: String
    let period: String
    let image: String
    let photos: [String]
    let badges: [String]
    let rating: Double
    let recommender: String
    let recommenderImg: String
    let lat: Double
    let lng: Double
    let type: String
    let address: String?
    let contact: String?
    let availableDate: Date?
    let isAvailableNow: Bool
    
    // Default values for backward compatibility
    init(id: Int, title: String, description: String, price: Int, currency: String, period: String, image: String, photos: [String], badges: [String], rating: Double, recommender: String, recommenderImg: String, lat: Double, lng: Double, type: String, address: String? = nil, contact: String? = nil, availableDate: Date? = nil, isAvailableNow: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.currency = currency
        self.period = period
        self.image = image
        self.photos = photos
        self.badges = badges
        self.rating = rating
        self.recommender = recommender
        self.recommenderImg = recommenderImg
        self.lat = lat
        self.lng = lng
        self.type = type
        self.address = address
        self.contact = contact
        self.availableDate = availableDate
        self.isAvailableNow = isAvailableNow
    }
}

// MARK: - Roommate Model
struct Roommate: Identifiable, Codable {
    let id: Int
    let name: String
    let age: Int
    let budget: Int
    let location: String
    let image: String
    let tags: [String]
    let lat: Double
    let lng: Double
    let moveIn: String
}

// MARK: - Home Swap Model
struct HomeSwap: Identifiable, Codable {
    let id: Int
    let title: String
    let target: String
    let dates: String
    let image: String
    let owner: String
    let ownerImg: String
    let lat: Double
    let lng: Double
    let homeType: String
}

// MARK: - Chat Model
struct Chat: Identifiable, Codable {
    let id: Int
    let title: String
    let image: String
    let message: String
    let time: String
    let unread: Bool
    let type: ChatType
    
    enum ChatType: String, Codable {
        case group = "group"
        case dm = "dm"
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    let id: Int
    var sender: String
    var senderAvatar: String
    var text: String
    var time: String
    var color: String?
    var isMe: Bool
    var replyTo: MessageReply?
    var type: MessageType?
    
    enum MessageType: String, Codable {
        case separator = "separator"
        case message = "message"
    }
    
    struct MessageReply: Codable {
        let sender: String
        let text: String
    }
}
