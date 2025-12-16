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

    var body: some View {
        ZStack {
            // Main Map
            MapViewRepresentable(
                roads: roadStore.roads,
                drawnPath: appState.drawnPath,
                snappedPath: appState.snappedPath,
                isDrawingMode: appState.isDrawingMode,
                selectedRoad: $selectedRoadForPopup,
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
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // Search Button
            Button {
                showSearchSheet = true
                HapticManager.shared.buttonTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search location...")
                        .font(.subheadline)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }

            // Location Button
            Button {
                locationManager.centerOnUserLocation()
                HapticManager.shared.buttonTap()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
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
                    Button {
                        appState.stopDrawing()
                        appState.clearDrawing()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }

                    // Clear Path Button
                    if !appState.drawnPath.isEmpty {
                        Button {
                            appState.clearDrawing()
                            HapticManager.shared.buttonTap()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.orange)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    // Done/Save Button
                    if appState.drawnPath.count >= 2 {
                        Button {
                            snapAndPrepareRating()
                        } label: {
                            Label("Done", systemImage: "checkmark")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    Spacer()

                    // Draw Road Button
                    Button {
                        appState.startDrawing()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.tip.crop.circle")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Draw Road")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 100) // Space for tab bar
    }

    // MARK: - Drawing Mode Card
    private var drawingModeCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "hand.draw.fill")
                    .foregroundStyle(.blue)
                Text("Drawing Mode")
                    .font(.headline)
                Spacer()
                Text("\(appState.drawnPath.count) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !appState.drawnPath.isEmpty {
                HStack {
                    Text("Distance:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f km", appState.drawnPath.totalDistanceInKm()))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()

                    if appState.drawnPath.totalDistanceInKm() > 20 {
                        Label("Max 20km", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            } else {
                Text("Tap on the map to draw your road path")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    // MARK: - Snapping Overlay
    private var snappingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Snapping to road...")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Finding the best match for your path")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
                    VStack(spacing: 8) {
                        Text(road.displayName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label(road.formattedDistance, systemImage: "road.lanes")
                            if let count = road.ratingCount, count > 0 {
                                Label("\(count) ratings", systemImage: "star.fill")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                    Button {
                        appState.prepareForRating(road: road)
                    } label: {
                        Label("Add Your Rating", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // Dismiss handled by sheet
                    }
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
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(String(format: "%.1f", road.overallRating))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(road.ratingColor.color)

                VStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(road.overallRating.rounded()) ? "star.fill" : "star")
                                .foregroundStyle(index < Int(road.overallRating.rounded()) ? .yellow : .gray.opacity(0.3))
                        }
                    }
                    Text("out of 5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var ratingCategoriesCard: some View {
        VStack(spacing: 16) {
            ForEach(RatingCategory.allCases) { category in
                let value = ratingValue(for: category)
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                        .frame(width: 24)

                    Text(category.title)
                        .font(.subheadline)

                    Spacer()

                    RatingDotsView(rating: Int(value.rounded()), color: category.color)

                    Text(String(format: "%.1f", value))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Comments")
                .font(.headline)
                .padding(.horizontal)

            ForEach(ratings.filter { $0.comment != nil && !$0.comment!.isEmpty }) { rating in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        RatingDotsView(rating: Int(rating.overallRating.rounded()), color: .yellow)
                        Spacer()
                        if let date = rating.createdAt {
                            Text(formatDate(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(rating.comment ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
