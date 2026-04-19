import Foundation

enum ITunesEndpoint {
    private static let scheme = "https"
    private static let host = DataLayer.apiHost

    static func search(term: String, limit: Int, offset: Int, country: String = "US") throws -> URL {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { throw AppError.emptySearchTerm }

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "term", value: trimmedTerm),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "country", value: country)
        ]

        guard let url = components.url else { throw AppError.invalidURL }
        return url
    }

    static func albumLookup(collectionId: Int, country: String = "US") throws -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/lookup"
        components.queryItems = [
            URLQueryItem(name: "id", value: String(collectionId)),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: country)
        ]

        guard let url = components.url else { throw AppError.invalidURL }
        return url
    }
}
