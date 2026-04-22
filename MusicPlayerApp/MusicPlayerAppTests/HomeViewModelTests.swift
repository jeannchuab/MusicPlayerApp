import Testing
@testable import MusicPlayerApp

@MainActor
struct HomeViewModelTests {
    @Test func initialLoadPublishesRecentlyPlayedWithoutSearching() async {
        let song = Song.stub()
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [Song.stub(id: 2)])
        let repository = StubSongRepository(searchResult: .success(page), recentlyPlayedSongs: [song])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.state == .loaded([song]))
        #expect(viewModel.visibleSongs == [song])
        #expect(repository.searchRequests.isEmpty)
    }

    @Test func initialLoadPublishesEmptyWhenThereAreNoRecentlyPlayedSongs() async {
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [Song.stub()])
        let repository = StubSongRepository(searchResult: .success(page))
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.state == .empty)
        #expect(repository.searchRequests.isEmpty)
    }

    @Test func initialLoadPublishesErrorWhenRecentlyPlayedFails() async {
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [Song.stub()])
        let repository = StubSongRepository(searchResult: .success(page))
        repository.recentlyPlayedError = AppError.transport("Offline")
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.state == .failed(.transport("Offline")))
    }

    @Test func searchPublishesLoadedSongs() async {
        let song = Song.stub()
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [song])
        let repository = StubSongRepository(searchResult: .success(page))
        let viewModel = HomeViewModel(repository: repository, initialSearchText: "demo")

        await viewModel.search()

        #expect(viewModel.state == .loaded([song]))
        #expect(repository.searchRequests.first?.term == "demo")
    }

    @Test func emptySearchPublishesEmptyWithoutCallingRepository() async {
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [.stub()])
        let repository = StubSongRepository(searchResult: .success(page))
        let viewModel = HomeViewModel(repository: repository, initialSearchText: "   ")

        await viewModel.search()

        #expect(viewModel.state == .empty)
        #expect(repository.searchRequests.isEmpty)
    }

    @Test func failedSearchPublishesErrorState() async {
        let repository = StubSongRepository(searchResult: .failure(AppError.transport("Offline")))
        let viewModel = HomeViewModel(repository: repository, initialSearchText: "demo")

        await viewModel.search()

        #expect(viewModel.state == .failed(.transport("Offline")))
    }

    @Test func selectingSongAddsItToRecentlyPlayed() async {
        let song = Song.stub()
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [song])
        let repository = StubSongRepository(searchResult: .success(page))
        let viewModel = HomeViewModel(repository: repository, initialSearchText: "demo")

        viewModel.select(song)

        #expect(viewModel.recentlyPlayed == [song])
        #expect(viewModel.selectedSong == song)
    }

    @Test func recordingPlaybackUpdatesVisibleRecentlyPlayedResultsWhenSearchIsEmpty() async {
        let firstSong = Song.stub(id: 1, title: "First")
        let nextSong = Song.stub(id: 2, title: "Next")
        let page = SearchPage(query: "demo", offset: 0, limit: 25, resultCount: 1, songs: [nextSong])
        let repository = StubSongRepository(searchResult: .success(page), recentlyPlayedSongs: [firstSong])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()
        viewModel.recordPlayback(for: nextSong)

        #expect(viewModel.recentlyPlayed == [nextSong, firstSong])
        #expect(viewModel.visibleSongs == [nextSong, firstSong])
        #expect(viewModel.state == .loaded([nextSong, firstSong]))
    }

    @Test func loadMoreRevealsNextSliceWithoutRequestingDuplicatePage() async {
        let songs = (1...60).map { Song.stub(id: $0, title: "Song \($0)") }
        let page = SearchPage(query: "demo", offset: 0, limit: 200, resultCount: songs.count, songs: songs)
        let repository = StubSongRepository(searchResult: .success(page))
        let viewModel = HomeViewModel(repository: repository, initialSearchText: "demo")

        await viewModel.search()
        #expect(viewModel.visibleSongs.count == 25)
        #expect(repository.searchRequests.count == 1)
        #expect(repository.searchRequests.first?.offset == 0)

        await viewModel.loadMoreIfNeeded(currentSong: songs[24])
        #expect(viewModel.visibleSongs.count == 50)
        #expect(viewModel.visibleSongs[25].id == songs[25].id)
        #expect(repository.searchRequests.count == 1)

        await viewModel.loadMoreIfNeeded(currentSong: songs[49])
        #expect(viewModel.visibleSongs.count == 60)
        #expect(viewModel.visibleSongs.last?.id == songs.last?.id)
        #expect(repository.searchRequests.count == 1)
    }
}
