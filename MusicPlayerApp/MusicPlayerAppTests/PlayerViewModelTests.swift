import Foundation
import Testing
@testable import MusicPlayerApp

@MainActor
struct PlayerViewModelTests {
    @Test func loadDoNotStartsPlaybackWhenPreviewURLExists() async {
        let service = StubAudioPlaybackService(duration: 30)
        let song = Song.stub(previewURL: URL(string: "https://example.com/preview.m4a"))
        let viewModel = PlayerViewModel(song: song, playbackService: service)

        await viewModel.load()

        #expect(service.loadedURL == song.previewURL)
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadPublishesErrorWhenPreviewURLIsMissing() async {
        let service = StubAudioPlaybackService()
        let song = Song.stub(previewURL: nil)
        let viewModel = PlayerViewModel(song: song, playbackService: service)

        await viewModel.load()

        #expect(viewModel.isPlaying == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func seekUsesDurationAndClampsProgress() {
        let service = StubAudioPlaybackService(duration: 40)
        let viewModel = PlayerViewModel(
            song: .stub(durationMilliseconds: 40_000),
            playbackService: service
        )

        viewModel.seek(toProgress: 0.5)
        viewModel.seek(toProgress: 2)

        #expect(service.seekRequests == [20, 40])
        #expect(viewModel.currentTime == 40)
    }

    @Test func togglePlayPauseMirrorsServiceState() {
        let service = StubAudioPlaybackService()
        let viewModel = PlayerViewModel(song: .stub(), playbackService: service)

        viewModel.togglePlayPause()
        #expect(viewModel.isPlaying)

        viewModel.togglePlayPause()
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
            playbackService: service
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
            playbackService: service
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
        let viewModel = PlayerViewModel(song: songs[0], playlist: songs, playbackService: service)

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
        let viewModel = PlayerViewModel(song: songs[1], playlist: songs, playbackService: service)

        await viewModel.playPreviousTrack()

        #expect(viewModel.song == songs[0])
        #expect(service.loadedURL == songs[0].previewURL)
        #expect(service.seekRequests == [0])
        #expect(viewModel.isPlaying)
    }

    @Test func previousTrackReplaysCurrentSongWhenCurrentSongIsFirst() async {
        let service = StubAudioPlaybackService(currentTime: 12, duration: 30)
        let song = Song.stub(id: 1, title: "One")
        let viewModel = PlayerViewModel(song: song, playlist: [song], playbackService: service)

        await viewModel.playPreviousTrack()

        #expect(viewModel.song == song)
        #expect(service.loadedURL == nil)
        #expect(service.seekRequests == [0])
        #expect(service.playRequestCount == 1)
        #expect(viewModel.isPlaying)
    }
}
