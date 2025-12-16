import Foundation

// MARK: - API Configuration
enum APIConfig {
    #if DEBUG
    static let baseURL = "https://road-rank-mobile-app.vercel.app"
    #else
    static let baseURL = "https://road-rank-mobile-app.vercel.app"
    #endif

    static let timeout: TimeInterval = 30
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int, String?)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - API Client
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.timeoutIntervalForResource = APIConfig.timeout * 2
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Roads API

    func fetchRoads() async throws -> [Road] {
        let url = try makeURL(path: "/api/roads")
        let data = try await performRequest(url: url)

        do {
            let roads = try JSONDecoder().decode([Road].self, from: data)
            return roads
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createRoad(_ input: NewRoadInput) async throws -> Road {
        let url = try makeURL(path: "/api/roads")
        let body = input.toRoadPayload()

        let data = try await performRequest(url: url, method: "POST", body: body)

        do {
            let road = try JSONDecoder().decode(Road.self, from: data)
            return road
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Ratings API

    func fetchRatings(for roadId: String) async throws -> [Rating] {
        let url = try makeURL(path: "/api/roads/\(roadId)/ratings")
        let data = try await performRequest(url: url)

        do {
            let ratings = try JSONDecoder().decode([Rating].self, from: data)
            return ratings
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func submitRating(_ input: NewRatingInput) async throws -> Rating {
        let url = try makeURL(path: "/api/roads/\(input.roadId)/ratings")
        let body = input.toPayload()

        let data = try await performRequest(url: url, method: "POST", body: body)

        do {
            let rating = try JSONDecoder().decode(Rating.self, from: data)
            return rating
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Private Helpers

    private func makeURL(path: String) throws -> URL {
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        return url
    }

    private func performRequest(
        url: URL,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("RoadRank-iOS/1.0", forHTTPHeaderField: "User-Agent")

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, message)
            }

            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Road Store (ObservableObject for SwiftUI)
@MainActor
class RoadStore: ObservableObject {
    @Published var roads: [Road] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let apiClient = APIClient.shared

    func fetchRoads() async {
        isLoading = true
        error = nil

        do {
            roads = try await apiClient.fetchRoads()
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch roads: \(error)")
        }

        isLoading = false
    }

    func createRoad(_ input: NewRoadInput) async -> Bool {
        isLoading = true
        error = nil

        do {
            let newRoad = try await apiClient.createRoad(input)
            roads.insert(newRoad, at: 0)
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            print("Failed to create road: \(error)")
            isLoading = false
            return false
        }
    }

    func submitRating(_ input: NewRatingInput) async -> Bool {
        isLoading = true
        error = nil

        do {
            _ = try await apiClient.submitRating(input)
            // Refresh roads to get updated ratings
            await fetchRoads()
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            print("Failed to submit rating: \(error)")
            isLoading = false
            return false
        }
    }

    func fetchRatings(for roadId: String) async -> [Rating] {
        do {
            return try await apiClient.fetchRatings(for: roadId)
        } catch {
            print("Failed to fetch ratings: \(error)")
            return []
        }
    }

    func road(withId id: String) -> Road? {
        roads.first { $0.id == id }
    }
}
