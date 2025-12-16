import Foundation
import MapKit

// MARK: - CLLocationCoordinate2D Extensions
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }

    var isValid: Bool {
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
}

// MARK: - Array of Coordinates Extensions
extension Array where Element == CLLocationCoordinate2D {
    var boundingRegion: MKCoordinateRegion {
        guard !isEmpty else { return .defaultRegion }

        var minLat = self[0].latitude
        var maxLat = self[0].latitude
        var minLng = self[0].longitude
        var maxLng = self[0].longitude

        for coord in self {
            minLat = Swift.min(minLat, coord.latitude)
            maxLat = Swift.max(maxLat, coord.latitude)
            minLng = Swift.min(minLng, coord.longitude)
            maxLng = Swift.max(maxLng, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLng - minLng) * 1.3
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    var totalDistance: CLLocationDistance {
        guard count >= 2 else { return 0 }

        var distance: CLLocationDistance = 0
        for i in 0..<count - 1 {
            distance += self[i].distance(to: self[i + 1])
        }

        return distance
    }

    var center: CLLocationCoordinate2D {
        guard !isEmpty else { return CLLocationCoordinate2D() }

        let latSum = reduce(0) { $0 + $1.latitude }
        let lngSum = reduce(0) { $0 + $1.longitude }

        return CLLocationCoordinate2D(
            latitude: latSum / Double(count),
            longitude: lngSum / Double(count)
        )
    }
}

// MARK: - MKCoordinateRegion Extensions
extension MKCoordinateRegion {
    var northEast: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta / 2,
            longitude: center.longitude + span.longitudeDelta / 2
        )
    }

    var southWest: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: center.latitude - span.latitudeDelta / 2,
            longitude: center.longitude - span.longitudeDelta / 2
        )
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= southWest.latitude &&
        coordinate.latitude <= northEast.latitude &&
        coordinate.longitude >= southWest.longitude &&
        coordinate.longitude <= northEast.longitude
    }

    func expanded(by factor: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * factor,
                longitudeDelta: span.longitudeDelta * factor
            )
        )
    }
}

// MARK: - Distance Formatting
extension CLLocationDistance {
    var formattedKilometers: String {
        let km = self / 1000
        if km >= 10 {
            return String(format: "%.0f km", km)
        } else if km >= 1 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", self)
        }
    }

    var formattedMiles: String {
        let miles = self / 1609.344
        if miles >= 10 {
            return String(format: "%.0f mi", miles)
        } else if miles >= 1 {
            return String(format: "%.1f mi", miles)
        } else {
            let yards = self / 0.9144
            return String(format: "%.0f yd", yards)
        }
    }
}
