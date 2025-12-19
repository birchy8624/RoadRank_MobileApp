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
            .navigationTitle("Ride Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        closeAndReset()
                    }
                }
            }
        }
    }

    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Route")
                .font(.headline)

            RideSummaryMapView(
                fullPath: ride.clCoordinates,
                selectedPath: selectedSegmentCoordinates,
                isSelectingSegment: isSelectingSegment
            )
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Main stats row
            HStack(spacing: 0) {
                StatCard(
                    icon: "clock.fill",
                    value: ride.formattedDuration,
                    label: "Duration",
                    color: .blue
                )

                Divider()
                    .frame(height: 60)

                StatCard(
                    icon: "road.lanes",
                    value: ride.formattedDistance,
                    label: "Distance",
                    color: .green
                )

                Divider()
                    .frame(height: 60)

                StatCard(
                    icon: "speedometer",
                    value: ride.formattedAverageSpeed,
                    label: "Avg Speed",
                    color: .orange
                )
            }
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Secondary stats
            HStack(spacing: 12) {
                MiniStatCard(
                    icon: "arrow.up",
                    value: ride.formattedMaxSpeed,
                    label: "Max Speed"
                )

                MiniStatCard(
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    value: "\(ride.path.count)",
                    label: "Points"
                )

                if let start = ride.path.first {
                    MiniStatCard(
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
                Text("Select Segment to Save")
                    .font(.headline)

                Spacer()

                Button("Reset") {
                    selectedStartIndex = 0
                    selectedEndIndex = ride.path.count - 1
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }

            VStack(spacing: 20) {
                // Start slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Start Point")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Point \(selectedStartIndex + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
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
                    .tint(.green)
                }

                // End slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("End Point")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Point \(selectedEndIndex + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
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
                    .tint(.red)
                }

                // Segment info
                HStack {
                    VStack(alignment: .leading) {
                        Text("Selected Segment")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(selectedEndIndex - selectedStartIndex + 1) points")
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Distance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f km", selectedSegmentDistance))
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !isSelectingSegment {
                // Save as Road button
                Button {
                    isSelectingSegment = true
                    selectedStartIndex = 0
                    selectedEndIndex = max(0, ride.path.count - 1)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "road.lanes")
                        Text("Save as Road & Rate")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Discard button
                Button {
                    closeAndReset()
                } label: {
                    Text("Discard Ride")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                // Confirm selection button
                Button {
                    saveSelectedSegment()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Continue to Rating")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedEndIndex <= selectedStartIndex)

                // Cancel selection
                Button {
                    isSelectingSegment = false
                } label: {
                    Text("Cancel Selection")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Stat Card
struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                renderer.strokeColor = polyline.isSelecting ? .systemGray3 : .systemBlue
                renderer.lineWidth = polyline.isSelecting ? 4 : 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }

            if let polyline = overlay as? SelectedSegmentPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemGreen
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
            markerView.markerTintColor = markerAnnotation.isStart ? .systemGreen : .systemRed
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
