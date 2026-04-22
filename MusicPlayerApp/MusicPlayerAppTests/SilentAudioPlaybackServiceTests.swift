import Foundation
import Testing
@testable import MusicPlayerApp

/// Coverage tests for the silent playback service used in previews and UI tests.
@MainActor
struct SilentAudioPlaybackServiceTests {

    // MARK: - Tests

    @Test func loadResetsPlaybackState() async throws {
        let service = SilentAudioPlaybackService()
        service.play()
        service.seek(to: 12)

        try await service.load(url: URL(string: "https://example.com/sample.m4a"))

        #expect(service.currentTime == 0)
        #expect(service.duration == 30)
        #expect(service.isPlaying == false)
    }

    @Test func playAndPauseUpdatePlaybackState() {
        let service = SilentAudioPlaybackService()

        service.play()
        #expect(service.isPlaying)

        service.pause()
        #expect(service.isPlaying == false)
    }

    @Test func seekClampsTheRequestedTimeWithinTheDuration() {
        let service = SilentAudioPlaybackService()

        service.seek(to: -5)
        #expect(service.currentTime == 0)

        service.seek(to: 99)
        #expect(service.currentTime == 30)
    }

    @Test func refreshAdvancesPlaybackAndStopsAtTheEnd() {
        let service = SilentAudioPlaybackService()
        service.play()

        service.refresh()
        #expect(service.currentTime == 0.1)
        #expect(service.isPlaying)

        service.seek(to: 29.95)
        service.refresh()
        #expect(service.currentTime == 30)
        #expect(service.isPlaying == false)
    }
}
