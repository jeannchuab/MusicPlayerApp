import Foundation

/// The central repository that combines song search, album lookup, and playback history.
///
/// `SongRepository` is the single dependency injected into view models. The concrete
/// implementation (``CachedSongRepository``) coordinates an API client and a local cache.
/// All members are main-actor–isolated because the repository is consumed directly by SwiftUI view models.
@MainActor
protocol SongRepository: AnyObject {

    /// Searches for songs matching the given term.
    ///
    /// - Parameters:
    ///   - term: The free-text search query (artist, album, or track name).
    ///   - limit: The maximum number of results to return.
    ///   - offset: The number of results to skip, used for pagination.
    /// - Returns: A ``SearchPage`` containing the matched songs and pagination metadata.
    /// - Throws: An ``AppError`` if the network request or decoding fails.
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage

    /// Fetches the album matching the given iTunes collection identifier.
    ///
    /// - Parameter collectionId: The iTunes collection ID of the album to look up.
    /// - Returns: The fully populated ``Album`` including its ``Album/songs``.
    /// - Throws: An ``AppError`` if the network request or decoding fails.
    func lookupAlbum(collectionId: Int) async throws -> Album

    /// Returns the most recently played songs from the local store.
    ///
    /// - Parameter limit: The maximum number of songs to return, ordered from most to least recent.
    /// - Returns: An array of recently played ``Song`` values.
    /// - Throws: An error if the local store cannot be read.
    func recentlyPlayed(limit: Int) throws -> [Song]

    /// Records a song as recently played in the local store.
    ///
    /// - Parameter song: The song to persist to the playback history.
    /// - Throws: An error if the local store cannot be written to.
    func addRecentlyPlayed(_ song: Song) throws
}
