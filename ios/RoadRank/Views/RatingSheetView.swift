import SwiftUI

// MARK: - Rating Sheet View
struct RatingSheetView: View {
    let road: Road?
    let drawnPath: [Coordinate]

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var roadStore: RoadStore
    @Environment(\.dismiss) var dismiss

    // Form State
    @State private var roadName: String = ""
    @State private var twistiness: Int = 3
    @State private var surfaceCondition: Int = 3
    @State private var funFactor: Int = 3
    @State private var scenery: Int = 3
    @State private var visibility: Int = 3
    @State private var selectedWarnings: Set<RoadWarning> = []
    @State private var comment: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var isNewRoad: Bool {
        road == nil
    }

    var isValid: Bool {
        if isNewRoad {
            return !roadName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   drawnPath.count >= 2
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Road Name (for new roads)
                    if isNewRoad {
                        roadNameSection
                    }

                    // Rating Sliders
                    ratingSection

                    // Warnings
                    warningsSection

                    // Comment
                    commentSection

                    // Submit Button
                    submitButton
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Theme.background)
            .navigationTitle(isNewRoad ? "New Road" : "Add Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        appState.clearDrawing()
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            .toolbarBackground(Theme.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            if isNewRoad {
                // Mini map preview
                if !drawnPath.isEmpty {
                    MiniMapView(coordinates: drawnPath.map(\.clLocationCoordinate2D))
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                }

                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "road.lanes")
                            .foregroundStyle(Theme.primary)
                        Text(String(format: "%.2f km", drawnPath.totalDistanceInKm()))
                            .fontWeight(.semibold)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                            .foregroundStyle(Theme.secondary)
                        Text("\(drawnPath.count) points")
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            } else if let road = road {
                VStack(spacing: 12) {
                    Text(road.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)

                    if road.overallRating > 0 {
                        HStack(spacing: 12) {
                            Text(String(format: "%.1f", road.overallRating))
                                .font(.headline)
                                .foregroundStyle(road.ratingColor.color)

                            HStack(spacing: 3) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(road.overallRating.rounded()) ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundStyle(index < Int(road.overallRating.rounded()) ? Theme.warning : Theme.surface)
                                }
                            }

                            if let count = road.ratingCount {
                                Text("(\(count) ratings)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top)
    }

    // MARK: - Road Name Section
    private var roadNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "textformat")
                    .foregroundStyle(Theme.primary)
                Text("Road Name")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            TextField("Enter road name...", text: $roadName)
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)

            Text("Give your road a memorable name")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Rating Section
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.warning)
                Text("Ratings")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            BrandedRatingSliderRow(
                category: .twistiness,
                value: $twistiness
            )

            BrandedRatingSliderRow(
                category: .surfaceCondition,
                value: $surfaceCondition
            )

            BrandedRatingSliderRow(
                category: .funFactor,
                value: $funFactor
            )

            BrandedRatingSliderRow(
                category: .scenery,
                value: $scenery
            )

            BrandedRatingSliderRow(
                category: .visibility,
                value: $visibility
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Warnings Section
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.warning)
                Text("Warnings")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("Tap any warnings that apply to this road.")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)

            HStack(spacing: 12) {
                ForEach(RoadWarning.allCases) { warning in
                    WarningToggleButton(
                        warning: warning,
                        isSelected: selectedWarnings.contains(warning)
                    ) {
                        toggleWarning(warning)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Comment Section
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(Theme.secondary)
                Text("Comment (Optional)")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            TextEditor(text: $comment)
                .frame(height: 100)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)

            Text("Share your experience driving this road")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        BrandedFullWidthButton(
            isNewRoad ? "Create Road" : "Submit Rating",
            icon: isNewRoad ? "plus.circle.fill" : "star.fill",
            style: isValid ? .primary : .secondary,
            isLoading: isSubmitting
        ) {
            submitRating()
        }
        .disabled(!isValid || isSubmitting)
        .opacity(isValid ? 1 : 0.6)
    }

    // MARK: - Submit Action
    private func submitRating() {
        isSubmitting = true
        HapticManager.shared.impact(.medium)

        Task {
            var success = false

            if isNewRoad {
                // Create new road
                var input = NewRoadInput()
                input.name = roadName.trimmingCharacters(in: .whitespacesAndNewlines)
                input.path = drawnPath
                input.twistiness = twistiness
                input.surfaceCondition = surfaceCondition
                input.funFactor = funFactor
                input.scenery = scenery
                input.visibility = visibility
                input.comment = comment
                input.warnings = Array(selectedWarnings)

                success = await roadStore.createRoad(input)
            } else if let road = road {
                // Add rating to existing road
                var input = NewRatingInput(roadId: road.id)
                input.twistiness = twistiness
                input.surfaceCondition = surfaceCondition
                input.funFactor = funFactor
                input.scenery = scenery
                input.visibility = visibility
                input.comment = comment
                input.warnings = Array(selectedWarnings)

                success = await roadStore.submitRating(input)
            }

            await MainActor.run {
                isSubmitting = false

                if success {
                    HapticManager.shared.success()
                    appState.showToast(
                        isNewRoad ? "Road created successfully!" : "Rating submitted!",
                        type: .success
                    )
                    appState.clearDrawing()
                    dismiss()
                } else {
                    HapticManager.shared.error()
                    errorMessage = roadStore.error ?? "Failed to submit. Please try again."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Branded Rating Slider Row
struct BrandedRatingSliderRow: View {
    let category: RatingCategory
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(category.color)
                        .frame(width: 28)

                    Text(category.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(category.color)
                    .frame(width: 32)
            }

            // Custom Slider
            BrandedRatingSlider(value: $value, color: category.color)

            // Labels
            HStack {
                Text(category.lowDescription)
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                Text(category.highDescription)
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

// MARK: - Branded Rating Slider
struct BrandedRatingSlider: View {
    @Binding var value: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Theme.surface)
                    .frame(height: 8)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth(in: geometry), height: 8)

                // Dots
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { dotValue in
                        ZStack {
                            Circle()
                                .fill(dotValue <= value ? color : Theme.surface)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(dotValue == value ? color : .clear, lineWidth: 3)
                                        .frame(width: 28, height: 28)
                                )
                                .shadow(color: dotValue == value ? color.opacity(0.5) : .clear, radius: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                value = dotValue
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
            }
        }
        .frame(height: 36)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    updateValue(from: gesture)
                }
        )
    }

    private func fillWidth(in geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width
        let stepWidth = totalWidth / 5
        return stepWidth * CGFloat(value) - stepWidth / 2
    }

    private func updateValue(from gesture: DragGesture.Value) {
        let width = UIScreen.main.bounds.width - 80
        let stepWidth = width / 5
        let newValue = min(5, max(1, Int(gesture.location.x / stepWidth) + 1))

        if newValue != value {
            withAnimation(.spring(response: 0.2)) {
                value = newValue
            }
            HapticManager.shared.selection()
        }
    }

    private func toggleWarning(_ warning: RoadWarning) {
        if selectedWarnings.contains(warning) {
            selectedWarnings.remove(warning)
        } else {
            selectedWarnings.insert(warning)
        }
        HapticManager.shared.selection()
    }
}

// MARK: - Warning Toggle Button
struct WarningToggleButton: View {
    let warning: RoadWarning
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: warning.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.warning : Theme.textMuted)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Theme.warning.opacity(0.15) : Theme.surface)
                    )
                Text(warning.title)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rating Dots View
struct RatingDotsView: View {
    let rating: Int
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < rating ? color : Theme.surface)
                    .frame(width: size, height: size)
            }
        }
    }
}

#Preview {
    RatingSheetView(
        road: nil,
        drawnPath: [
            Coordinate(lat: 53.4, lng: -1.8),
            Coordinate(lat: 53.5, lng: -1.9)
        ]
    )
    .environmentObject(AppState())
    .environmentObject(RoadStore())
}
