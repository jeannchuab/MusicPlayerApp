import Foundation
import Testing
@testable import MusicPlayerApp

/// Coverage tests for the production playback service using a testable player adapter.
@MainActor
struct AVAudioPlaybackServiceTests {

    // MARK: - Tests

    @Test func loadResetsPublishedStateAndReplacesTheCurrentItem() async throws {
        let player = StubAVPlayerController()
        let service = AVAudioPlaybackService(player: player)
        let url = try #require(URL(string: "https://example.com/preview.m4a"))

        try await service.load(url: url)

        #expect(player.replacedURL == url)
        #expect(service.currentTime == 0)
        #expect(service.duration == 0)
        #expect(service.isPlaying == false)
    }

    @Test func loadThrowsWhenTheURLIsMissing() async {
        let service = AVAudioPlaybackService(player: StubAVPlayerController())

        await #expect(throws: AppError.invalidURL) {
            try await service.load(url: nil)
        }
    }

    @Test func playAndPauseMirrorTheUnderlyingPlayerState() {
        let player = StubAVPlayerController()
        let service = AVAudioPlaybackService(player: player)

        service.play()
        #expect(player.playCallCount == 1)
        #expect(service.isPlaying)

        service.pause()
        #expect(player.pauseCallCount == 1)
        #expect(service.isPlaying == false)
    }

    @Test func seekClampsToTheKnownDurationAndUpdatesCurrentTime() {
        let player = StubAVPlayerController()
        player.currentItemDurationSeconds = 15
        let service = AVAudioPlaybackService(player: player)
        service.refresh()

        service.seek(to: 50)

        #expect(player.seekRequests == [15])
        #expect(service.currentTime == 15)
    }

    @Test func refreshSynchronizesTimeDurationAndPlaybackState() {
        let player = StubAVPlayerController()
        player.currentTimeSeconds = 12
        player.currentItemDurationSeconds = 42
        player.isPlaying = true
        let service = AVAudioPlaybackService(player: player)

        service.refresh()

        #expect(service.currentTime == 12)
        #expect(service.duration == 42)
        #expect(service.isPlaying)
    }

    @Test func refreshIgnoresNonFiniteValuesWithoutCrashing() {
        let player = StubAVPlayerController()
        player.currentTimeSeconds = .nan
        player.currentItemDurationSeconds = .infinity
        let service = AVAudioPlaybackService(player: player)

        service.refresh()

        #expect(service.currentTime == 0)
        #expect(service.duration == 0)
    }
}

/// A controllable player test double used to exercise `AVAudioPlaybackService`.
@MainActor
private final class StubAVPlayerController: AVPlayerControlling {

    // MARK: - Properties

    /// The URL passed to the most recent `replaceCurrentItem` call.
    private(set) var replacedURL: URL?

    /// The recorded seek requests in seconds.
    private(set) var seekRequests: [Double] = []

    /// The number of times playback was started.
    private(set) var playCallCount = 0

    /// The number of times playback was paused.
    private(set) var pauseCallCount = 0

    /// The current playback time in seconds.
    var currentTimeSeconds: Double = 0

    /// The loaded item duration in seconds, when available.
    var currentItemDurationSeconds: Double?

    /// Indicates whether the underlying player is actively playing.
    var isPlaying = false

    // MARK: - AVPlayerControlling

    /// Replaces the current player item with the provided URL.
    ///
    /// - Parameter url: The media URL that should become the active item.
    func replaceCurrentItem(with url: URL) {
        replacedURL = url
    }

    /// Starts playback for the current item.
    func play() {
        playCallCount += 1
        isPlaying = true
    }

    /// Pauses playback for the current item.
    func pause() {
        pauseCallCount += 1
        isPlaying = false
    }

    /// Seeks to the provided playback time in seconds.
    ///
    /// - Parameter seconds: The target playback time.
    func seek(to seconds: Double) {
        seekRequests.append(seconds)
        currentTimeSeconds = seconds
    }
}
