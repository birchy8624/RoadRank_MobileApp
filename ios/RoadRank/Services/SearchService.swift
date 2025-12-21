import Foundation
import MapKit

// MARK: - Search Service
actor SearchService {
    static let shared = SearchService()

    private let nominatimURL = "https://nominatim.openstreetmap.org/search"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    // MARK: - Nominatim Search

    func search(query: String) async throws -> [LocationSearchResult] {
        guard !query.isEmpty else { return [] }

        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidQuery
        }

        let urlString = "\(nominatimURL)?q=\(encodedQuery)&format=json&limit=10&addressdetails=1"

        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("RoadRank-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // Fall back to MapKit on server error
                return try await searchWithMapKit(query: query)
            }

            let results = try JSONDecoder().decode([NominatimResult].self, from: data)
            return results.map { LocationSearchResult(nominatimResult: $0) }
        } catch is SearchError {
            throw SearchError.searchFailed(NSError(domain: "SearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Both search providers failed"]))
        } catch {
            // Fallback to Apple's MapKit search on any other error
            return try await searchWithMapKit(query: query)
        }
    }

    // MARK: - MapKit Search (Fallback)

    private func searchWithMapKit(query: String) async throws -> [LocationSearchResult] {
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
    case invalidQuery
    case invalidURL
    case serverError
    case searchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "Invalid search query"
        case .invalidURL:
            return "Invalid search URL"
        case .serverError:
            return "Search server error"
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
