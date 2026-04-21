import Foundation

/// Builds iTunes API endpoint URLs used by the data layer.
enum ITunesEndpoint {

    // MARK: - Properties

    /// The URL scheme used for iTunes API requests.
    private static let scheme = "https"

    /// The API host used for iTunes requests.
    private static let host = DataLayer.apiHost

    // MARK: - Endpoints

    /// Builds the iTunes search endpoint URL for song queries.
    ///
    /// - Parameters:
    ///   - term: The search term entered by the user.
    ///   - limit: The maximum number of results requested.
    ///   - country: The storefront country code used for the query.
    static func search(term: String, limit: Int, country: String = "US") throws -> URL {
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
            URLQueryItem(name: "country", value: country)
        ]

        guard let url = components.url else { throw AppError.invalidURL }
        return url
    }

    /// Builds the iTunes lookup endpoint URL for an album collection.
    ///
    /// - Parameters:
    ///   - collectionId: The iTunes collection identifier for the album.
    ///   - country: The storefront country code used for the query.
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
