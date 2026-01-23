//
//  AppModels.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import Foundation
import CoreLocation

// MARK: - Tab Enum
enum AppTab: String, CaseIterable {
    case explore = "explore"
    case map = "map"
    case housing = "housing"
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
