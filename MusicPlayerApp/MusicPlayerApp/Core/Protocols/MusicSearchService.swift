import Foundation

/// A service that searches for songs by a free-text query.
///
/// Conforming types typically wrap a remote API (e.g. the iTunes Search API).
protocol MusicSearchService: Sendable {

    /// Searches for songs matching the given term.
    ///
    /// - Parameters:
    ///   - term: The free-text search query (artist, album, or track name).
    ///   - limit: The maximum number of results to return.
    ///   - offset: The number of results to skip, used for pagination.
    /// - Returns: A ``SearchPage`` containing the matched songs and pagination metadata.
    /// - Throws: An ``AppError`` if the network request or decoding fails.
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage
}
