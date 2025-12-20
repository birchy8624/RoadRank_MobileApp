import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var roadStore: RoadStore
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingSettings: Bool = false
    @State private var showingAbout: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // Quick Stats
                    statsSection

                    // Menu Items
                    menuSection

                    // App Info
                    appInfoSection
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "car.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Road Explorer")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Finding the best driving roads")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Activity")
                .font(.headline)

            HStack(spacing: 12) {
                ProfileStatCard(
                    title: "My Roads",
                    value: "\(myRoads.count)",
                    icon: "map.fill",
                    color: .blue
                )

                ProfileStatCard(
                    title: "Total Distance",
                    value: totalDistance,
                    icon: "road.lanes",
                    color: .green
                )
            }

            HStack(spacing: 12) {
                ProfileStatCard(
                    title: "Total Ratings",
                    value: "\(totalRatings)",
                    icon: "star.fill",
                    color: .yellow
                )

                ProfileStatCard(
                    title: "Best Road",
                    value: String(format: "%.1f", topRoadRating),
                    icon: "trophy.fill",
                    color: .orange
                )
            }
        }
    }

    private var myRoads: [Road] {
        roadStore.roads.filter { $0.isMyRoad }
    }

    private var totalDistance: String {
        let total = myRoads.reduce(0) { $0 + $1.distanceInKm }
        if total >= 1000 {
            return String(format: "%.0f km", total)
        }
        return String(format: "%.1f km", total)
    }

    private var totalRatings: Int {
        myRoads.compactMap(\.ratingCount).reduce(0, +)
    }

    private var topRoadRating: Double {
        myRoads.map(\.overallRating).max() ?? 0
    }

    // MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: 0) {
            MenuRow(icon: "gearshape.fill", title: "Settings", color: .gray) {
                showingSettings = true
            }

            Divider().padding(.leading, 56)

            MenuRow(icon: "location.fill", title: "Location Permissions", color: .blue) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            Divider().padding(.leading, 56)

            MenuRow(icon: "star.fill", title: "Rate App", color: .yellow) {
                // Would open App Store review
                HapticManager.shared.notification(.success)
            }

            Divider().padding(.leading, 56)

            MenuRow(icon: "square.and.arrow.up", title: "Share App", color: .green) {
                // Would open share sheet
                HapticManager.shared.buttonTap()
            }

            Divider().padding(.leading, 56)

            MenuRow(icon: "info.circle.fill", title: "About", color: .cyan) {
                showingAbout = true
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.rear.road.lane")
                .font(.system(size: 32))
                .foregroundStyle(.blue.gradient)

            Text("RoadRank")
                .font(.headline)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Menu Row
struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @AppStorage("autoSnapToRoad") var autoSnapToRoad: Bool = true
    @AppStorage("showDistanceUnit") var showDistanceUnit: String = "km"

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle(isOn: $hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }

                    Toggle(isOn: $autoSnapToRoad) {
                        Label("Auto-snap to Road", systemImage: "road.lanes.curved.right")
                    }

                    Picker(selection: $showDistanceUnit) {
                        Text("Kilometers").tag("km")
                        Text("Miles").tag("mi")
                    } label: {
                        Label("Distance Unit", systemImage: "ruler")
                    }
                }

                Section("Location") {
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        Label("Location Settings", systemImage: "location.fill")
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        // Clear cache action
                        HapticManager.shared.notification(.warning)
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Location Settings View
struct LocationSettingsView: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(locationStatusText)
                        .foregroundStyle(.secondary)
                }

                if locationManager.authorizationStatus == .denied ||
                   locationManager.authorizationStatus == .restricted {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                }
            } header: {
                Text("Location Permission")
            } footer: {
                Text("RoadRank needs location access to show nearby roads and track your driving routes.")
            }

            Section("Background Tracking") {
                Toggle(isOn: .constant(locationManager.authorizationStatus == .authorizedAlways)) {
                    Label("Always Allow", systemImage: "location.fill")
                }
                .disabled(true)
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedWhenInUse: return "When In Use"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "car.rear.road.lane")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }

                        Text("RoadRank")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Description
                    VStack(spacing: 12) {
                        Text("Discover and rate the best driving roads")
                            .font(.headline)

                        Text("RoadRank helps driving enthusiasts find, rate, and share their favorite roads. Draw your route, snap it to real roads, and rate it on five key factors: Twistiness, Surface Condition, Fun Factor, Scenery, and Visibility.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "pencil.tip", title: "Draw Routes", description: "Draw your favorite roads directly on the map")
                        FeatureRow(icon: "road.lanes.curved.right", title: "Road Snapping", description: "Automatically snap to real road paths")
                        FeatureRow(icon: "star.fill", title: "Rate Roads", description: "Rate roads on 5 different criteria")
                        FeatureRow(icon: "person.2.fill", title: "Community", description: "See ratings from other drivers")
                    }
                    .padding(.horizontal)

                    // Links
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "https://github.com/birchy8624/RoadRank")!) {
                            Label("View on GitHub", systemImage: "link")
                                .font(.subheadline)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileView()
        .environmentObject(RoadStore())
        .environmentObject(LocationManager())
}
