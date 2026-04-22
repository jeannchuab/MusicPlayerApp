import Foundation
import Testing
@testable import MusicPlayerApp

@MainActor
struct PlayerViewModelTests {
    @Test func loadDoNotStartsPlaybackWhenPreviewURLExists() async {
        let service = StubAudioPlaybackService(duration: 30)
        let song = Song.stub(previewURL: URL(string: "https://example.com/preview.m4a"))
        let cacheManager = StubPreviewCacheManager()
        let viewModel = PlayerViewModel(
            song: song,
            playbackService: service,
            previewCacheManager: cacheManager,
            connectionMonitor: StubNetworkConnectionMonitor(isConnected: true)
        )

        await viewModel.load()

        #expect(service.loadedURL == song.previewURL)
        #expect(viewModel.isPlaying == false)
    }

    @Test func loadPublishesErrorWhenPreviewURLIsMissing() async {
        let service = StubAudioPlaybackService()
        let song = Song.stub(previewURL: nil)
        let viewModel = PlayerViewModel(
            song: song,
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager()
        )

        await viewModel.load()

        #expect(viewModel.isPlaying == false)
    }

    @Test func seekUsesDurationAndClampsProgress() {
        let service = StubAudioPlaybackService(duration: 40)
        let viewModel = PlayerViewModel(
            song: .stub(durationMilliseconds: 40_000),
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager()
        )

        viewModel.seek(toProgress: 0.5)
        viewModel.seek(toProgress: 2)

        #expect(service.seekRequests == [20, 40])
        #expect(viewModel.currentTime == 40)
    }

    @Test func togglePlayPauseMirrorsServiceState() async {
        let service = StubAudioPlaybackService()
        let viewModel = PlayerViewModel(
            song: .stub(),
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager()
        )

        await viewModel.togglePlayPause()
        #expect(viewModel.isPlaying)

        await viewModel.togglePlayPause()
        #expect(viewModel.isPlaying == false)
    }

    @Test func formatsTimesForTimeline() {
        #expect(PlayerViewModel.formattedTime(0) == "0:00")
        #expect(PlayerViewModel.formattedTime(65) == "1:05")
    }

    @Test func computedPlaybackPropertiesReflectCurrentState() {
        let service = StubAudioPlaybackService(currentTime: 65, duration: 130)
        let viewModel = PlayerViewModel(
            song: .stub(durationMilliseconds: 130_000),
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager()
        )

        viewModel.refreshPlaybackState()

        #expect(viewModel.progress == 0.5)
        #expect(viewModel.currentTimeText == "1:05")
        #expect(viewModel.durationText == "2:10")
    }

    @Test func refreshPlaybackStateRepeatsTheCurrentSongWhenRepeatIsEnabled() {
        let service = StubAudioPlaybackService(currentTime: 30, duration: 30, isPlaying: false)
        let viewModel = PlayerViewModel(
            song: .stub(durationMilliseconds: 30_000),
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager()
        )
        viewModel.isRepeating = true

        viewModel.refreshPlaybackState()

        #expect(service.seekRequests == [0])
        #expect(service.playRequestCount == 1)
        #expect(viewModel.isPlaying)
        #expect(viewModel.currentTime == 0)
    }

    @Test func nextTrackLoadsAndPlaysNextSongFromPlaylist() async {
        let service = StubAudioPlaybackService(duration: 30)
        let songs = [
            Song.stub(id: 1, title: "One", previewURL: URL(string: "https://example.com/one.m4a")),
            Song.stub(id: 2, title: "Two", previewURL: URL(string: "https://example.com/two.m4a"))
        ]
        let cacheManager = StubPreviewCacheManager()
        let viewModel = PlayerViewModel(
            song: songs[0],
            playlist: songs,
            playbackService: service,
            previewCacheManager: cacheManager,
            connectionMonitor: StubNetworkConnectionMonitor(isConnected: true)
        )
        await viewModel.playNextTrack()

        #expect(viewModel.song == songs[1])
        #expect(service.loadedURL == songs[1].previewURL)
        #expect(service.seekRequests == [0])
        #expect(viewModel.isPlaying)
    }

    @Test func previousTrackLoadsAndPlaysPreviousSongFromPlaylist() async {
        let service = StubAudioPlaybackService(duration: 30)
        let songs = [
            Song.stub(id: 1, title: "One", previewURL: URL(string: "https://example.com/one.m4a")),
            Song.stub(id: 2, title: "Two", previewURL: URL(string: "https://example.com/two.m4a"))
        ]
        let cacheManager = StubPreviewCacheManager()
        let viewModel = PlayerViewModel(
            song: songs[1],
            playlist: songs,
            playbackService: service,
            previewCacheManager: cacheManager,
            connectionMonitor: StubNetworkConnectionMonitor(isConnected: true)
        )
        await viewModel.playPreviousTrack()

        #expect(viewModel.song == songs[0])
        #expect(service.loadedURL == songs[0].previewURL)
        #expect(service.seekRequests == [0])
        #expect(viewModel.isPlaying)
    }

