import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var isAnimating = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "road.lanes.curved.right",
            title: "Discover Epic Roads",
            subtitle: "Found a Laguna Seca Corkscrew in the wild?\nA Mugello chicane on your commute?",
            highlight: "Find it."
        ),
        OnboardingPage(
            icon: "mappin.and.ellipse",
            title: "Mark Your Favorites",
            subtitle: "Draw the road on the map and save it.\nBuild your collection of the best drives.",
            highlight: "Mark it."
        ),
        OnboardingPage(
            icon: "star.bubble",
            title: "Rate & Share",
            subtitle: "Rate roads and help others discover\nthe best driving experiences.",
            highlight: "Share it."
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Theme.background
                .ignoresSafeArea()

            // Ambient glows
            Circle()
                .fill(Theme.primary.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: CGFloat(currentPage - 1) * 100, y: -200)
                .animation(.easeInOut(duration: 0.8), value: currentPage)

            Circle()
                .fill(Theme.secondary.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: CGFloat(1 - currentPage) * 80, y: 200)
                .animation(.easeInOut(duration: 0.8), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .frame(height: 44)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer()

                // Page indicators
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Theme.primary : Theme.surface)
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                    HapticManager.shared.impact(.medium)
                }) {
                    HStack(spacing: 10) {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Theme.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.notification(.success)
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let highlight: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @State private var iconScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            // Icon with glow
            ZStack {
                // Glow background
                Circle()
                    .fill(Theme.primary.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)

                // Icon container
                Circle()
                    .fill(Theme.backgroundSecondary)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.primary.opacity(0.5), Theme.secondary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Theme.primary.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Theme.primaryGradient)
                    .symbolEffect(.pulse, options: .repeating, isActive: isActive)
            }
            .scaleEffect(iconScale)

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)

                // Highlight text
                Text(page.highlight)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryGradient)
                    .padding(.top, 8)
            }
            .opacity(contentOpacity)
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { _, active in
            if active {
                animateIn()
            }
        }
        .onAppear {
            if isActive {
                animateIn()
            }
        }
    }

    private func animateIn() {
        iconScale = 0.8
        contentOpacity = 0

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            iconScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            contentOpacity = 1.0
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
