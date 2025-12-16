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

                    // Comment
                    commentSection

                    // Submit Button
                    submitButton
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle(isNewRoad ? "New Road" : "Add Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        appState.clearDrawing()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            if isNewRoad {
                // Mini map preview
                if !drawnPath.isEmpty {
                    MiniMapView(coordinates: drawnPath.map(\.clLocationCoordinate2D))
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack(spacing: 16) {
                    Label(String(format: "%.2f km", drawnPath.totalDistanceInKm()), systemImage: "road.lanes")
                    Label("\(drawnPath.count) points", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else if let road = road {
                VStack(spacing: 8) {
                    Text(road.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if road.overallRating > 0 {
                        HStack(spacing: 8) {
                            Text(String(format: "%.1f", road.overallRating))
                                .font(.headline)
                                .foregroundStyle(road.ratingColor.color)

                            RatingDotsView(rating: Int(road.overallRating.rounded()), color: .yellow)

                            if let count = road.ratingCount {
                                Text("(\(count) ratings)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Road Name")
                .font(.headline)

            TextField("Enter road name...", text: $roadName)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            Text("Give your road a memorable name")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Rating Section
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ratings")
                .font(.headline)

            RatingSliderRow(
                category: .twistiness,
                value: $twistiness
            )

            RatingSliderRow(
                category: .surfaceCondition,
                value: $surfaceCondition
            )

            RatingSliderRow(
                category: .funFactor,
                value: $funFactor
            )

            RatingSliderRow(
                category: .scenery,
                value: $scenery
            )

            RatingSliderRow(
                category: .visibility,
                value: $visibility
            )
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Comment Section
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comment (Optional)")
                .font(.headline)

            TextEditor(text: $comment)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            Text("Share your experience driving this road")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            submitRating()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: isNewRoad ? "plus.circle.fill" : "star.fill")
                    Text(isNewRoad ? "Create Road" : "Submit Rating")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? Color.accentColor : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isValid || isSubmitting)
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

// MARK: - Rating Slider Row
struct RatingSliderRow: View {
    let category: RatingCategory
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                    .frame(width: 24)

                Text(category.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(category.color)
            }

            // Custom Slider
            RatingSlider(value: $value, color: category.color)

            // Labels
            HStack {
                Text(category.lowDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(category.highDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Rating Slider
struct RatingSlider: View {
    @Binding var value: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 8)

                // Fill
                Capsule()
                    .fill(color.gradient)
                    .frame(width: fillWidth(in: geometry), height: 8)

                // Dots
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { dotValue in
                        Circle()
                            .fill(dotValue <= value ? color : Color(.systemGray4))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(dotValue == value ? color : .clear, lineWidth: 3)
                                    .frame(width: 24, height: 24)
                            )
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
        .frame(height: 32)
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
        let width = UIScreen.main.bounds.width - 64 // Approximate width
        let stepWidth = width / 5
        let newValue = min(5, max(1, Int(gesture.location.x / stepWidth) + 1))

        if newValue != value {
            withAnimation(.spring(response: 0.2)) {
                value = newValue
            }
            HapticManager.shared.selection()
        }
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
                    .fill(index < rating ? color : Color.gray.opacity(0.2))
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
