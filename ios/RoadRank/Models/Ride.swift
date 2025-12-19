import Foundation
import CoreLocation

// MARK: - Ride
struct Ride: Identifiable, Codable {
    let id: UUID
    var startTime: Date
    var endTime: Date?
    var path: [RidePoint]

    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil, path: [RidePoint] = []) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.path = path
    }

    // MARK: - Computed Properties

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var distanceInMeters: Double {
        guard path.count >= 2 else { return 0 }
        var totalDistance: Double = 0

        for i in 0..<path.count - 1 {
            let loc1 = CLLocation(latitude: path[i].coordinate.lat, longitude: path[i].coordinate.lng)
            let loc2 = CLLocation(latitude: path[i + 1].coordinate.lat, longitude: path[i + 1].coordinate.lng)
            totalDistance += loc1.distance(from: loc2)
        }

        return totalDistance
    }

    var distanceInKm: Double {
        distanceInMeters / 1000.0
    }

    var formattedDistance: String {
        if distanceInKm < 1 {
            return String(format: "%.0f m", distanceInMeters)
        } else {
            return String(format: "%.2f km", distanceInKm)
        }
    }

    var averageSpeedKmh: Double {
        guard duration > 0 else { return 0 }
        let hours = duration / 3600.0
        return distanceInKm / hours
    }

    var formattedAverageSpeed: String {
        String(format: "%.1f km/h", averageSpeedKmh)
    }

    var maxSpeedKmh: Double {
        path.map { $0.speedKmh }.max() ?? 0
    }

    var formattedMaxSpeed: String {
        String(format: "%.1f km/h", maxSpeedKmh)
    }

    var coordinates: [Coordinate] {
        path.map { $0.coordinate }
    }

    var clCoordinates: [CLLocationCoordinate2D] {
        path.map { $0.coordinate.clLocationCoordinate2D }
    }

    var centerCoordinate: CLLocationCoordinate2D? {
        guard !path.isEmpty else { return nil }
        let midIndex = path.count / 2
        return path[midIndex].coordinate.clLocationCoordinate2D
    }

    var boundingRegion: (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)? {
        guard !path.isEmpty else { return nil }

        let lats = path.map { $0.coordinate.lat }
        let lngs = path.map { $0.coordinate.lng }

        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLng = lngs.min(),
              let maxLng = lngs.max() else { return nil }

        return (minLat, maxLat, minLng, maxLng)
    }

    // MARK: - Segment Extraction

    func segment(from startIndex: Int, to endIndex: Int) -> [Coordinate] {
        guard startIndex >= 0, endIndex < path.count, startIndex <= endIndex else { return [] }
        return Array(path[startIndex...endIndex]).map { $0.coordinate }
    }
}

// MARK: - Ride Point
struct RidePoint: Identifiable, Codable {
    let id: UUID
    let coordinate: Coordinate
    let timestamp: Date
    let speed: Double // meters per second
    let altitude: Double?
    let horizontalAccuracy: Double

    init(
        id: UUID = UUID(),
        coordinate: Coordinate,
        timestamp: Date = Date(),
        speed: Double = 0,
        altitude: Double? = nil,
        horizontalAccuracy: Double = 0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.speed = speed
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
    }

    init(from location: CLLocation) {
        self.id = UUID()
        self.coordinate = Coordinate(coordinate: location.coordinate)
        self.timestamp = location.timestamp
        self.speed = max(0, location.speed)
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
    }

    var speedKmh: Double {
        speed * 3.6 // Convert m/s to km/h
    }

    var formattedSpeed: String {
        String(format: "%.1f km/h", speedKmh)
    }
}

// MARK: - Ride State
enum RideState: Equatable {
    case idle
    case tracking
    case paused
    case finished(Ride)
}

// MARK: - Segment Selection
struct SegmentSelection: Identifiable, Equatable {
    let id = UUID()
    var startIndex: Int
    var endIndex: Int

    var isValid: Bool {
        startIndex >= 0 && endIndex >= startIndex
    }

    func coordinates(from ride: Ride) -> [Coordinate] {
        ride.segment(from: startIndex, to: endIndex)
    }

    func distance(from ride: Ride) -> Double {
        let segment = coordinates(from: ride)
        return segment.totalDistanceInKm()
    }
}
