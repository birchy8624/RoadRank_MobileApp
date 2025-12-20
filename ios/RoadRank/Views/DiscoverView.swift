import SwiftUI
import MapKit

// MARK: - Discover View
struct DiscoverView: View {
    @EnvironmentObject var roadStore: RoadStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager

    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .newest
    @State private var filterRating: Double = 0
    @State private var roadFilter: RoadFilter = .myRoads

    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case highestRated = "Highest Rated"
        case mostRated = "Most Rated"
        case nearest = "Nearest"
    }

    enum RoadFilter: String, CaseIterable {
        case myRoads = "My Roads"
        case allRoads = "All Roads"
    }

    var filteredRoads: [Road] {
        var result = roadStore.roads

        // Filter by road ownership
        switch roadFilter {
        case .myRoads:
            result = result.filter { $0.isMyRoad }
        case .allRoads:
            break // Show all roads
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { road in
                road.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by minimum rating
        if filterRating > 0 {
            result = result.filter { $0.overallRating >= filterRating }
        }

        // Sort
        switch sortOption {
        case .newest:
            result.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .highestRated:
            result.sort { $0.overallRating > $1.overallRating }
        case .mostRated:
            result.sort { ($0.ratingCount ?? 0) > ($1.ratingCount ?? 0) }
        case .nearest:
            if let userLocation = locationManager.location {
                result.sort { road1, road2 in
                    let center1 = road1.centerCoordinate ?? CLLocationCoordinate2D()
                    let center2 = road2.centerCoordinate ?? CLLocationCoordinate2D()
                    let dist1 = userLocation.distance(from: CLLocation(latitude: center1.latitude, longitude: center1.longitude))
                    let dist2 = userLocation.distance(from: CLLocation(latitude: center2.latitude, longitude: center2.longitude))
                    return dist1 < dist2
                }
            }
        }

        return result
    }

    var myRoadsCount: Int {
        roadStore.roads.filter { $0.isMyRoad }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Stats Header
                    statsHeader
                        .padding(.top, 12)

                    // Filter Pills
                    filterPills

                    // Road Cards
                    if filteredRoads.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredRoads) { road in
                            RoadCard(road: road) {
                                appState.selectedRoad = road
                                appState.selectedTab = .map
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search roads...")
            .refreshable {
                await roadStore.fetchRoads()
            }
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatCard(
                title: roadFilter == .myRoads ? "My Roads" : "All Roads",
                value: "\(filteredRoads.count)",
                icon: roadFilter == .myRoads ? "person.fill" : "road.lanes",
                color: .blue
            )

            StatCard(
                title: "Avg Rating",
                value: String(format: "%.1f", averageRating),
                icon: "star.fill",
                color: .yellow
            )

            StatCard(
                title: "Top Rated",
                value: String(format: "%.1f", topRating),
                icon: "trophy.fill",
                color: .orange
            )
        }
    }

    private var averageRating: Double {
        let roads = roadFilter == .myRoads ? roadStore.roads.filter { $0.isMyRoad } : roadStore.roads
        let ratingsWithValues = roads.filter { $0.overallRating > 0 }
        guard !ratingsWithValues.isEmpty else { return 0 }
        return ratingsWithValues.map(\.overallRating).reduce(0, +) / Double(ratingsWithValues.count)
    }

    private var topRating: Double {
        let roads = roadFilter == .myRoads ? roadStore.roads.filter { $0.isMyRoad } : roadStore.roads
        return roads.map(\.overallRating).max() ?? 0
    }

    // MARK: - Filter Pills
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Road Filter (My Roads / All Roads)
                ForEach(RoadFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter == .myRoads ? "\(filter.rawValue) (\(myRoadsCount))" : filter.rawValue,
                        isSelected: roadFilter == filter,
                        icon: filter == .myRoads ? "person.fill" : "globe"
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            roadFilter = filter
                        }
                        HapticManager.shared.selection()
                    }
                }

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)

                // Sort Options
                ForEach(SortOption.allCases, id: \.self) { option in
                    FilterPill(
                        title: option.rawValue,
                        isSelected: sortOption == option
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            sortOption = option
                        }
                        HapticManager.shared.selection()
                    }
                }

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)

                // Rating Filter
                FilterPill(
                    title: filterRating > 0 ? "\(Int(filterRating))+ Stars" : "All Ratings",
                    isSelected: filterRating > 0,
                    icon: "star.fill"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        filterRating = filterRating >= 4 ? 0 : filterRating + 1
                    }
                    HapticManager.shared.selection()
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: roadFilter == .myRoads ? "person.crop.circle.badge.questionmark" : "road.lanes")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text(roadFilter == .myRoads ? "No Roads Yet" : "No Roads Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text(roadFilter == .myRoads
                ? "You haven't added any roads yet. Start by drawing your first road!"
                : "Try adjusting your filters or be the first to add a road!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                appState.selectedTab = .map
                appState.startDrawing()
            } label: {
                Label("Draw a Road", systemImage: "pencil.tip.crop.circle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Road Card
struct RoadCard: View {
    let road: Road
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(road.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            // My Road badge
                            if road.isMyRoad {
                                Text("My Road")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 12) {
                            Label(road.formattedDistance, systemImage: "road.lanes")
                            if let count = road.ratingCount, count > 0 {
                                Label("\(count)", systemImage: "person.2.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Rating Badge
                    if road.overallRating > 0 {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", road.overallRating))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(road.ratingColor.color)

                            HStack(spacing: 1) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(index < Int(road.overallRating.rounded()) ? road.ratingColor.color : Color.gray.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                }

                // Rating Categories Preview
                if road.ratingCount ?? 0 > 0 {
                    HStack(spacing: 16) {
                        CategoryPreview(icon: "arrow.triangle.swap", value: road.avgTwistiness ?? 0, color: .purple)
                        CategoryPreview(icon: "road.lanes", value: road.avgSurfaceCondition ?? 0, color: .blue)
                        CategoryPreview(icon: "bolt.fill", value: road.avgFunFactor ?? 0, color: .orange)
                        CategoryPreview(icon: "mountain.2.fill", value: road.avgScenery ?? 0, color: .green)
                        CategoryPreview(icon: "eye.fill", value: road.avgVisibility ?? 0, color: .cyan)
                    }
                }

                // Mini Map Preview
                MiniMapView(coordinates: road.coordinates)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Preview
struct CategoryPreview: View {
    let icon: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(String(format: "%.1f", value))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Map View
struct MiniMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.mapType = .standard
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        guard coordinates.count >= 2 else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

        // Fit to polyline
        let rect = polyline.boundingMapRect
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mapView.setVisibleMapRect(rect, edgePadding: padding, animated: false)

        // Set delegate for rendering
        mapView.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 3
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(RoadStore())
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