    @Test func previousTrackReplaysCurrentSongWhenCurrentSongIsFirst() async {
        let service = StubAudioPlaybackService(currentTime: 12, duration: 30)
        let song = Song.stub(id: 1, title: "One")
        let viewModel = PlayerViewModel(
            song: song,
            playlist: [song],
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager(),
            connectionMonitor: StubNetworkConnectionMonitor(isConnected: true)
        )

        await viewModel.load()

        // Reset tracking state so assertions only reflect the replay action.
        service.seekRequests = []
        service.playRequestCount = 0
        service.currentTime = 12

        await viewModel.playPreviousTrack()

        #expect(viewModel.song == song)
        #expect(service.seekRequests == [0])
        #expect(service.playRequestCount == 1)
        #expect(viewModel.isPlaying)
    }

    @Test func loadPrefersCachedPreviewURLWhenAvailable() async throws {
        let service = StubAudioPlaybackService(duration: 30)
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let localURL = URL(fileURLWithPath: "/tmp/cached-preview.m4a")
        let cacheManager = StubPreviewCacheManager(
            cachedRemoteURLs: [remoteURL],
            localFileURLs: [remoteURL: localURL]
        )
        let viewModel = PlayerViewModel(
            song: .stub(previewURL: remoteURL),
            playbackService: service,
            previewCacheManager: cacheManager
        )

        await viewModel.load()

        #expect(service.loadedURL == localURL)
        #expect(viewModel.previewStorageState == .stored)
    }

    @Test func toggleStoredStateCachesPreviewWhenNotStored() async throws {
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let cacheManager = StubPreviewCacheManager()
        let viewModel = PlayerViewModel(
            song: .stub(previewURL: remoteURL),
            playbackService: StubAudioPlaybackService(),
            previewCacheManager: cacheManager
        )

        await viewModel.toggleStoredState()

        #expect(cacheManager.cacheRequests == [remoteURL])
        #expect(viewModel.previewStorageState == .stored)
    }

    @Test func toggleStoredStateRemovesCachedPreviewWhenStored() async throws {
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let cacheManager = StubPreviewCacheManager(cachedRemoteURLs: [remoteURL])
        let viewModel = PlayerViewModel(
            song: .stub(previewURL: remoteURL),
            playbackService: StubAudioPlaybackService(),
            previewCacheManager: cacheManager
        )

        await viewModel.toggleStoredState()

        #expect(cacheManager.removeRequests == [remoteURL])
        #expect(viewModel.previewStorageState == .notStored)
    }

    @Test func playNextTrackRefreshesStoredStateForNewSong() async throws {
        let service = StubAudioPlaybackService(duration: 30)
        let firstURL = try #require(URL(string: "https://example.com/one.m4a"))
        let secondURL = try #require(URL(string: "https://example.com/two.m4a"))
        let songs = [
            Song.stub(id: 1, title: "One", previewURL: firstURL),
            Song.stub(id: 2, title: "Two", previewURL: secondURL)
        ]
        let cacheManager = StubPreviewCacheManager(cachedRemoteURLs: [secondURL])
        let viewModel = PlayerViewModel(
            song: songs[0],
            playlist: songs,
            playbackService: service,
            previewCacheManager: cacheManager,
            connectionMonitor: StubNetworkConnectionMonitor(isConnected: true)
        )

        await viewModel.playNextTrack()

        #expect(viewModel.song == songs[1])
        #expect(viewModel.previewStorageState == .stored)
    }

    @Test func toggleStoredStatePublishesErrorsWhenCachingFails() async throws {
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let cacheManager = StubPreviewCacheManager()
        cacheManager.cacheError = AppError.transport("offline")
        let viewModel = PlayerViewModel(
            song: .stub(previewURL: remoteURL),
            playbackService: StubAudioPlaybackService(),
            previewCacheManager: cacheManager
        )

        await viewModel.toggleStoredState()

        #expect(viewModel.previewStorageState == .failed)
    }

    @Test func togglePlayPausePublishesOfflineBannerWhenPreviewIsNotAvailable() async throws {
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let service = StubAudioPlaybackService()
        let viewModel = PlayerViewModel(
            song: .stub(previewURL: remoteURL),
            playbackService: service,
            previewCacheManager: StubPreviewCacheManager(),
            connectionMonitor: StubNetworkConnectionMonitor(isConnected: false)
        )

        await viewModel.togglePlayPause()

        #expect(service.playRequestCount == 0)
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.bannerMessage == "This song is not available offline")
    }
}
