import SwiftUI

// MARK: - RoadRank Theme
struct Theme {
    // MARK: - Primary Brand Colors
    static let primary = Color(hex: "0EA5E9")        // Vibrant sky blue
    static let primaryDark = Color(hex: "0284C7")    // Darker blue
    static let secondary = Color(hex: "06B6D4")      // Cyan accent

    // MARK: - Action Colors
    static let success = Color(hex: "10B981")        // Emerald green
    static let successDark = Color(hex: "059669")    // Darker green
    static let warning = Color(hex: "F59E0B")        // Amber
    static let danger = Color(hex: "EF4444")         // Red
    static let dangerDark = Color(hex: "DC2626")     // Darker red

    // MARK: - Accent Colors
    static let purple = Color(hex: "8B5CF6")         // Violet
    static let pink = Color(hex: "EC4899")           // Pink
    static let orange = Color(hex: "F97316")         // Orange
    static let teal = Color(hex: "14B8A6")           // Teal

    // MARK: - Neutral Colors
    static let background = Color(hex: "0F172A")     // Dark navy
    static let backgroundSecondary = Color(hex: "1E293B")  // Slate
    static let surface = Color(hex: "334155")        // Slate surface
    static let surfaceLight = Color(hex: "475569")   // Lighter slate

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "94A3B8")  // Slate gray
    static let textMuted = Color(hex: "64748B")      // Muted gray

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [success, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dangerGradient = LinearGradient(
        colors: [danger, pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [purple, pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [orange, warning],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkGradient = LinearGradient(
        colors: [background, backgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Card Styles
    static let cardBackground = Color(hex: "1E293B").opacity(0.95)
    static let cardBorder = Color.white.opacity(0.1)
    static let cardShadow = Color.black.opacity(0.3)

    // MARK: - Glow Effects
    static func glow(_ color: Color, radius: CGFloat = 20) -> some View {
        color.blur(radius: radius)
    }
}

// MARK: - Color Extensions
extension Color {
    // Legacy Brand Colors (for compatibility)
    static let brandBlue = Theme.primary
    static let brandCyan = Theme.secondary
    static let brandGreen = Theme.success
    static let brandOrange = Theme.warning
    static let brandRed = Theme.danger
    static let brandPurple = Theme.purple

    // Gradient
    static let brandGradient = Theme.primaryGradient

    // Rating Colors
    static func ratingColor(for value: Double) -> Color {
        switch value {
        case 0..<2: return Theme.danger
        case 2..<3: return Theme.warning
        case 3..<4: return Theme.orange
        default: return Theme.success
        }
    }

    // Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }

    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
    }

    func brandedCard() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            )
            .shadow(color: Theme.cardShadow, radius: 15, x: 0, y: 8)
    }

    func glassCard() -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }

    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Theme.primaryGradient)
            .clipShape(Capsule())
            .shadow(color: Theme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .fontWeight(.medium)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Theme.surface)
            .clipShape(Capsule())
    }

    func dangerButtonStyle() -> some View {
        self
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Theme.dangerGradient)
            .clipShape(Capsule())
            .shadow(color: Theme.danger.opacity(0.4), radius: 10, x: 0, y: 5)
    }

    func successButtonStyle() -> some View {
        self
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Theme.successGradient)
            .clipShape(Capsule())
            .shadow(color: Theme.success.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.5),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                        .onAppear {
                            phase = 1
                        }
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Animation Extensions
extension Animation {
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

// MARK: - Branded Components

// Primary Action Button
struct BrandedButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, success, danger

        var gradient: LinearGradient {
            switch self {
            case .primary: return Theme.primaryGradient
            case .secondary: return LinearGradient(colors: [Theme.surface, Theme.surfaceLight], startPoint: .top, endPoint: .bottom)
            case .success: return Theme.successGradient
            case .danger: return Theme.dangerGradient
            }
        }

        var shadowColor: Color {
            switch self {
            case .primary: return Theme.primary.opacity(0.4)
            case .secondary: return Color.clear
            case .success: return Theme.success.opacity(0.4)
            case .danger: return Theme.danger.opacity(0.4)
            }
        }

        var textColor: Color {
            switch self {
            case .secondary: return Theme.textSecondary
            default: return .white
            }
        }
    }

    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(style.textColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(style.gradient)
            .clipShape(Capsule())
            .shadow(color: style.shadowColor, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// Full Width Button
struct BrandedFullWidthButton: View {
    let title: String
    let icon: String?
    let style: BrandedButton.ButtonStyle
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, style: BrandedButton.ButtonStyle = .primary, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(style.textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(style.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: style.shadowColor, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// Icon Button
struct BrandedIconButton: View {
    let icon: String
    let size: CGFloat
    let style: IconStyle
    let action: () -> Void

    enum IconStyle {
        case glass, solid, outline
    }

    init(_ icon: String, size: CGFloat = 44, style: IconStyle = .glass, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(backgroundView)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .glass:
            Color.white.opacity(0.15)
                .background(.ultraThinMaterial.opacity(0.5))
        case .solid:
            Theme.surface
        case .outline:
            Color.clear
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// Stat Display Card
struct BrandedStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Status Badge
struct BrandedBadge: View {
    let text: String
    let color: Color
    let isAnimated: Bool

    init(_ text: String, color: Color = Theme.success, isAnimated: Bool = false) {
        self.text = text
        self.color = color
        self.isAnimated = isAnimated
    }

    var body: some View {
        HStack(spacing: 8) {
            if isAnimated {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .shadow(color: color, radius: 4)
            }

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}
