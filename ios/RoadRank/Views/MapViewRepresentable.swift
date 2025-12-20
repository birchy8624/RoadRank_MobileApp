import SwiftUI
import MapKit

// MARK: - Map View Representable (UIKit Bridge)
struct MapViewRepresentable: UIViewRepresentable {
    let roads: [Road]
    let drawnPath: [Coordinate]
    let snappedPath: [Coordinate]?
    let isDrawingMode: Bool
    @Binding var selectedRoad: Road?
    @Binding var shouldCenterOnUser: Bool
    @Binding var roadToCenter: Road?
    var userLocation: CLLocation?
    var onPathUpdate: (([Coordinate]) -> Void)?
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.mapType = .standard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.overrideUserInterfaceStyle = .light

        // Set initial region (UK)
        mapView.setRegion(.defaultRegion, animated: false)

        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        mapView.addGestureRecognizer(panGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.isDrawingMode = isDrawingMode
        context.coordinator.onPathUpdate = onPathUpdate
        context.coordinator.onMapTap = onMapTap
        context.coordinator.roads = roads

        // Center on user location if requested
        if shouldCenterOnUser, let location = userLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            mapView.setRegion(region, animated: true)
            // Reset the flag after centering
            DispatchQueue.main.async {
                self.shouldCenterOnUser = false
            }
        }

        // Center on road if requested (from Discover tab navigation)
        if let road = roadToCenter {
            let coordinates = road.coordinates
            if coordinates.count >= 2 {
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                let rect = polyline.boundingMapRect
                let insets = UIEdgeInsets(top: 80, left: 40, bottom: 200, right: 40)
                mapView.setVisibleMapRect(rect, edgePadding: insets, animated: true)
            } else if let center = road.centerCoordinate {
                let region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                mapView.setRegion(region, animated: true)
            }
            // Reset after centering
            DispatchQueue.main.async {
                self.roadToCenter = nil
            }
        }

        // Update overlays
        mapView.removeOverlays(mapView.overlays)

        // Add road overlays
        for road in roads {
            let coordinates = road.coordinates
            guard coordinates.count >= 2 else { continue }

            let polyline = RoadPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.roadId = road.id
            polyline.color = road.ratingColor.uiColor
            polyline.lineWidth = 4
            mapView.addOverlay(polyline)
        }

        // Add drawn path overlay
        if !drawnPath.isEmpty {
            let coordinates = drawnPath.map { $0.clLocationCoordinate2D }
            let polyline = DrawingPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.color = .systemBlue
            polyline.lineWidth = 3
            polyline.isDashed = true
            mapView.addOverlay(polyline)
        }

        // Add snapped path overlay
        if let snapped = snappedPath, !snapped.isEmpty {
            let coordinates = snapped.map { $0.clLocationCoordinate2D }
            let polyline = DrawingPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.color = .systemGreen
            polyline.lineWidth = 5
            polyline.isDashed = false
            mapView.addOverlay(polyline)
        }

        // Disable scrolling during drawing
        mapView.isScrollEnabled = !isDrawingMode
        mapView.isZoomEnabled = !isDrawingMode
        mapView.isRotateEnabled = !isDrawingMode
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapViewRepresentable
        var isDrawingMode: Bool = false
        var onPathUpdate: (([Coordinate]) -> Void)?
        var onMapTap: ((CLLocationCoordinate2D) -> Void)?
        var roads: [Road] = []

        private var currentDrawingPath: [Coordinate] = []
        private var isCurrentlyDrawing = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // MARK: - Gesture Recognizers

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            if isDrawingMode {
                onMapTap?(coordinate)
            } else {
                // Check if tapped on a road
                checkForRoadTap(at: point, in: mapView)
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard isDrawingMode, let mapView = gesture.view as? MKMapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            switch gesture.state {
            case .began:
                isCurrentlyDrawing = true
                currentDrawingPath = [Coordinate(coordinate: coordinate)]
                onPathUpdate?(currentDrawingPath)

            case .changed:
                guard isCurrentlyDrawing else { return }

                // Throttle updates
                if let last = currentDrawingPath.last {
                    let lastLoc = CLLocation(latitude: last.lat, longitude: last.lng)
                    let newLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    if newLoc.distance(from: lastLoc) >= 10 { // At least 10 meters
                        currentDrawingPath.append(Coordinate(coordinate: coordinate))
                        onPathUpdate?(currentDrawingPath)
                        HapticManager.shared.draw()
                    }
                }

            case .ended, .cancelled:
                isCurrentlyDrawing = false

            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return !isDrawingMode
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if gestureRecognizer is UIPanGestureRecognizer {
                return isDrawingMode
            }
            return true
        }

        private func checkForRoadTap(at point: CGPoint, in mapView: MKMapView) {
            let mapPoint = MKMapPoint(mapView.convert(point, toCoordinateFrom: mapView))

            for overlay in mapView.overlays {
                guard let roadPolyline = overlay as? RoadPolyline,
                      let roadId = roadPolyline.roadId else { continue }

                // Check if point is near the polyline
                if isPoint(mapPoint, nearPolyline: roadPolyline, threshold: 30) {
                    if let road = roads.first(where: { $0.id == roadId }) {
                        HapticManager.shared.selection()
                        parent.selectedRoad = road
                        return
                    }
                }
            }
        }

        private func isPoint(_ point: MKMapPoint, nearPolyline polyline: MKPolyline, threshold: Double) -> Bool {
            let points = polyline.points()

            for i in 0..<polyline.pointCount - 1 {
                let p1 = points[i]
                let p2 = points[i + 1]

                let distance = distanceFromPoint(point, toLineSegmentFrom: p1, to: p2)
                if distance < threshold {
                    return true
                }
            }

            return false
        }

        private func distanceFromPoint(_ point: MKMapPoint, toLineSegmentFrom p1: MKMapPoint, to p2: MKMapPoint) -> Double {
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y

            if dx == 0 && dy == 0 {
                return point.distance(to: p1)
            }

            let t = max(0, min(1, ((point.x - p1.x) * dx + (point.y - p1.y) * dy) / (dx * dx + dy * dy)))
            let projection = MKMapPoint(x: p1.x + t * dx, y: p1.y + t * dy)

            return point.distance(to: projection)
        }

        // MARK: - Map View Delegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let roadPolyline = overlay as? RoadPolyline {
                let renderer = MKPolylineRenderer(polyline: roadPolyline)
                renderer.strokeColor = roadPolyline.color
                renderer.lineWidth = roadPolyline.lineWidth
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }

            if let drawingPolyline = overlay as? DrawingPolyline {
                let renderer = MKPolylineRenderer(polyline: drawingPolyline)
                renderer.strokeColor = drawingPolyline.color
                renderer.lineWidth = drawingPolyline.lineWidth
                renderer.lineCap = .round
                renderer.lineJoin = .round

                if drawingPolyline.isDashed {
                    renderer.lineDashPattern = [8, 8]
                }

                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Custom Polylines

class RoadPolyline: MKPolyline {
    var roadId: String?
    var color: UIColor = .systemGreen
    var lineWidth: CGFloat = 4
}

class DrawingPolyline: MKPolyline {
    var color: UIColor = .systemBlue
    var lineWidth: CGFloat = 3
    var isDashed: Bool = false
}
