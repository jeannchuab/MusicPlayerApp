import AVFoundation
import Foundation

/// Minimal player-facing abstraction used by ``AVAudioPlaybackService``.
///
/// This keeps the production service testable without changing its public
/// ``AudioPlaybackService`` contract.
@MainActor
protocol AVPlayerControlling: AnyObject {

    // MARK: - Properties

    /// The current playback time in seconds.
    var currentTimeSeconds: Double { get }

    /// The loaded item duration in seconds, when available.
    var currentItemDurationSeconds: Double? { get }

    /// Indicates whether the underlying player is actively playing.
    var isPlaying: Bool { get }

    // MARK: - Methods

    /// Replaces the current player item with the provided URL.
    ///
    /// - Parameter url: The media URL that should become the active item.
    func replaceCurrentItem(with url: URL)

    /// Starts playback for the current item.
    func play()

    /// Pauses playback for the current item.
    func pause()

    /// Seeks to the provided playback time in seconds.
    ///
    /// - Parameter seconds: The target playback time.
    func seek(to seconds: Double)
}

/// An ``AudioPlaybackService`` implementation backed by `AVPlayer`.
@MainActor
final class AVAudioPlaybackService: AudioPlaybackService {

    // MARK: - Properties

    /// The underlying player responsible for audio playback.
    private let player: any AVPlayerControlling

    /// The current playback time in seconds.
    private(set) var currentTime: TimeInterval = 0

    /// The loaded track duration in seconds.
    private(set) var duration: TimeInterval = 0

    /// Indicates whether audio is currently playing.
    private(set) var isPlaying = false

    // MARK: - Initialization

    /// Creates an audio playback service backed by the provided player.
    ///
    /// - Parameter player: The player adapter used to perform playback operations.
    init(player: any AVPlayerControlling = SystemAVPlayerController()) {
        self.player = player
    }

    // MARK: - AudioPlaybackService

    /// Loads the provided preview URL into the player.
    ///
    /// - Parameter url: The song preview URL to load.
    func load(url: URL?) async throws {
        guard let url else {
            throw AppError.invalidURL
        }

        player.replaceCurrentItem(with: url)
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
        player.seek(to: safeTime)
        currentTime = safeTime
    }

    /// Synchronizes the exposed playback state with the underlying `AVPlayer`.
    func refresh() {
        currentTime = player.currentTimeSeconds.finiteValue(or: 0) ?? 0

        if let itemDuration = player.currentItemDurationSeconds?.finiteValue(or: nil) {
            duration = itemDuration
        }

        isPlaying = player.isPlaying
    }
}

/// Production adapter that bridges ``AVPlayer`` into ``AVPlayerControlling``.
@MainActor
private final class SystemAVPlayerController: AVPlayerControlling {

    // MARK: - Properties

    /// The concrete system player used for playback.
    private let player = AVPlayer()

    /// The current playback time in seconds.
    var currentTimeSeconds: Double {
        player.currentTime().seconds
    }

    /// The loaded item duration in seconds, when available.
    var currentItemDurationSeconds: Double? {
        player.currentItem?.duration.seconds
    }

    /// Indicates whether the underlying player is actively playing.
    var isPlaying: Bool {
        player.timeControlStatus == .playing
    }

    // MARK: - AVPlayerControlling

    /// Replaces the current player item with the provided URL.
    ///
    /// - Parameter url: The media URL that should become the active item.
    func replaceCurrentItem(with url: URL) {
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }

    /// Starts playback for the current item.
    func play() {
        player.play()
    }

    /// Pauses playback for the current item.
    func pause() {
        player.pause()
    }

    /// Seeks to the provided playback time in seconds.
    ///
    /// - Parameter seconds: The target playback time.
    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
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
