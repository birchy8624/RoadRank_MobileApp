import SwiftUI

@main
struct RoadRankApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var roadStore = RoadStore()
    @StateObject private var appState = AppState()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(roadStore)
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .map
    @Published var isShowingRatingSheet: Bool = false
    @Published var selectedRoad: Road?
    @Published var isDrawingMode: Bool = false
    @Published var drawnPath: [Coordinate] = []
    @Published var snappedPath: [Coordinate]?
    @Published var isSnapping: Bool = false
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastType: ToastType = .info

    enum Tab: String, CaseIterable {
        case map = "Map"
        case discover = "Discover"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .map: return "map.fill"
            case .discover: return "magnifyingglass"
            case .profile: return "person.fill"
            }
        }
    }

    enum ToastType {
        case success, error, warning, info

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    func showToast(_ message: String, type: ToastType = .info) {
        toastMessage = message
        toastType = type
        withAnimation(.spring(response: 0.3)) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.3)) {
                self.showToast = false
            }
        }
    }

    func startDrawing() {
        isDrawingMode = true
        drawnPath = []
        snappedPath = nil
        HapticManager.shared.impact(.medium)
    }

    func stopDrawing() {
        isDrawingMode = false
        HapticManager.shared.impact(.light)
    }

    func clearDrawing() {
        drawnPath = []
        snappedPath = nil
    }

    func prepareForRating(road: Road?) {
        selectedRoad = road
        isShowingRatingSheet = true
    }
}
