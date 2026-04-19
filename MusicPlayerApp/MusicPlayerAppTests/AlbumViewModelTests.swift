import Testing
@testable import MusicPlayerApp

@MainActor
struct AlbumViewModelTests {
    @Test func loadPublishesAlbum() async {
        let album = Album.stub(id: 99, songs: [.stub(id: 1), .stub(id: 2)])
        let repository = StubSongRepository(
            searchResult: .failure(AppError.transport("Unused")),
            albumResult: .success(album)
        )
        let viewModel = AlbumViewModel(collectionId: 99, repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .loaded(album))
    }

    @Test func loadPublishesErrorWhenAlbumLookupFails() async {
        let repository = StubSongRepository(
            searchResult: .failure(AppError.transport("Unused")),
            albumResult: .failure(AppError.transport("Offline"))
        )
        let viewModel = AlbumViewModel(collectionId: 99, repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .failed(.transport("Offline")))
    }

    @Test func selectingSongAddsRecentlyPlayed() {
        let song = Song.stub(id: 3)
        let repository = StubSongRepository(
            searchResult: .failure(AppError.transport("Unused")),
            albumResult: .success(.stub())
        )
        let viewModel = AlbumViewModel(collectionId: 99, repository: repository)

        viewModel.select(song)

        #expect(viewModel.selectedSong == song)
        #expect((try? repository.recentlyPlayed(limit: 1)) == [song])
    }
}
