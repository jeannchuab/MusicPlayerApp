import Foundation

@MainActor
final class CachedSongRepository: SongRepository {
    private let searchService: any MusicSearchService
    private let albumLookupService: any AlbumLookupService
    private let cacheStore: SongCacheStore

    init(
        searchService: any MusicSearchService,
        albumLookupService: any AlbumLookupService,
        cacheStore: SongCacheStore
    ) {
        self.searchService = searchService
        self.albumLookupService = albumLookupService
        self.cacheStore = cacheStore
    }

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

    func recentlyPlayed(limit: Int) throws -> [Song] {
        try cacheStore.recentlyPlayed(limit: limit)
    }

    func addRecentlyPlayed(_ song: Song) throws {
        try cacheStore.addRecentlyPlayed(song)
    }
}
