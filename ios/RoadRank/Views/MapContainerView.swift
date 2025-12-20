import SwiftUI
import MapKit

// MARK: - Map Container View
struct MapContainerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var roadStore: RoadStore
    @StateObject private var searchViewModel = SearchViewModel()

    @State private var position: MapCameraPosition = .region(.defaultRegion)
    @State private var selectedRoadForPopup: Road?
    @State private var showSearchSheet: Bool = false
    @State private var roadToCenter: Road?

    var body: some View {
        ZStack {
            // Main Map
            MapViewRepresentable(
                roads: roadStore.roads,
                drawnPath: appState.drawnPath,
                snappedPath: appState.snappedPath,
                isDrawingMode: appState.isDrawingMode,
                selectedRoad: $selectedRoadForPopup,
                shouldCenterOnUser: $locationManager.shouldCenterOnUser,
                roadToCenter: $roadToCenter,
                userLocation: locationManager.location,
                onPathUpdate: { newPath in
                    appState.drawnPath = newPath
                },
                onMapTap: { coordinate in
                    if appState.isDrawingMode {
                        appState.drawnPath.append(Coordinate(coordinate: coordinate))
                        HapticManager.shared.draw()
                    }
                }
            )
            .ignoresSafeArea()

            // Overlay Controls
            VStack {
                // Top Bar
                topBar

                Spacer()

                // Bottom Controls
                bottomControls
            }

            // Snapping Overlay
            if appState.isSnapping {
                snappingOverlay
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            SearchSheetView(
                searchViewModel: searchViewModel,
                onLocationSelected: { result in
                    withAnimation {
                        position = .region(MKCoordinateRegion(
                            center: result.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        ))
                    }
                    showSearchSheet = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedRoadForPopup) { road in
            RoadDetailSheet(road: road)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: appState.selectedRoad) { _, newRoad in
            if let road = newRoad {
                // Center the map on the selected road and show its detail sheet
                roadToCenter = road
                selectedRoadForPopup = road
                // Clear the appState selection so it can be selected again
                appState.selectedRoad = nil
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // Search Button
            Button {
                showSearchSheet = true
                HapticManager.shared.buttonTap()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.primary)
                    Text("Search location...")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Theme.backgroundSecondary.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                )
            }

            // Location Button
            BrandedIconButton("location.fill", size: 44, style: .solid) {
                locationManager.centerOnUserLocation()
                HapticManager.shared.buttonTap()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Drawing Mode Info
            if appState.isDrawingMode {
                drawingModeCard
            }

            // Main Action Buttons
            HStack(spacing: 12) {
                if appState.isDrawingMode {
                    // Cancel Button
                    BrandedButton("Cancel", icon: "xmark", style: .danger) {
                        appState.stopDrawing()
                        appState.clearDrawing()
                    }

                    // Clear Path Button
                    if !appState.drawnPath.isEmpty {
                        BrandedIconButton("arrow.uturn.backward", size: 50, style: .solid) {
                            appState.clearDrawing()
                            HapticManager.shared.buttonTap()
                        }
                    }

                    Spacer()

                    // Done/Save Button
                    if appState.drawnPath.count >= 2 {
                        BrandedButton("Done", icon: "checkmark", style: .success) {
                            snapAndPrepareRating()
                        }
                    }
                } else {
                    // Start Ride Button
                    BrandedButton("Start Ride", icon: "location.fill", style: .success) {
                        locationManager.startRide()
                        appState.isRideTrackingActive = true
                    }

                    Spacer()

                    // Draw Road Button
                    BrandedButton("Draw Road", icon: "pencil.tip.crop.circle", style: .primary) {
                        appState.startDrawing()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 120) // Space for tab bar
    }

    // MARK: - Drawing Mode Card
    private var drawingModeCard: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                    Text("Drawing Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Text("\(appState.drawnPath.count) points")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.surface)
                    .clipShape(Capsule())
            }

            if !appState.drawnPath.isEmpty {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "road.lanes")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                        Text("Distance:")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Text(String(format: "%.2f km", appState.drawnPath.totalDistanceInKm()))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Spacer()

                    if appState.drawnPath.totalDistanceInKm() > 20 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Max 20km")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.danger)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(Theme.textMuted)
                    Text("Tap on the map to draw your road path")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.backgroundSecondary.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
        .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }

    // MARK: - Snapping Overlay
    private var snappingOverlay: some View {
        ZStack {
            Theme.background.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Animated loading indicator
                ZStack {
                    Circle()
                        .stroke(Theme.surface, lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Theme.primaryGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                }

                VStack(spacing: 8) {
                    Text("Snapping to road...")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)

                    Text("Finding the best match for your path")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            )
            .shadow(color: Theme.cardShadow, radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Actions

    private func snapAndPrepareRating() {
        appState.isSnapping = true
        HapticManager.shared.impact(.medium)

        Task {
            do {
                let snapped = try await RoadSnappingService.shared.snapToRoad(path: appState.drawnPath)
                await MainActor.run {
                    appState.snappedPath = snapped
                    appState.isSnapping = false
                    appState.stopDrawing()
                    appState.prepareForRating(road: nil)
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    appState.isSnapping = false
                    // Use original path if snapping fails
                    appState.prepareForRating(road: nil)
                    appState.showToast("Using original path (snapping failed)", type: .warning)
                    HapticManager.shared.warning()
                }
            }
        }
    }
}

// MARK: - Road Detail Sheet
struct RoadDetailSheet: View {
    let road: Road
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var roadStore: RoadStore
    @State private var ratings: [Rating] = []
    @State private var isLoadingRatings: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text(road.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.textPrimary)

                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "road.lanes")
                                    .foregroundStyle(Theme.primary)
                                Text(road.formattedDistance)
                            }
                            if let count = road.ratingCount, count > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Theme.warning)
                                    Text("\(count) ratings")
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top)

                    // Overall Rating
                    if road.overallRating > 0 {
                        overallRatingCard
                    }

                    // Rating Categories
                    if road.ratingCount ?? 0 > 0 {
                        ratingCategoriesCard
                    }

                    // Comments
                    if !ratings.isEmpty {
                        commentsSection
                    }

                    // Add Rating Button
                    BrandedFullWidthButton("Add Your Rating", icon: "plus.circle.fill", style: .primary) {
                        appState.prepareForRating(road: road)
                    }
                    .padding(.horizontal)

                    if let shareURL = road.shareURL {
                        ShareLink(item: shareURL) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Share Road")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(BrandedButton.ButtonStyle.secondary.textColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(BrandedButton.ButtonStyle.secondary.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: BrandedButton.ButtonStyle.secondary.shadowColor, radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Dismiss handled by sheet
                    }
                    .foregroundStyle(Theme.primary)
                }
            }
        }
        .task {
            await loadRatings()
        }
    }

    private var overallRatingCard: some View {
        VStack(spacing: 12) {
            Text("Overall Rating")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                Text(String(format: "%.1f", road.overallRating))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(road.ratingColor.color)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 3) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(road.overallRating.rounded()) ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundStyle(index < Int(road.overallRating.rounded()) ? Theme.warning : Theme.surface)
                        }
                    }
                    Text("out of 5")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    private var ratingCategoriesCard: some View {
        VStack(spacing: 16) {
            ForEach(RatingCategory.allCases) { category in
                let value = ratingValue(for: category)
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(category.color)
                        .frame(width: 28)

                    Text(category.title)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.surface)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(category.color)
                                .frame(width: geometry.size.width * (value / 5.0), height: 8)
                        }
                    }
                    .frame(width: 80, height: 8)

                    Text(String(format: "%.1f", value))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 32, alignment: .trailing)
                }
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
        .padding(.horizontal)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Comments")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal)

            ForEach(ratings.filter { $0.comment != nil && !$0.comment!.isEmpty }) { rating in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 3) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating.overallRating.rounded()) ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(index < Int(rating.overallRating.rounded()) ? Theme.warning : Theme.surface)
                            }
                        }
                        Spacer()
                        if let date = rating.createdAt {
                            Text(formatDate(date))
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    Text(rating.comment ?? "")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.surface)
                )
            }
            .padding(.horizontal)
        }
    }

    private func ratingValue(for category: RatingCategory) -> Double {
        switch category {
        case .twistiness: return road.avgTwistiness ?? 0
        case .surfaceCondition: return road.avgSurfaceCondition ?? 0
        case .funFactor: return road.avgFunFactor ?? 0
        case .scenery: return road.avgScenery ?? 0
        case .visibility: return road.avgVisibility ?? 0
        }
    }

    private func loadRatings() async {
        isLoadingRatings = true
        ratings = await roadStore.fetchRatings(for: road.id)
        isLoadingRatings = false
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    MapContainerView()
        .environmentObject(AppState())
        .environmentObject(LocationManager())
        .environmentObject(RoadStore())
}
