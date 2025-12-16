import SwiftUI
import MapKit

// MARK: - Search Sheet View
struct SearchSheetView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    var onLocationSelected: (LocationSearchResult) -> Void

    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Results
                if searchViewModel.isSearching {
                    loadingView
                } else if let error = searchViewModel.error {
                    errorView(error)
                } else if searchViewModel.results.isEmpty && !searchViewModel.query.isEmpty {
                    emptyView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search for a location...", text: $searchViewModel.query)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        searchViewModel.search()
                    }

                if !searchViewModel.query.isEmpty {
                    Button {
                        searchViewModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onChange(of: searchViewModel.query) { _, _ in
            searchViewModel.search()
        }
    }

    // MARK: - Results List
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Recent/Popular locations header
                if searchViewModel.query.isEmpty {
                    popularLocationsSection
                }

                // Search Results
                ForEach(searchViewModel.results) { result in
                    SearchResultRow(result: result) {
                        HapticManager.shared.selection()
                        onLocationSelected(result)
                    }
                }
            }
        }
    }

    // MARK: - Popular Locations
    private var popularLocationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular UK Driving Areas")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 16)

            ForEach(popularLocations) { location in
                SearchResultRow(result: location) {
                    HapticManager.shared.selection()
                    onLocationSelected(location)
                }
            }
        }
    }

    private var popularLocations: [LocationSearchResult] {
        [
            LocationSearchResult(
                title: "Peak District",
                subtitle: "Derbyshire, England",
                coordinate: CLLocationCoordinate2D(latitude: 53.35, longitude: -1.8)
            ),
            LocationSearchResult(
                title: "Lake District",
                subtitle: "Cumbria, England",
                coordinate: CLLocationCoordinate2D(latitude: 54.45, longitude: -3.1)
            ),
            LocationSearchResult(
                title: "Scottish Highlands",
                subtitle: "Scotland",
                coordinate: CLLocationCoordinate2D(latitude: 57.0, longitude: -5.0)
            ),
            LocationSearchResult(
                title: "Snowdonia",
                subtitle: "Wales",
                coordinate: CLLocationCoordinate2D(latitude: 52.9, longitude: -3.9)
            ),
            LocationSearchResult(
                title: "North Yorkshire Moors",
                subtitle: "Yorkshire, England",
                coordinate: CLLocationCoordinate2D(latitude: 54.35, longitude: -0.9)
            )
        ]
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Search Error")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                searchViewModel.search()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No Results")
                .font(.headline)
            Text("Try searching for a different location")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: LocationSearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
            .padding(.leading, 68)
    }
}

// MARK: - Extension for custom initializer
extension LocationSearchResult {
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

    // Required private initializer workaround
    private init(id: UUID, title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

#Preview {
    SearchSheetView(searchViewModel: SearchViewModel()) { _ in }
}
