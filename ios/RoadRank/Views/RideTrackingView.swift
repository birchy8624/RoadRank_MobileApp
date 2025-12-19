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
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Theme.background.opacity(0.9), Theme.background.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)

                Spacer()

                LinearGradient(
                    colors: [.clear, Theme.background.opacity(0.7), Theme.background.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)
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
            BrandedIconButton("xmark", size: 44, style: .glass) {
                showCancelConfirmation = true
            }

            Spacer()

            // Status indicator
            BrandedBadge(
                locationManager.rideState == .tracking ? "Recording" : "Paused",
                color: locationManager.rideState == .tracking ? Theme.success : Theme.warning,
                isAnimated: locationManager.rideState == .tracking
            )

            Spacer()

            // Center on user button
            BrandedIconButton("location.fill", size: 44, style: .glass) {
                locationManager.centerOnUserLocation()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Stats Display
    private var statsDisplay: some View {
        VStack(spacing: 32) {
            // Time - Large central display
            VStack(spacing: 8) {
                Text(locationManager.formattedElapsedTime)
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 0)

                Text("Duration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textSecondary)
            }

            // Speed and Distance Cards
            HStack(spacing: 20) {
                // Speed Card
                VStack(spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(locationManager.formattedCurrentSpeed)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .monospacedDigit()

                        Text("km/h")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "speedometer")
                            .foregroundStyle(Theme.primary)
                        Text("Speed")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.backgroundSecondary.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                )

                // Distance Card
                VStack(spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(distanceValue)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .monospacedDigit()

                        Text(distanceUnit)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "road.lanes")
                            .foregroundStyle(Theme.success)
                        Text("Distance")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.backgroundSecondary.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)

            // Points tracked
            HStack(spacing: 8) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .foregroundStyle(Theme.textMuted)
                Text("\(locationManager.currentRide?.path.count ?? 0) points tracked")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.surface.opacity(0.5))
            .clipShape(Capsule())
        }
        .padding(.bottom, 40)
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 32) {
            // Pause/Resume Button
            Button {
                if locationManager.rideState == .tracking {
                    locationManager.pauseRide()
                } else {
                    locationManager.resumeRide()
                }
            } label: {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.backgroundSecondary)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )

                        Image(systemName: locationManager.rideState == .tracking ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Text(locationManager.rideState == .tracking ? "Pause" : "Resume")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            // Stop Button
            Button {
                showStopConfirmation = true
            } label: {
                VStack(spacing: 10) {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Theme.danger.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)

                        Circle()
                            .fill(Theme.dangerGradient)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: Theme.danger.opacity(0.5), radius: 15, x: 0, y: 8)

                        Image(systemName: "stop.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("Stop")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)
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
                // Use theme colors
                renderer.strokeColor = UIColor(red: 14/255, green: 165/255, blue: 233/255, alpha: 1) // Theme.primary
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
