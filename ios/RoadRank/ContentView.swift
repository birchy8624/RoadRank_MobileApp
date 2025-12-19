import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var roadStore: RoadStore

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appState.selectedTab) {
                MapContainerView()
                    .tag(AppState.Tab.map)

                DiscoverView()
                    .tag(AppState.Tab.discover)

                ProfileView()
                    .tag(AppState.Tab.profile)
            }
            .safeAreaInset(edge: .bottom) {
                BrandedTabBar(selectedTab: $appState.selectedTab)
            }

            // Toast overlay
            if appState.showToast {
                BrandedToastView(
                    message: appState.toastMessage,
                    type: appState.toastType
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $appState.isShowingRatingSheet) {
            RatingSheetView(
                road: appState.selectedRoad,
                drawnPath: appState.snappedPath ?? appState.drawnPath
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $appState.isRideTrackingActive) {
            RideTrackingView()
                .environmentObject(locationManager)
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showRideSummary) {
            if let ride = appState.finishedRide {
                RideSummaryView(ride: ride)
                    .environmentObject(appState)
                    .environmentObject(locationManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
            }
        }
        .onAppear {
            locationManager.requestPermission()
            Task {
                await roadStore.fetchRoads()
            }
        }
    }
}

// MARK: - Branded Tab Bar
struct BrandedTabBar: View {
    @Binding var selectedTab: AppState.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                BrandedTabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    HapticManager.shared.selection()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Theme.backgroundSecondary)
                .overlay(
                    Capsule()
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: Theme.cardShadow, radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }
}

struct BrandedTabBarButton: View {
    let tab: AppState.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Glow effect for selected
                    if isSelected {
                        Circle()
                            .fill(Theme.primary.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .symbolEffect(.bounce, value: isSelected)
                }

                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? Theme.primary : Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.primary.opacity(0.15) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Branded Toast View
struct BrandedToastView: View {
    let message: String
    let type: AppState.ToastType

    var body: some View {
        VStack {
            HStack(spacing: 14) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(type.color)
                }

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(type.color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Theme.cardShadow, radius: 15, x: 0, y: 8)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Legacy Toast View (for compatibility)
struct ToastView: View {
    let message: String
    let type: AppState.ToastType

    var body: some View {
        BrandedToastView(message: message, type: type)
    }
}

// MARK: - Legacy Custom Tab Bar (for compatibility)
struct CustomTabBar: View {
    @Binding var selectedTab: AppState.Tab

    var body: some View {
        BrandedTabBar(selectedTab: $selectedTab)
    }
}

struct TabBarButton: View {
    let tab: AppState.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        BrandedTabBarButton(tab: tab, isSelected: isSelected, action: action)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(RoadStore())
        .environmentObject(AppState())
}
