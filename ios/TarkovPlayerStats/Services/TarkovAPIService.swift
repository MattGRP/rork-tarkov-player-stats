import Foundation

nonisolated enum TarkovAPIError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case playerNotFound

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let msg): return "Network error: \(msg)"
        case .decodingError(let msg): return "Data error: \(msg)"
        case .playerNotFound: return "Player not found"
        }
    }
}

@Observable
final class TarkovAPIService {
    static let shared = TarkovAPIService()
    private let baseURL = "https://players.tarkov.dev/profile"
    private var cachedIndex: [String: String]?

    func fetchPlayerProfile(accountId: String) async throws -> PlayerProfile {
        guard let url = URL(string: "\(baseURL)/\(accountId).json") else {
            throw TarkovAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            throw TarkovAPIError.playerNotFound
        }

        do {
            return try JSONDecoder().decode(PlayerProfile.self, from: data)
        } catch {
            throw TarkovAPIError.decodingError(error.localizedDescription)
        }
    }

    func searchPlayers(name: String) async throws -> [(id: String, name: String)] {
        let index = try await fetchIndex()
        let query = name.lowercased()
        return index
            .filter { $0.value.lowercased().contains(query) }
            .map { (id: $0.key, name: $0.value) }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
            .prefix(50)
            .map { $0 }
    }

    private func fetchIndex() async throws -> [String: String] {
        if let cached = cachedIndex { return cached }

        guard let url = URL(string: "\(baseURL)/index.json") else {
            throw TarkovAPIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        do {
            let index = try JSONDecoder().decode([String: String].self, from: data)
            cachedIndex = index
            return index
        } catch {
            throw TarkovAPIError.decodingError(error.localizedDescription)
        }
    }
}
