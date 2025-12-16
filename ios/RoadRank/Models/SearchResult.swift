import Foundation
import MapKit

// MARK: - Nominatim Search Result
struct NominatimResult: Codable, Identifiable {
    let placeId: Int
    let lat: String
    let lon: String
    let displayName: String
    let type: String?
    let importance: Double?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case lat, lon
        case displayName = "display_name"
        case type, importance
    }

    var id: Int { placeId }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(lat) ?? 0,
            longitude: Double(lon) ?? 0
        )
    }

    var shortName: String {
        let components = displayName.components(separatedBy: ", ")
        if components.count >= 2 {
            return "\(components[0]), \(components[1])"
        }
        return components.first ?? displayName
    }

    var locationDescription: String {
        let components = displayName.components(separatedBy: ", ")
        if components.count > 2 {
            return components.dropFirst(2).prefix(2).joined(separator: ", ")
        }
        return ""
    }
}

// MARK: - OSRM Match Response
struct OSRMMatchResponse: Codable {
    let code: String
    let matchings: [OSRMMatching]?
    let tracepoints: [OSRMTracepoint?]?
}

struct OSRMMatching: Codable {
    let geometry: String
    let confidence: Double?
    let legs: [OSRMLeg]?
    let distance: Double?
    let duration: Double?
}

struct OSRMLeg: Codable {
    let distance: Double?
    let duration: Double?
    let steps: [OSRMStep]?
}

struct OSRMStep: Codable {
    let distance: Double?
    let duration: Double?
    let geometry: String?
    let name: String?
}

struct OSRMTracepoint: Codable {
    let location: [Double]
    let name: String?
    let matchingsIndex: Int?
    let waypointIndex: Int?

    enum CodingKeys: String, CodingKey {
        case location, name
        case matchingsIndex = "matchings_index"
        case waypointIndex = "waypoint_index"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location[1],
            longitude: location[0]
        )
    }
}

// MARK: - MKLocalSearch Extension for Fallback
struct LocationSearchResult: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

    init(mapItem: MKMapItem) {
        self.id = UUID()
        self.title = mapItem.name ?? "Unknown Location"
        self.subtitle = mapItem.placemark.formattedAddress ?? ""
        self.coordinate = mapItem.placemark.coordinate
    }

    init(nominatimResult: NominatimResult) {
        self.id = UUID()
        self.title = nominatimResult.shortName
        self.subtitle = nominatimResult.locationDescription
        self.coordinate = nominatimResult.coordinate
    }
}

// MARK: - Placemark Extension
extension MKPlacemark {
    var formattedAddress: String? {
        var addressComponents: [String] = []

        if let locality = locality {
            addressComponents.append(locality)
        }
        if let administrativeArea = administrativeArea {
            addressComponents.append(administrativeArea)
        }
        if let country = country {
            addressComponents.append(country)
        }

        return addressComponents.isEmpty ? nil : addressComponents.joined(separator: ", ")
    }
}
