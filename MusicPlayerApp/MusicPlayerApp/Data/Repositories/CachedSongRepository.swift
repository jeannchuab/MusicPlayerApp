import Foundation

/// A repository that prefers live iTunes data and falls back to local cache when needed.
@MainActor
final class CachedSongRepository: SongRepository {

    // MARK: - Properties

    /// The live service used for song search requests.
    private let searchService: any MusicSearchService

    /// The live service used for album lookup requests.
    private let albumLookupService: any AlbumLookupService

    /// The cache store used for persistence and fallback reads.
    private let cacheStore: SongCacheStore

    // MARK: - Initialization

    /// Creates a repository that combines live services with local caching.
    ///
    /// - Parameters:
    ///   - searchService: The live service used for song search requests.
    ///   - albumLookupService: The live service used for album lookup requests.
    ///   - cacheStore: The cache store used for persistence and fallback reads.
    init(
        searchService: any MusicSearchService,
        albumLookupService: any AlbumLookupService,
        cacheStore: SongCacheStore
    ) {
        self.searchService = searchService
        self.albumLookupService = albumLookupService
        self.cacheStore = cacheStore
    }

    // MARK: - SongRepository

    /// Searches for songs, caching successful responses and falling back to cached pages on failure.
    ///
    /// - Parameters:
    ///   - term: The search term entered by the user.
    ///   - limit: The maximum number of songs requested.
    ///   - offset: The start offset for the requested page.
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage {
        do {
            let page = try await searchService.searchSongs(term: term, limit: limit, offset: offset)
            try cacheStore.saveSearchPage(page)
            return page
        } catch {
            if let cachedPage = try? cacheStore.cachedSearchPage(query: term, limit: limit, offset: offset) {
                return cachedPage
            }

            throw error
        }
    }

    /// Looks up album details, caching successful responses and falling back to cache on failure.
    ///
    /// - Parameter collectionId: The iTunes collection identifier for the album.
    func lookupAlbum(collectionId: Int) async throws -> Album {
        do {
            let album = try await albumLookupService.lookupAlbum(collectionId: collectionId)
            try cacheStore.saveAlbum(album)
            return album
        } catch {
            if let cachedAlbum = try? cacheStore.cachedAlbum(collectionId: collectionId) {
                return cachedAlbum
            }

            throw error
        }
    }

    /// Returns the most recently played songs from the cache store.
    ///
    /// - Parameter limit: The maximum number of songs to return.
    func recentlyPlayed(limit: Int) throws -> [Song] {
        try cacheStore.recentlyPlayed(limit: limit)
    }

    /// Adds a song to the recently played history through the cache store.
    ///
    /// - Parameter song: The song that should be marked as recently played.
    func addRecentlyPlayed(_ song: Song) throws {
        try cacheStore.addRecentlyPlayed(song)
    }
}
