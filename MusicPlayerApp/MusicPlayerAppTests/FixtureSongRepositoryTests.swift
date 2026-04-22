import Testing
@testable import MusicPlayerApp

/// Coverage tests for the deterministic fixture repository used by previews and UI tests.
@MainActor
struct FixtureSongRepositoryTests {

    // MARK: - Tests

    @Test func searchSongsFiltersFixtureCatalogAndBuildsSearchPage() async throws {
        let repository = FixtureSongRepository()

        let page = try await repository.searchSongs(term: "neural", limit: 10, offset: 0)

        #expect(page.query == "neural")
        #expect(page.resultCount == 2)
        #expect(page.songs.map(\.title) == ["Midnight Signal", "Golden Static"])
    }

    @Test func lookupAlbumReturnsAlbumMetadataAndMatchingSongs() async throws {
        let repository = FixtureSongRepository()

        let album = try await repository.lookupAlbum(collectionId: 202)

        #expect(album.title == "Synthetic Bloom")
        #expect(album.artistName == "Nova Echo")
        #expect(album.songs.map(\.title) == ["Circuit Heart", "Soft Voltage"])
    }

    @Test func recentlyPlayedAndAddRecentlyPlayedKeepMostRecentOrder() throws {
        let repository = FixtureSongRepository()
        let song = Song.stub(id: 999, title: "Newest")

        try repository.addRecentlyPlayed(song)

        #expect(try repository.recentlyPlayed(limit: 2).map(\.title) == ["Newest", "Midnight Signal"])
    }

    @Test func emptyModeReturnsNoRecentlyPlayedSongsAndNoSearchResults() async throws {
        let repository = FixtureSongRepository(mode: .empty)

        let page = try await repository.searchSongs(term: "", limit: 10, offset: 0)

        #expect(page.songs.isEmpty)
        #expect(try repository.recentlyPlayed(limit: 10).isEmpty)
    }

    @Test func errorModeThrowsConsistentFixtureTransportErrors() async {
        let repository = FixtureSongRepository(mode: .error)

        await #expect(throws: AppError.transport("Fixture repository forced failure")) {
            _ = try await repository.searchSongs(term: "demo", limit: 10, offset: 0)
        }
    }
}
