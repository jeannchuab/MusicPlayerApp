import Foundation

/// A lightweight playback service used by previews and UI tests without real audio output.
@MainActor
final class SilentAudioPlaybackService: AudioPlaybackService {

    // MARK: - Properties

    /// The current playback time in seconds.
    private(set) var currentTime: TimeInterval = 0

    /// The simulated duration in seconds.
    private(set) var duration: TimeInterval = 30

    /// Indicates whether simulated playback is active.
    private(set) var isPlaying = false

    // MARK: - AudioPlaybackService

    /// Resets the simulated playback state.
    ///
    /// - Parameter url: The requested preview URL, ignored by the silent service.
    func load(url: URL?) async throws {
        currentTime = 0
        duration = 30
        isPlaying = false
    }

    /// Starts simulated playback.
    func play() {
        isPlaying = true
    }

    /// Pauses simulated playback.
    func pause() {
        isPlaying = false
    }

    /// Seeks the simulated playback time, clamped to the configured duration.
    ///
    /// - Parameter time: The target playback time in seconds.
    func seek(to time: TimeInterval) {
        currentTime = min(max(time, 0), duration)
    }

    /// Advances simulated playback while active and stops at the end of the duration.
    func refresh() {
        guard isPlaying else { return }
        currentTime = min(currentTime + 0.1, duration)
        if currentTime >= duration {
            isPlaying = false
        }
    }
}
