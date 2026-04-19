import Foundation
import SwiftData
import Testing
@testable import MusicPlayerApp

@MainActor
struct CachedSongRepositoryTests {
    @Test func returnsRemoteSearchAndCachesPage() async throws {
        let song = Song.stub(id: 42)
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [song])
        let remote = StubRemote(searchResult: .success(page), albumResult: .success(.stub()))
        let cache = try makeCache()
        let repository = CachedSongRepository(
            searchService: remote,
            albumLookupService: remote,
            cacheStore: cache
        )

        let result = try await repository.searchSongs(term: "demo", limit: 25, offset: 0)
        let cached = try cache.cachedSearchPage(query: "demo", limit: 25, offset: 0)

        #expect(result.songs == [song])
        #expect(cached?.songs == [song])
    }

    @Test func fallsBackToCachedSearchWhenRemoteFails() async throws {
        let song = Song.stub(id: 7)
        let cachedPage = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [song])
        let remote = StubRemote(searchResult: .failure(AppError.transport("Offline")), albumResult: .success(.stub()))
        let cache = try makeCache()
        try cache.saveSearchPage(cachedPage)
        let repository = CachedSongRepository(
            searchService: remote,
            albumLookupService: remote,
            cacheStore: cache
        )

        let result = try await repository.searchSongs(term: "demo", limit: 25, offset: 0)

        #expect(result == cachedPage)
    }

    @Test func fallsBackToCachedAlbumWhenRemoteFails() async throws {
        let album = Album.stub(id: 123, songs: [.stub(id: 8)])
        let remote = StubRemote(searchResult: .failure(AppError.transport("Offline")), albumResult: .failure(AppError.transport("Offline")))
        let cache = try makeCache()
        try cache.saveAlbum(album)
        let repository = CachedSongRepository(
            searchService: remote,
            albumLookupService: remote,
            cacheStore: cache
        )

        let result = try await repository.lookupAlbum(collectionId: 123)

        #expect(result == album)
    }

    @Test func savesRecentlyPlayedSongsMostRecentFirst() async throws {
        let first = Song.stub(id: 1, title: "First")
        let second = Song.stub(id: 2, title: "Second")
        let remote = StubRemote(searchResult: .failure(AppError.transport("Offline")), albumResult: .failure(AppError.transport("Offline")))
        let cache = try makeCache()
        let repository = CachedSongRepository(
            searchService: remote,
            albumLookupService: remote,
            cacheStore: cache
        )

        try repository.addRecentlyPlayed(first)
        try repository.addRecentlyPlayed(second)

        let recents = try repository.recentlyPlayed(limit: 2)

        #expect(recents.map(\.id) == [second.id, first.id])
    }

    private func makeCache() throws -> SwiftDataSongCacheStore {
        let schema = Schema([
            CachedSongEntity.self,
            CachedSearchPageEntity.self,
            CachedAlbumEntity.self
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )

        return SwiftDataSongCacheStore(context: ModelContext(container))
    }
}

private struct StubRemote: MusicSearchService, AlbumLookupService {
    let searchResult: Result<SearchPage, Error>
    let albumResult: Result<Album, Error>

    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage {
        try searchResult.get()
    }

    func lookupAlbum(collectionId: Int) async throws -> Album {
        try albumResult.get()
    }
}
