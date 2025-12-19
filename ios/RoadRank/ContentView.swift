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
                CustomTabBar(selectedTab: $appState.selectedTab)
            }

            // Toast overlay
            if appState.showToast {
                ToastView(
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

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppState.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                TabBarButton(
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
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
    }
}

struct TabBarButton: View {
    let tab: AppState.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)

                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let type: AppState.ToastType

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(type.color)

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(RoadStore())
        .environmentObject(AppState())
}
