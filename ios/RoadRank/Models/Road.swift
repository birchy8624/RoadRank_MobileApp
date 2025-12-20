import Foundation
import MapKit
import SwiftUI

// MARK: - Coordinate
struct Coordinate: Codable, Equatable, Hashable, Identifiable {
    var id: String { "\(lat)-\(lng)" }
    let lat: Double
    let lng: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.lat = coordinate.latitude
        self.lng = coordinate.longitude
    }
}

// MARK: - Rating Summary (nested object in API response)
struct RatingSummary: Codable {
    let ratingCount: Int?
    let avgTwistiness: Double?
    let avgSurfaceCondition: Double?
    let avgFunFactor: Double?
    let avgScenery: Double?
    let avgVisibility: Double?
    let avgOverall: Double?

    enum CodingKeys: String, CodingKey {
        case ratingCount = "rating_count"
        case avgTwistiness = "avg_twistiness"
        case avgSurfaceCondition = "avg_surface_condition"
        case avgFunFactor = "avg_fun_factor"
        case avgScenery = "avg_scenery"
        case avgVisibility = "avg_visibility"
        case avgOverall = "avg_overall"
    }
}

// MARK: - Road
struct Road: Codable, Identifiable, Equatable {
    let id: String
    let name: String?
    let path: [Coordinate]
    let twistiness: Int?
    let surfaceCondition: Int?
    let funFactor: Int?
    let scenery: Int?
    let visibility: Int?
    let createdAt: String?
    let ratingSummary: RatingSummary?
    var deviceId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, path, twistiness, visibility
        case surfaceCondition = "surface_condition"
        case funFactor = "fun_factor"
        case scenery
        case createdAt = "created_at"
        case ratingSummary = "rating_summary"
        case deviceId = "device_id"
    }

    // Custom decoder to handle id as either Int or String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }

        name = try container.decodeIfPresent(String.self, forKey: .name)
        path = try container.decode([Coordinate].self, forKey: .path)
        twistiness = try container.decodeIfPresent(Int.self, forKey: .twistiness)
        surfaceCondition = try container.decodeIfPresent(Int.self, forKey: .surfaceCondition)
        funFactor = try container.decodeIfPresent(Int.self, forKey: .funFactor)
        scenery = try container.decodeIfPresent(Int.self, forKey: .scenery)
        visibility = try container.decodeIfPresent(Int.self, forKey: .visibility)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        ratingSummary = try container.decodeIfPresent(RatingSummary.self, forKey: .ratingSummary)
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
    }

    // Computed properties for backwards compatibility
    var ratingCount: Int? { ratingSummary?.ratingCount }
    var avgTwistiness: Double? { ratingSummary?.avgTwistiness }
    var avgSurfaceCondition: Double? { ratingSummary?.avgSurfaceCondition }
    var avgFunFactor: Double? { ratingSummary?.avgFunFactor }
    var avgScenery: Double? { ratingSummary?.avgScenery }
    var avgVisibility: Double? { ratingSummary?.avgVisibility }

    var displayName: String {
        name ?? "Unnamed Road"
    }

    var overallRating: Double {
        // Prefer the pre-computed avgOverall from the API
        if let avgOverall = ratingSummary?.avgOverall {
            return avgOverall
        }
        // Fallback to computing from individual ratings
        let ratings = [avgTwistiness, avgSurfaceCondition, avgFunFactor, avgScenery, avgVisibility]
        let validRatings = ratings.compactMap { $0 }
        guard !validRatings.isEmpty else { return 0 }
        return validRatings.reduce(0, +) / Double(validRatings.count)
    }

    var ratingColor: RatingColor {
        RatingColor.fromRating(overallRating)
    }

    var coordinates: [CLLocationCoordinate2D] {
        path.map { $0.clLocationCoordinate2D }
    }

    var centerCoordinate: CLLocationCoordinate2D? {
        guard !path.isEmpty else { return nil }
        let midIndex = path.count / 2
        return path[midIndex].clLocationCoordinate2D
    }

    var distanceInKm: Double {
        guard path.count >= 2 else { return 0 }
        var totalDistance: Double = 0
        for i in 0..<path.count - 1 {
            let loc1 = CLLocation(latitude: path[i].lat, longitude: path[i].lng)
            let loc2 = CLLocation(latitude: path[i + 1].lat, longitude: path[i + 1].lng)
            totalDistance += loc1.distance(from: loc2)
        }
        return totalDistance / 1000
    }

    var formattedDistance: String {
        String(format: "%.1f km", distanceInKm)
    }

    var isMyRoad: Bool {
        deviceId == DeviceManager.shared.deviceId
    }

    static func == (lhs: Road, rhs: Road) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Rating
