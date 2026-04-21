import Foundation

/// Defines the persistence operations used to cache searches, albums, and playback history.
@MainActor
protocol SongCacheStore: AnyObject {

    /// Returns the cached search page for the provided query and paging values, if present.
    ///
    /// - Parameters:
    ///   - query: The original search term.
    ///   - limit: The number of songs requested for the page.
    ///   - offset: The start offset of the requested page.
    func cachedSearchPage(query: String, limit: Int, offset: Int) throws -> SearchPage?

    /// Persists a search page in the cache.
    ///
    /// - Parameter page: The search page to persist.
    func saveSearchPage(_ page: SearchPage) throws

    /// Returns the cached album for the provided collection identifier, if present.
    ///
    /// - Parameter collectionId: The iTunes collection identifier for the album.
    func cachedAlbum(collectionId: Int) throws -> Album?

    /// Persists an album in the cache.
    ///
    /// - Parameter album: The album to persist.
    func saveAlbum(_ album: Album) throws

    /// Returns the most recently played songs up to the requested limit.
    ///
    /// - Parameter limit: The maximum number of songs to return.
    func recentlyPlayed(limit: Int) throws -> [Song]

    /// Adds a song to the recently played history.
    ///
    /// - Parameter song: The song that should be marked as recently played.
    func addRecentlyPlayed(_ song: Song) throws
}
