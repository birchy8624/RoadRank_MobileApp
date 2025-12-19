import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Theme.background, Theme.backgroundSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient glow effects
            Circle()
                .fill(Theme.primary.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -50, y: -100)

            Circle()
                .fill(Theme.secondary.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 80, y: 150)

            VStack(spacing: 40) {
                Spacer()

                // Logo with loading ring
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Theme.primary.opacity(0.2), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - Double(pulseScale))

                    // Spinning gradient ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Theme.primary,
                                    Theme.secondary,
                                    Theme.primary.opacity(0.3),
                                    Theme.primary
                                ]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringRotation))

                    // Inner glow circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.primary.opacity(0.3),
                                    Theme.primary.opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Logo icon
                    VStack(spacing: 4) {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(Theme.primaryGradient)

                        // Small road indicator dots
                        HStack(spacing: 4) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Theme.primary)
                                    .frame(width: 4, height: 4)
                                    .opacity(isAnimating ? 1.0 : 0.3)
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(index) * 0.15),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                VStack(spacing: 8) {
                    Text("RoadRank")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Theme.textSecondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Rate the roads you love")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .opacity(logoOpacity)

                Spacer()
                Spacer()

                // Loading indicator
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 60)
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Logo entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Start continuous animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = true
        }

        // Ring rotation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 1.5
        }
    }
}

#Preview {
    SplashScreenView()
}
