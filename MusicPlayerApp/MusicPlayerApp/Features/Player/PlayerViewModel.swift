import Combine
import Foundation

/// View model that manages player state, transport controls, and playlist navigation.
@MainActor
final class PlayerViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The song currently loaded in the player.
    @Published private(set) var song: Song

    /// Indicates whether playback is currently active.
    @Published private(set) var isPlaying = false

    /// The current playback time in seconds.
    @Published private(set) var currentTime: TimeInterval = 0

    /// The total duration of the current song in seconds.
    @Published private(set) var duration: TimeInterval

    /// The user-facing playback error message, when one exists.
    @Published private(set) var errorMessage: String?

    /// Indicates whether repeat mode is currently enabled.
    @Published var isRepeating = false

    // MARK: - Private Properties

    /// The playback service that performs audio operations.
    private let playbackService: any AudioPlaybackService

    /// The normalized playlist used for previous and next navigation.
    private let playlist: [Song]

    // MARK: - Initialization

    /// Creates a new player view model.
    ///
    /// - Parameters:
    ///   - song: The song initially loaded in the player.
    ///   - playlist: The ordered songs used for previous and next navigation.
    ///   - playbackService: The playback service that performs audio operations.
    init(song: Song, playlist: [Song] = [], playbackService: any AudioPlaybackService) {
        self.song = song
        self.playlist = Self.normalizedPlaylist(playlist, selectedSong: song)
        self.playbackService = playbackService
        duration = song.durationSeconds ?? 30
    }

    // MARK: - Computed Properties

    /// The normalized progress value derived from the current playback time and duration.
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    /// The formatted current playback time.
    var currentTimeText: String {
        Self.formattedTime(currentTime)
    }

    /// The formatted total duration.
    var durationText: String {
        Self.formattedTime(duration)
    }

    // MARK: - Public Methods

    /// Loads the current song into the playback service.
    func load() async {
        do {
            try await playbackService.load(url: song.previewURL)
            syncFromPlaybackService()
            errorMessage = nil
        } catch let appError as AppError {
            errorMessage = appError.userMessage
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).userMessage
        }
    }

    /// Toggles playback between play and pause.
    func togglePlayPause() {
        isPlaying ? playbackService.pause() : playbackService.play()
        syncFromPlaybackService()
    }

    /// Starts the periodic loop that refreshes playback progress while the task is active.
    func startPlaybackProgressUpdates() async {
        while !Task.isCancelled {
            refreshPlaybackState()
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// Pauses playback and synchronizes published state.
    func pause() {
        playbackService.pause()
        syncFromPlaybackService()
    }

    /// Seeks playback using a normalized progress value.
    ///
    /// - Parameter progress: A value between `0` and `1` representing playback progress.
    func seek(toProgress progress: Double) {
        let safeProgress = min(max(progress, 0), 1)
        playbackService.seek(to: duration * safeProgress)
        syncFromPlaybackService()
    }

    /// Moves playback to the previous song in the playlist, or replays the current one when already at the start.
    func playPreviousTrack() async {
        guard let currentIndex else {
            await replayCurrentTrack()
            return
        }

        guard currentIndex > 0 else {
            await replayCurrentTrack()
            return
        }

        await play(song: playlist[currentIndex - 1])
    }

    /// Moves playback to the next song in the playlist when available.
    func playNextTrack() async {
        guard let currentIndex, playlist.indices.contains(currentIndex + 1) else { return }
        await play(song: playlist[currentIndex + 1])
    }

    /// Toggles repeat mode for the current song.
    func toggleRepeat() {
        isRepeating.toggle()
    }

    /// Refreshes published playback state and restarts playback when repeat is enabled at the end of the song.
    func refreshPlaybackState() {
        playbackService.refresh()
        syncFromPlaybackService()

        if isRepeating && !isPlaying && duration > 0 && currentTime >= duration {
            playbackService.seek(to: 0)
            playbackService.play()
            syncFromPlaybackService()
        }
    }

    // MARK: - Private Methods

    /// Synchronizes the published state with the underlying playback service.
    private func syncFromPlaybackService() {
        currentTime = playbackService.currentTime
        if playbackService.duration > 0 {
            duration = playbackService.duration
        }
        isPlaying = playbackService.isPlaying
    }

    /// The index of the currently loaded song in the normalized playlist.
    private var currentIndex: Int? {
        playlist.firstIndex { $0.id == song.id }
    }

    /// Seeks back to the beginning of the current song and resumes playback.
    private func replayCurrentTrack() async {
        playbackService.seek(to: 0)
        playbackService.play()
        syncFromPlaybackService()
    }

    /// Loads, starts, and publishes the provided song as the new current track.
    ///
    /// - Parameter nextSong: The song that should become the active track.
    private func play(song nextSong: Song) async {
        playbackService.pause()
        song = nextSong
        currentTime = 0
        duration = nextSong.durationSeconds ?? 30

        do {
            try await playbackService.load(url: nextSong.previewURL)
            playbackService.seek(to: 0)
            playbackService.play()
            syncFromPlaybackService()
            errorMessage = nil
        } catch let appError as AppError {
            syncFromPlaybackService()
            errorMessage = appError.userMessage
        } catch {
            syncFromPlaybackService()
            errorMessage = AppError.unknown(error.localizedDescription).userMessage
        }
    }

    /// Normalizes a playlist by removing duplicates and ensuring the selected song is included.
    ///
    /// - Parameters:
    ///   - playlist: The original playlist candidates.
    ///   - selectedSong: The song that must exist in the returned playlist.
    private static func normalizedPlaylist(_ playlist: [Song], selectedSong: Song) -> [Song] {
        var uniqueSongs: [Song] = []
        var seenIds = Set<Int>()

        for song in playlist {
            guard seenIds.insert(song.id).inserted else { continue }
            uniqueSongs.append(song)
        }

        if uniqueSongs.contains(where: { $0.id == selectedSong.id }) {
            return uniqueSongs
        }

        return [selectedSong] + uniqueSongs
    }

    /// Formats a playback time value into `m:ss`.
    ///
    /// - Parameter time: The playback time in seconds.
    static func formattedTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(Int(time.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
