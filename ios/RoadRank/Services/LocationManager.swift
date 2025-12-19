import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

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

    // Ride tracking state
    @Published var currentRide: Ride?
    @Published var rideState: RideState = .idle
    @Published var currentSpeed: Double = 0 // km/h
    @Published var elapsedTime: TimeInterval = 0
    @Published var rideDistance: Double = 0 // meters

    private var rideTimer: Timer?
    private var rideStartTime: Date?

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

    // MARK: - Ride Tracking

    func startRide() {
        guard rideState == .idle else { return }

        rideStartTime = Date()
        currentRide = Ride(startTime: rideStartTime!)
        rideState = .tracking
        currentSpeed = 0
        elapsedTime = 0
        rideDistance = 0

        manager.allowsBackgroundLocationUpdates = true
        startUpdatingLocation()

        // Start timer for elapsed time
        rideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.rideStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }

        HapticManager.shared.success()
    }

    func pauseRide() {
        guard rideState == .tracking else { return }
        rideState = .paused
        rideTimer?.invalidate()
        rideTimer = nil
        HapticManager.shared.impact(.medium)
    }

    func resumeRide() {
        guard rideState == .paused else { return }
        rideState = .tracking

        // Resume timer
        rideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.rideStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }

        HapticManager.shared.impact(.medium)
    }

    func finishRide() -> Ride? {
        guard rideState == .tracking || rideState == .paused,
              var ride = currentRide else { return nil }

        rideTimer?.invalidate()
        rideTimer = nil
        ride.endTime = Date()
        manager.allowsBackgroundLocationUpdates = false

        let finishedRide = ride
        rideState = .finished(finishedRide)

        HapticManager.shared.success()
        return finishedRide
    }

    func cancelRide() {
        rideTimer?.invalidate()
        rideTimer = nil
        rideStartTime = nil
        currentRide = nil
        rideState = .idle
        currentSpeed = 0
        elapsedTime = 0
        rideDistance = 0
        manager.allowsBackgroundLocationUpdates = false

        HapticManager.shared.warning()
    }

    func resetRide() {
        rideTimer?.invalidate()
        rideTimer = nil
        rideStartTime = nil
        currentRide = nil
        rideState = .idle
        currentSpeed = 0
        elapsedTime = 0
        rideDistance = 0
    }

    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedCurrentSpeed: String {
        String(format: "%.1f", currentSpeed)
    }

    var formattedRideDistance: String {
        let km = rideDistance / 1000.0
        if km < 1 {
            return String(format: "%.0f m", rideDistance)
        } else {
            return String(format: "%.2f km", km)
        }
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

            // Record ride if tracking
            if self.rideState == .tracking {
                // Update current speed
                if newLocation.speed >= 0 {
                    self.currentSpeed = newLocation.speed * 3.6 // Convert m/s to km/h
                }

                // Add point to ride if accuracy is good enough
                if newLocation.horizontalAccuracy <= 50 {
                    let ridePoint = RidePoint(from: newLocation)

                    // Check minimum distance from last point (10m for smoother tracking)
                    if let lastPoint = self.currentRide?.path.last {
                        let lastLocation = CLLocation(
                            latitude: lastPoint.coordinate.lat,
                            longitude: lastPoint.coordinate.lng
                        )
                        let distance = newLocation.distance(from: lastLocation)

                        if distance >= 10 {
                            self.currentRide?.path.append(ridePoint)
                            self.rideDistance += distance
                        }
                    } else {
                        self.currentRide?.path.append(ridePoint)
                    }
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
