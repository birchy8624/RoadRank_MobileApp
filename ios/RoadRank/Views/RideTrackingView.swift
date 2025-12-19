import SwiftUI
import MapKit

// MARK: - Ride Tracking View
struct RideTrackingView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showStopConfirmation = false
    @State private var showCancelConfirmation = false

    var body: some View {
        ZStack {
            // Map background showing ride path
            RideMapView(
                path: locationManager.currentRide?.clCoordinates ?? [],
                userLocation: locationManager.location?.coordinate
            )
            .ignoresSafeArea()

            // Gradient overlay for readability
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 350)
            }
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // Stats display
                statsDisplay

                // Control buttons
                controlButtons
                    .padding(.bottom, 50)
            }
        }
        .confirmationDialog("Stop Ride?", isPresented: $showStopConfirmation, titleVisibility: .visible) {
            Button("Finish Ride") {
                finishRide()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your ride will be saved and you can review the summary.")
        }
        .confirmationDialog("Cancel Ride?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Discard Ride", role: .destructive) {
                locationManager.cancelRide()
                dismiss()
            }
            Button("Keep Riding", role: .cancel) { }
        } message: {
            Text("This will discard all ride data. This cannot be undone.")
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Cancel button
            Button {
                showCancelConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(locationManager.rideState == .tracking ? .green : .orange)
                    .frame(width: 10, height: 10)
                    .shadow(color: locationManager.rideState == .tracking ? .green : .orange, radius: 4)

                Text(locationManager.rideState == .tracking ? "Recording" : "Paused")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.5))
            .clipShape(Capsule())

            Spacer()

            // Center on user button
            Button {
                locationManager.centerOnUserLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Stats Display
    private var statsDisplay: some View {
        VStack(spacing: 24) {
            // Time - Large central display
            VStack(spacing: 4) {
                Text(locationManager.formattedElapsedTime)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text("Duration")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Speed and Distance
            HStack(spacing: 40) {
                // Speed
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(locationManager.formattedCurrentSpeed)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text("km/h")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text("Speed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 1, height: 60)

                // Distance
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(distanceValue)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text(distanceUnit)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text("Distance")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // Points tracked
            HStack(spacing: 8) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(locationManager.currentRide?.path.count ?? 0) points tracked")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 24) {
            // Pause/Resume Button
            Button {
                if locationManager.rideState == .tracking {
                    locationManager.pauseRide()
                } else {
                    locationManager.resumeRide()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: locationManager.rideState == .tracking ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )

                    Text(locationManager.rideState == .tracking ? "Pause" : "Resume")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            // Stop Button
            Button {
                showStopConfirmation = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 90, height: 90)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)

                    Text("Stop")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Helpers
    private var distanceValue: String {
        let km = locationManager.rideDistance / 1000.0
        if km < 1 {
            return String(format: "%.0f", locationManager.rideDistance)
        } else {
            return String(format: "%.2f", km)
        }
    }

    private var distanceUnit: String {
        let km = locationManager.rideDistance / 1000.0
        return km < 1 ? "m" : "km"
    }

    private func finishRide() {
        if let ride = locationManager.finishRide() {
            appState.finishedRide = ride
            appState.showRideSummary = true
            dismiss()
        }
    }
}

// MARK: - Ride Map View
struct RideMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.mapType = .standard
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update polyline
        mapView.removeOverlays(mapView.overlays)

        if path.count >= 2 {
            let polyline = MKPolyline(coordinates: path, count: path.count)
            mapView.addOverlay(polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    RideTrackingView()
        .environmentObject(LocationManager())
        .environmentObject(AppState())
}
