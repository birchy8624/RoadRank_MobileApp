import SwiftUI
import MapKit

// MARK: - Ride Summary View
struct RideSummaryView: View {
    let ride: Ride

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedStartIndex: Int = 0
    @State private var selectedEndIndex: Int = 0
    @State private var isSelectingSegment = false
    @State private var showSaveConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Map with route
                    mapSection

                    // Stats summary
                    statsSection

                    // Segment selection
                    if isSelectingSegment {
                        segmentSelectionSection
                    }

                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Ride Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        closeAndReset()
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            .toolbarBackground(Theme.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(Theme.primary)
                Text("Your Route")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            RideSummaryMapView(
                fullPath: ride.clCoordinates,
                selectedPath: selectedSegmentCoordinates,
                isSelectingSegment: isSelectingSegment
            )
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Main stats row
            HStack(spacing: 0) {
                BrandedStatCard(
                    icon: "clock.fill",
                    value: ride.formattedDuration,
                    label: "Duration",
                    color: Theme.primary
                )

                Rectangle()
                    .fill(Theme.surface)
                    .frame(width: 1, height: 60)

                BrandedStatCard(
                    icon: "road.lanes",
                    value: ride.formattedDistance,
                    label: "Distance",
                    color: Theme.success
                )

                Rectangle()
                    .fill(Theme.surface)
                    .frame(width: 1, height: 60)

                BrandedStatCard(
                    icon: "speedometer",
                    value: ride.formattedAverageSpeed,
                    label: "Avg Speed",
                    color: Theme.warning
                )
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            )

            // Secondary stats
            HStack(spacing: 12) {
                MiniStatCardBranded(
                    icon: "arrow.up",
                    value: ride.formattedMaxSpeed,
                    label: "Max Speed"
                )

                MiniStatCardBranded(
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    value: "\(ride.path.count)",
                    label: "Points"
                )

                if let start = ride.path.first {
                    MiniStatCardBranded(
                        icon: "clock",
                        value: formatTime(start.timestamp),
                        label: "Started"
                    )
                }
            }
        }
    }

    // MARK: - Segment Selection Section
    private var segmentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "scissors")
                        .foregroundStyle(Theme.primary)
                    Text("Select Segment to Save")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Button("Reset") {
                    selectedStartIndex = 0
                    selectedEndIndex = ride.path.count - 1
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.primary)
            }

            VStack(spacing: 20) {
                // Start slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.success)
                                .frame(width: 8, height: 8)
                            Text("Start Point")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("Point \(selectedStartIndex + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.success)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.success.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Slider(
                        value: Binding(
                            get: { Double(selectedStartIndex) },
                            set: { newValue in
                                let index = Int(newValue)
                                if index < selectedEndIndex {
                                    selectedStartIndex = index
                                }
                            }
                        ),
                        in: 0...Double(max(0, ride.path.count - 2)),
                        step: 1
                    )
                    .tint(Theme.success)
                }

                // End slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.danger)
                                .frame(width: 8, height: 8)
                            Text("End Point")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text("Point \(selectedEndIndex + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.danger.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Slider(
                        value: Binding(
                            get: { Double(selectedEndIndex) },
                            set: { newValue in
                                let index = Int(newValue)
                                if index > selectedStartIndex {
                                    selectedEndIndex = index
                                }
                            }
                        ),
                        in: 1...Double(ride.path.count - 1),
                        step: 1
                    )
                    .tint(Theme.danger)
                }

                // Segment info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Segment")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                        Text("\(selectedEndIndex - selectedStartIndex + 1) points")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Distance")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                        Text(String(format: "%.2f km", selectedSegmentDistance))
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !isSelectingSegment {
                // Save as Road button
                BrandedFullWidthButton("Save as Road & Rate", icon: "road.lanes", style: .primary) {
                    isSelectingSegment = true
                    selectedStartIndex = 0
                    selectedEndIndex = max(0, ride.path.count - 1)
                }

                // Discard button
                BrandedFullWidthButton("Discard Ride", icon: "trash", style: .secondary) {
                    closeAndReset()
                }
            } else {
                // Confirm selection button
                BrandedFullWidthButton("Continue to Rating", icon: "checkmark.circle.fill", style: .success) {
                    saveSelectedSegment()
                }

                // Cancel selection
                BrandedFullWidthButton("Cancel Selection", style: .secondary) {
                    isSelectingSegment = false
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var selectedSegmentCoordinates: [CLLocationCoordinate2D] {
        guard selectedStartIndex < ride.path.count,
              selectedEndIndex < ride.path.count,
              selectedStartIndex <= selectedEndIndex else {
            return []
        }
        return Array(ride.path[selectedStartIndex...selectedEndIndex])
            .map { $0.coordinate.clLocationCoordinate2D }
    }

    private var selectedSegmentDistance: Double {
        let segment = ride.segment(from: selectedStartIndex, to: selectedEndIndex)
        return segment.totalDistanceInKm()
    }

    // MARK: - Actions

    private func saveSelectedSegment() {
        let segment = ride.segment(from: selectedStartIndex, to: selectedEndIndex)
        appState.drawnPath = segment
        appState.snappedPath = nil
        appState.showRideSummary = false
        appState.finishedRide = nil
        appState.isShowingRatingSheet = true
        locationManager.resetRide()
    }

    private func closeAndReset() {
        appState.showRideSummary = false
        appState.finishedRide = nil
        locationManager.resetRide()
        dismiss()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mini Stat Card Branded
struct MiniStatCardBranded: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Ride Summary Map View
struct RideSummaryMapView: UIViewRepresentable {
    let fullPath: [CLLocationCoordinate2D]
    let selectedPath: [CLLocationCoordinate2D]
    let isSelectingSegment: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        guard fullPath.count >= 2 else { return }

        // Add full path polyline (gray when selecting, blue otherwise)
        let fullPolyline = FullRidePolyline(coordinates: fullPath, count: fullPath.count)
        fullPolyline.isSelecting = isSelectingSegment
        mapView.addOverlay(fullPolyline)

        // Add selected segment polyline if selecting
        if isSelectingSegment && selectedPath.count >= 2 {
            let selectedPolyline = SelectedSegmentPolyline(coordinates: selectedPath, count: selectedPath.count)
            mapView.addOverlay(selectedPolyline)

            // Add start/end markers
            if let start = selectedPath.first {
                let startAnnotation = SegmentMarkerAnnotation(coordinate: start, isStart: true)
                mapView.addAnnotation(startAnnotation)
            }
            if let end = selectedPath.last {
                let endAnnotation = SegmentMarkerAnnotation(coordinate: end, isStart: false)
                mapView.addAnnotation(endAnnotation)
            }
        }

        // Fit map to show full route
        let rect = fullPolyline.boundingMapRect
        let insets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        mapView.setVisibleMapRect(rect, edgePadding: insets, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? FullRidePolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                // Use theme colors
                if polyline.isSelecting {
                    renderer.strokeColor = UIColor(white: 0.5, alpha: 0.5)
                } else {
                    renderer.strokeColor = UIColor(red: 14/255, green: 165/255, blue: 233/255, alpha: 1) // Theme.primary
                }
                renderer.lineWidth = polyline.isSelecting ? 4 : 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }

            if let polyline = overlay as? SelectedSegmentPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1) // Theme.success
                renderer.lineWidth = 6
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let markerAnnotation = annotation as? SegmentMarkerAnnotation else {
                return nil
            }

            let identifier = markerAnnotation.isStart ? "StartMarker" : "EndMarker"
            let markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            markerView.glyphImage = UIImage(systemName: markerAnnotation.isStart ? "play.fill" : "stop.fill")
            // Use theme colors
            markerView.markerTintColor = markerAnnotation.isStart ?
                UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1) : // Theme.success
                UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1) // Theme.danger
            markerView.displayPriority = .required
            return markerView
        }
    }
}

// MARK: - Custom Polylines
class FullRidePolyline: MKPolyline {
    var isSelecting: Bool = false
}

class SelectedSegmentPolyline: MKPolyline {}

// MARK: - Segment Marker Annotation
class SegmentMarkerAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let isStart: Bool

    init(coordinate: CLLocationCoordinate2D, isStart: Bool) {
        self.coordinate = coordinate
        self.isStart = isStart
        super.init()
    }
}

#Preview {
    RideSummaryView(
        ride: Ride(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            path: [
                RidePoint(coordinate: Coordinate(lat: 53.4, lng: -1.8), timestamp: Date(), speed: 10),
                RidePoint(coordinate: Coordinate(lat: 53.41, lng: -1.81), timestamp: Date(), speed: 15),
                RidePoint(coordinate: Coordinate(lat: 53.42, lng: -1.82), timestamp: Date(), speed: 20)
            ]
        )
    )
    .environmentObject(AppState())
    .environmentObject(LocationManager())
}
