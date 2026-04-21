import Foundation

/// Abstraction over audio playback, providing transport controls and timing information.
///
/// All members are main-actor–isolated because playback state is typically observed by SwiftUI views.
/// The concrete production implementation is ``AVAudioPlaybackService``.
@MainActor
protocol AudioPlaybackService: AnyObject {

    // MARK: - Properties

    /// The current playback position in seconds.
    var currentTime: TimeInterval { get }

    /// The total duration of the loaded audio track in seconds.
    var duration: TimeInterval { get }

    /// Whether audio is currently playing.
    var isPlaying: Bool { get }

    // MARK: - Methods

    /// Loads the audio track at the given URL, preparing it for playback.
    ///
    /// - Parameter url: The URL of the audio resource. Pass `nil` to clear the current track.
    /// - Throws: An error if the resource cannot be loaded.
    func load(url: URL?) async throws

    /// Begins or resumes playback of the loaded track.
    func play()

    /// Pauses playback, retaining the current position.
    func pause()

    /// Seeks to the specified time within the loaded track.
    ///
    /// - Parameter time: The target position in seconds.
    func seek(to time: TimeInterval)

    /// Re-reads the current playback position and duration, publishing updated values to observers.
    func refresh()
}
