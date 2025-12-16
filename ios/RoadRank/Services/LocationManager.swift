import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking: Bool = false
    @Published var heading: CLHeading?
    @Published var region: MKCoordinateRegion = .defaultRegion

    private let manager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    // Tracking state
    @Published var trackedRoute: [CLLocation] = []
    @Published var isRecordingRoute: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .automotiveNavigation

        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Optionally request always authorization for background tracking
            // manager.requestAlwaysAuthorization()
            break
        default:
            break
        }
    }

    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }

        isTracking = true
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopUpdatingLocation() {
        isTracking = false
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func centerOnUserLocation() {
        guard let location = location else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    // MARK: - Route Recording

    func startRecordingRoute() {
        trackedRoute = []
        isRecordingRoute = true
        manager.allowsBackgroundLocationUpdates = true
        startUpdatingLocation()
    }

    func stopRecordingRoute() -> [Coordinate] {
        isRecordingRoute = false
        manager.allowsBackgroundLocationUpdates = false

        let coordinates = trackedRoute.map { Coordinate(coordinate: $0.coordinate) }
        trackedRoute = []

        return coordinates
    }

    func cancelRecordingRoute() {
        isRecordingRoute = false
        manager.allowsBackgroundLocationUpdates = false
        trackedRoute = []
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        Task { @MainActor in
            self.location = newLocation
            self.region = MKCoordinateRegion(
                center: newLocation.coordinate,
                span: self.region.span
            )

            // Record route if tracking
            if self.isRecordingRoute {
                // Filter for accuracy and movement
                if let lastTracked = self.trackedRoute.last {
                    let distance = newLocation.distance(from: lastTracked)
                    if distance >= 20 && newLocation.horizontalAccuracy <= 50 {
                        self.trackedRoute.append(newLocation)
                    }
                } else if newLocation.horizontalAccuracy <= 50 {
                    self.trackedRoute.append(newLocation)
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.heading = newHeading
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.stopUpdatingLocation()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// MARK: - Default Region
extension MKCoordinateRegion {
    // Default to UK (where the seed data is)
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.5, longitude: -3.5),
        span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
    )
}

// MARK: - Coordinate Distance Calculation
extension Array where Element == Coordinate {
    func totalDistanceInMeters() -> Double {
        guard count >= 2 else { return 0 }
        var totalDistance: Double = 0

        for i in 0..<count - 1 {
            let loc1 = CLLocation(latitude: self[i].lat, longitude: self[i].lng)
            let loc2 = CLLocation(latitude: self[i + 1].lat, longitude: self[i + 1].lng)
            totalDistance += loc1.distance(from: loc2)
        }

        return totalDistance
    }

    func totalDistanceInKm() -> Double {
        totalDistanceInMeters() / 1000
    }
}
