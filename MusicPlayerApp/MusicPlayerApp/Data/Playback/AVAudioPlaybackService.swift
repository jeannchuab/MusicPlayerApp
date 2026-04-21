import AVFoundation
import Foundation

/// An ``AudioPlaybackService`` implementation backed by `AVPlayer`.
@MainActor
final class AVAudioPlaybackService: AudioPlaybackService {

    // MARK: - Properties

    /// The underlying AVPlayer responsible for audio playback.
    private let player = AVPlayer()

    /// The current playback time in seconds.
    private(set) var currentTime: TimeInterval = 0

    /// The loaded track duration in seconds.
    private(set) var duration: TimeInterval = 0

    /// Indicates whether audio is currently playing.
    private(set) var isPlaying = false

    // MARK: - AudioPlaybackService

    /// Loads the provided preview URL into the player.
    ///
    /// - Parameter url: The song preview URL to load.
    func load(url: URL?) async throws {
        guard let url else {
            throw AppError.invalidURL
        }

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        currentTime = 0
        duration = 0
        isPlaying = false
        refresh()
    }

    /// Starts playback for the currently loaded item.
    func play() {
        player.play()
        isPlaying = true
        refresh()
    }

    /// Pauses playback for the current item.
    func pause() {
        player.pause()
        isPlaying = false
        refresh()
    }

    /// Seeks playback to the provided time, clamped to the current duration when known.
    ///
    /// - Parameter time: The target playback time in seconds.
    func seek(to time: TimeInterval) {
        let safeTime = max(0, min(time, duration > 0 ? duration : time))
        player.seek(to: CMTime(seconds: safeTime, preferredTimescale: 600))
        currentTime = safeTime
    }

    /// Synchronizes the exposed playback state with the underlying `AVPlayer`.
    func refresh() {
        currentTime = player.currentTime().seconds.finiteValue(or: 0) ?? 0

        if let itemDuration = player.currentItem?.duration.seconds.finiteValue(or: nil) {
            duration = itemDuration
        }

        isPlaying = player.timeControlStatus == .playing
    }
}

/// Helpers for sanitizing `AVPlayer` time values before exposing them to the UI.
private extension Double {
    /// Returns the receiver when it is finite, otherwise the provided fallback value.
    ///
    /// - Parameter fallback: The value returned when the receiver is not finite.
    func finiteValue(or fallback: Double?) -> Double? {
        isFinite ? self : fallback
    }
}