struct Rating: Codable, Identifiable {
    let id: String?
    let roadId: String
    let twistiness: Int
    let surfaceCondition: Int
    let funFactor: Int
    let scenery: Int
    let visibility: Int
    let comment: String?
    let deviceId: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case roadId = "road_id"
        case twistiness
        case surfaceCondition = "surface_condition"
        case funFactor = "fun_factor"
        case scenery, visibility, comment
        case deviceId = "device_id"
        case createdAt = "created_at"
    }

    // Custom decoder to handle id as either Int or String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decodeIfPresent(String.self, forKey: .id)
        }

        // Handle roadId as either Int or String
        if let intRoadId = try? container.decode(Int.self, forKey: .roadId) {
            roadId = String(intRoadId)
        } else {
            roadId = try container.decode(String.self, forKey: .roadId)
        }

        twistiness = try container.decode(Int.self, forKey: .twistiness)
        surfaceCondition = try container.decode(Int.self, forKey: .surfaceCondition)
        funFactor = try container.decode(Int.self, forKey: .funFactor)
        scenery = try container.decode(Int.self, forKey: .scenery)
        visibility = try container.decode(Int.self, forKey: .visibility)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    var isMyRating: Bool {
        deviceId == DeviceManager.shared.deviceId
    }

    var overallRating: Double {
        Double(twistiness + surfaceCondition + funFactor + scenery + visibility) / 5.0
    }
}

// MARK: - Rating Category
enum RatingCategory: String, CaseIterable, Identifiable {
    case twistiness
    case surfaceCondition
    case funFactor
    case scenery
    case visibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twistiness: return "Twistiness"
        case .surfaceCondition: return "Surface Condition"
        case .funFactor: return "Fun Factor"
        case .scenery: return "Scenery"
        case .visibility: return "Visibility"
        }
    }

    var icon: String {
        switch self {
        case .twistiness: return "arrow.triangle.swap"
        case .surfaceCondition: return "road.lanes"
        case .funFactor: return "bolt.fill"
        case .scenery: return "mountain.2.fill"
        case .visibility: return "eye.fill"
        }
    }

    var color: Color {
        switch self {
        case .twistiness: return .purple
        case .surfaceCondition: return .blue
        case .funFactor: return .orange
        case .scenery: return .green
        case .visibility: return .cyan
        }
    }

    var lowDescription: String {
        switch self {
        case .twistiness: return "Straight"
        case .surfaceCondition: return "Poor"
        case .funFactor: return "Boring"
        case .scenery: return "Plain"
        case .visibility: return "Limited"
        }
    }

    var highDescription: String {
        switch self {
        case .twistiness: return "Very Twisty"
        case .surfaceCondition: return "Excellent"
        case .funFactor: return "Thrilling"
        case .scenery: return "Stunning"
        case .visibility: return "Clear"
        }
    }
}

// MARK: - Rating Color
enum RatingColor {
    case poor, fair, good, excellent

    static func fromRating(_ rating: Double) -> RatingColor {
        switch rating {
        case 0..<2: return .poor
        case 2..<3: return .fair
        case 3..<4: return .good
        default: return .excellent
        }
    }

    var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }

    var uiColor: UIColor {
        switch self {
        case .poor: return .systemRed
        case .fair: return .systemOrange
        case .good: return .systemYellow
        case .excellent: return .systemGreen
        }
    }
}

// MARK: - New Road Input
struct NewRoadInput {
    var name: String = ""
    var path: [Coordinate] = []
    var twistiness: Int = 3
    var surfaceCondition: Int = 3
    var funFactor: Int = 3
    var scenery: Int = 3
    var visibility: Int = 3
    var comment: String = ""
    var deviceId: String = DeviceManager.shared.deviceId

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        path.count >= 2
    }

    func toRoadPayload() -> [String: Any] {
        [
            "name": name,
            "path": path.map { ["lat": $0.lat, "lng": $0.lng] },
            "twistiness": twistiness,
            "surface_condition": surfaceCondition,
            "fun_factor": funFactor,
            "scenery": scenery,
            "visibility": visibility,
            "comment": comment.isEmpty ? NSNull() : comment,
            "device_id": deviceId
        ]
    }
}

// MARK: - Device Manager
class DeviceManager {
    static let shared = DeviceManager()

    private let deviceIdKey = "roadrank_device_id"

    var deviceId: String {
        if let existingId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existingId
        }

        // Generate a new unique device ID
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    private init() {}
}

// MARK: - New Rating Input
struct NewRatingInput {
    var roadId: String
    var twistiness: Int = 3
    var surfaceCondition: Int = 3
    var funFactor: Int = 3
    var scenery: Int = 3
    var visibility: Int = 3
    var comment: String = ""
    var deviceId: String = DeviceManager.shared.deviceId

    func toPayload() -> [String: Any] {
        [
            "twistiness": twistiness,
            "surface_condition": surfaceCondition,
            "fun_factor": funFactor,
            "scenery": scenery,
            "visibility": visibility,
            "comment": comment.isEmpty ? NSNull() : comment,
            "device_id": deviceId
        ]
    }
}
