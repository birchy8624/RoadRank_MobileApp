import Foundation
import MapKit

// MARK: - Road Snapping Service
actor RoadSnappingService {
    static let shared = RoadSnappingService()

    private let osrmBaseURL = "https://router.project-osrm.org/match/v1/driving/"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Snap Path to Road (Primary: Apple MapKit, Fallback: OSRM)

    func snapToRoad(path: [Coordinate]) async throws -> [Coordinate] {
        guard path.count >= 2 else {
            throw SnappingError.insufficientPoints
        }

        // Calculate path distance to determine parameters
        let distanceKm = path.totalDistanceInKm()

        // Validate distance (max 20km)
        guard distanceKm <= 20 else {
            throw SnappingError.pathTooLong
        }

        // Try Apple MapKit first (native iOS solution)
        do {
            let snapped = try await snapWithMapKit(path: path)
            if !snapped.isEmpty {
                return snapped
            }
        } catch {
            // Fall through to OSRM fallback
            print("MapKit snap failed: \(error.localizedDescription), trying OSRM fallback")
        }

        // Fallback to OSRM
        return try await snapWithOSRM(path: path, distanceKm: distanceKm)
    }

    // MARK: - Apple MapKit Snap-to-Road

    private func snapWithMapKit(path: [Coordinate]) async throws -> [Coordinate] {
        guard path.count >= 2 else { return [] }

        // For MapKit, we use MKDirections to get routes between waypoints
        // This naturally snaps to roads as it calculates driving directions
        var allCoordinates: [Coordinate] = []

        // Simplify path to reduce API calls (max 10 waypoints for routing)
        let waypoints = selectWaypoints(from: path, maxCount: 10)

        // Request directions between consecutive waypoints
        for i in 0..<(waypoints.count - 1) {
            let source = waypoints[i]
            let destination = waypoints[i + 1]

            let routeCoordinates = try await getRouteCoordinates(from: source, to: destination)

            if i == 0 {
                allCoordinates.append(contentsOf: routeCoordinates)
            } else if !routeCoordinates.isEmpty {
                // Skip first point to avoid duplicates
                allCoordinates.append(contentsOf: routeCoordinates.dropFirst())
            }
        }

        return allCoordinates
    }

    private func getRouteCoordinates(from source: Coordinate, to destination: Coordinate) async throws -> [Coordinate] {
        let request = MKDirections.Request()

        let sourcePlacemark = MKPlacemark(coordinate: source.clLocationCoordinate2D)
        let destPlacemark = MKPlacemark(coordinate: destination.clLocationCoordinate2D)

        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destPlacemark)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        return try await withCheckedThrowingContinuation { continuation in
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let route = response?.routes.first else {
                    continuation.resume(returning: [])
                    return
                }

                // Extract coordinates from the route polyline
                var coordinates: [Coordinate] = []
                let pointCount = route.polyline.pointCount
                let points = route.polyline.points()

                for i in 0..<pointCount {
                    let mapPoint = points[i]
                    let coord = mapPoint.coordinate
                    coordinates.append(Coordinate(lat: coord.latitude, lng: coord.longitude))
                }

                continuation.resume(returning: coordinates)
            }
        }
    }

    private func selectWaypoints(from path: [Coordinate], maxCount: Int) -> [Coordinate] {
        guard path.count > maxCount else { return path }

        // Always include first and last points
        var waypoints: [Coordinate] = [path.first!]

        // Select evenly spaced intermediate points
        let step = Double(path.count - 1) / Double(maxCount - 1)
        for i in 1..<(maxCount - 1) {
            let index = Int(Double(i) * step)
            waypoints.append(path[index])
        }

        waypoints.append(path.last!)
        return waypoints
    }

    // MARK: - OSRM Fallback

    private func snapWithOSRM(path: [Coordinate], distanceKm: Double) async throws -> [Coordinate] {
        // Simplify path if needed
        let simplifiedPath = simplifyPath(path, targetCount: 100)

        // Build OSRM URL
        let coordinateString = simplifiedPath
            .map { "\($0.lng),\($0.lat)" }
            .joined(separator: ";")

        // Adaptive parameters based on distance
        let radiuses = simplifiedPath.map { _ in
            distanceKm > 10 ? "75" : "50"
        }.joined(separator: ";")

        let overview = distanceKm > 5 ? "full" : "simplified"

        guard let url = URL(string: "\(osrmBaseURL)\(coordinateString)?overview=\(overview)&geometries=polyline&radiuses=\(radiuses)") else {
            throw SnappingError.invalidURL
        }

        // Make request
        var request = URLRequest(url: url)
        request.setValue("RoadRank-iOS/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SnappingError.serverError
            }

            let osrmResponse = try JSONDecoder().decode(OSRMMatchResponse.self, from: data)

            guard osrmResponse.code == "Ok",
                  let matching = osrmResponse.matchings?.first,
                  !matching.geometry.isEmpty else {
                throw SnappingError.noMatch
            }

            // Decode polyline
            let snappedCoordinates = decodePolyline(matching.geometry)

            guard !snappedCoordinates.isEmpty else {
                throw SnappingError.decodingFailed
            }

            return snappedCoordinates
        } catch let error as SnappingError {
            throw error
        } catch {
            throw SnappingError.networkError(error)
        }
    }

    // MARK: - Path Simplification (Ramer-Douglas-Peucker)

    private func simplifyPath(_ path: [Coordinate], targetCount: Int) -> [Coordinate] {
        guard path.count > targetCount else { return path }

        // Calculate appropriate epsilon
        var low = 0.00001
        var high = 0.01
        var result = path

        for _ in 0..<10 {
            let mid = (low + high) / 2
            result = rdpSimplify(path, epsilon: mid)

            if result.count > targetCount {
                low = mid
            } else {
                high = mid
            }

            if abs(result.count - targetCount) <= 10 {
                break
            }
        }

        return result
    }

    private func rdpSimplify(_ points: [Coordinate], epsilon: Double) -> [Coordinate] {
        guard points.count >= 3 else { return points }

        var maxDistance = 0.0
        var maxIndex = 0

        let first = points.first!
        let last = points.last!

        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(point: points[i], lineStart: first, lineEnd: last)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        if maxDistance > epsilon {
            let leftResults = rdpSimplify(Array(points[0...maxIndex]), epsilon: epsilon)
            let rightResults = rdpSimplify(Array(points[maxIndex...]), epsilon: epsilon)
            return Array(leftResults.dropLast()) + rightResults
        } else {
            return [first, last]
        }
    }

    private func perpendicularDistance(point: Coordinate, lineStart: Coordinate, lineEnd: Coordinate) -> Double {
        let dx = lineEnd.lng - lineStart.lng
        let dy = lineEnd.lat - lineStart.lat

        if dx == 0 && dy == 0 {
            return sqrt(pow(point.lng - lineStart.lng, 2) + pow(point.lat - lineStart.lat, 2))
        }

        let t = max(0, min(1, ((point.lng - lineStart.lng) * dx + (point.lat - lineStart.lat) * dy) / (dx * dx + dy * dy)))

        let projX = lineStart.lng + t * dx
        let projY = lineStart.lat + t * dy

        return sqrt(pow(point.lng - projX, 2) + pow(point.lat - projY, 2))
    }

    // MARK: - Polyline Decoding

    private func decodePolyline(_ encoded: String) -> [Coordinate] {
        var coordinates: [Coordinate] = []
        var index = encoded.startIndex
        var lat = 0
        var lng = 0

        while index < encoded.endIndex {
            var result = 0
            var shift = 0
            var byte = 0

            repeat {
                let char = encoded[index]
                index = encoded.index(after: index)
                byte = Int(char.asciiValue! - 63)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lat += dlat

            result = 0
            shift = 0

            repeat {
                let char = encoded[index]
                index = encoded.index(after: index)
                byte = Int(char.asciiValue! - 63)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lng += dlng

            coordinates.append(Coordinate(
                lat: Double(lat) / 1e5,
                lng: Double(lng) / 1e5
            ))
        }

        return coordinates
    }
}

// MARK: - Snapping Error
enum SnappingError: LocalizedError {
    case insufficientPoints
    case pathTooLong
    case invalidURL
    case serverError
    case noMatch
    case decodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .insufficientPoints:
            return "At least 2 points are required"
        case .pathTooLong:
            return "Road path cannot exceed 20km"
        case .invalidURL:
            return "Invalid request URL"
        case .serverError:
            return "Server error occurred"
        case .noMatch:
            return "Could not match path to road"
        case .decodingFailed:
            return "Failed to decode road data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
