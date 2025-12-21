import Foundation
import MapKit

// MARK: - Search Service
actor SearchService {
    static let shared = SearchService()

    private init() {}

    func search(query: String) async throws -> [LocationSearchResult] {
        guard !query.isEmpty else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems.map { LocationSearchResult(mapItem: $0) }
        } catch {
            throw SearchError.searchFailed(error)
        }
    }
}

// MARK: - Search Error
enum SearchError: LocalizedError {
    case searchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .searchFailed(let error):
            return "Search failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Search View Model
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [LocationSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var error: String?

    private var searchTask: Task<Void, Never>?
    private let searchService = SearchService.shared

    func search() {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }

        isSearching = true
        error = nil

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await searchService.search(query: query)
                if !Task.isCancelled {
                    self.results = searchResults
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                    self.results = []
                }
            }

            if !Task.isCancelled {
                self.isSearching = false
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        query = ""
        results = []
        error = nil
    }
}
