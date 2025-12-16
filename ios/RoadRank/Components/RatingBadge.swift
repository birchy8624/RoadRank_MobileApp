import SwiftUI

// MARK: - Rating Badge
struct RatingBadge: View {
    let rating: Double
    var showStars: Bool = true
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .headline
            case .large: return .title
            }
        }

        var starSize: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }
    }

    var ratingColor: Color {
        Color.ratingColor(for: rating)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", rating))
                .font(size.fontSize)
                .fontWeight(.bold)
                .foregroundStyle(ratingColor)

            if showStars {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < Int(rating.rounded()) ? ratingColor : Color.gray.opacity(0.2))
                            .frame(width: size.starSize, height: size.starSize)
                    }
                }
            }
        }
        .padding(size.padding)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Inline Rating
struct InlineRating: View {
    let rating: Double
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: index < Int(rating.rounded()) ? "star.fill" : "star")
                    .foregroundStyle(index < Int(rating.rounded()) ? .yellow : .gray.opacity(0.3))
                    .font(.caption)
            }

            Text(String(format: "%.1f", rating))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Category Rating Row
struct CategoryRatingRow: View {
    let category: RatingCategory
    let value: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
                .frame(width: 24)

            Text(category.title)
                .font(.subheadline)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color.gradient)
                        .frame(width: geometry.size.width * (value / 5), height: 8)
                }
            }
            .frame(width: 80, height: 8)

            Text(String(format: "%.1f", value))
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - Compact Category Rating
struct CompactCategoryRating: View {
    let category: RatingCategory
    let value: Double

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundStyle(category.color)

            Text(String(format: "%.1f", value))
                .font(.caption)
                .fontWeight(.bold)

            Text(category.title.prefix(3))
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Rating Badge") {
    VStack(spacing: 20) {
        RatingBadge(rating: 4.5, size: .small)
        RatingBadge(rating: 3.2, size: .medium)
        RatingBadge(rating: 2.1, size: .large)
    }
    .padding()
}

#Preview("Category Rating") {
    VStack(spacing: 12) {
        ForEach(RatingCategory.allCases) { category in
            CategoryRatingRow(category: category, value: Double.random(in: 1...5))
        }
    }
    .padding()
}
