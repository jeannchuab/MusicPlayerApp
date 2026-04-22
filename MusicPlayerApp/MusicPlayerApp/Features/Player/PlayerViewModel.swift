import Combine
import Foundation

/// View model that manages player state, transport controls, and playlist navigation.
@MainActor
final class PlayerViewModel: ObservableObject {

    // MARK: - Supporting Types

    /// Describes whether the current song preview is stored locally for offline playback.
    enum PreviewStorageState: Equatable {

        // MARK: - Cases

        /// The preview is not currently cached on disk.
        case notStored

        /// A cache or removal operation is currently in progress.
        case storing

        /// The preview is currently cached on disk.
        case stored

        /// The last cache operation failed.
        case failed
    }

    // MARK: - Published Properties

    /// The song currently loaded in the player.
    @Published private(set) var song: Song

    /// Indicates whether playback is currently active.
    @Published private(set) var isPlaying = false

    /// The current playback time in seconds.
    @Published private(set) var currentTime: TimeInterval = 0

    /// The total duration of the current song in seconds.
    @Published private(set) var duration: TimeInterval

    /// The transient banner message that should be presented by the player UI.
    @Published private(set) var bannerMessage: String?

    /// Indicates whether repeat mode is currently enabled.
    @Published var isRepeating = false

    /// Indicates whether the current song preview is stored locally for offline playback.
    @Published private(set) var previewStorageState: PreviewStorageState

    // MARK: - Private Properties

    /// The playback service that performs audio operations.
    private let playbackService: any AudioPlaybackService

    /// The preview cache manager used to store and resolve offline preview files.
    private let previewCacheManager: any PreviewCacheManaging

    /// The monitor used to decide whether remote previews can be loaded.
    private let connectionMonitor: any NetworkConnectionMonitoring

    /// The normalized playlist used for previous and next navigation.
    private let playlist: [Song]

    /// Indicates whether the current song has been loaded into the playback service.
    private var hasLoadedCurrentSong = false

    // MARK: - Initialization

    /// Creates a new player view model.
    ///
    /// - Parameters:
    ///   - song: The song initially loaded in the player.
    ///   - playlist: The ordered songs used for previous and next navigation.
    ///   - playbackService: The playback service that performs audio operations.
    ///   - previewCacheManager: The preview cache manager used to store and resolve offline preview files.
    ///   - connectionMonitor: The monitor used to decide whether remote previews can be loaded.
    init(
        song: Song,
        playlist: [Song] = [],
        playbackService: any AudioPlaybackService,
        previewCacheManager: any PreviewCacheManaging,
        connectionMonitor: any NetworkConnectionMonitoring = NetworkConnectionMonitor.shared
    ) {
        self.song = song
        self.playlist = Self.normalizedPlaylist(playlist, selectedSong: song)
        self.playbackService = playbackService
        self.previewCacheManager = previewCacheManager
        self.connectionMonitor = connectionMonitor
        duration = song.durationSeconds ?? 30
        previewStorageState = Self.storageState(for: song.previewURL, using: previewCacheManager)
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

    /// The accessibility-friendly label describing the current preview cache state.
    var previewStorageLabel: String {
        switch previewStorageState {
        case .notStored:
            "Store preview offline"
        case .storing:
            "Updating offline preview"
        case .stored:
            "Remove offline preview"
        case .failed:
            "Retry storing preview offline"
        }
    }

    /// The SF Symbol name that matches the current preview cache state.
    var previewStorageSymbolName: String {
        switch previewStorageState {
        case .notStored, .failed:
            "arrow.down.circle"
        case .storing:
            "arrow.triangle.2.circlepath.circle"
        case .stored:
            "checkmark.circle.fill"
        }
    }

    // MARK: - Public Methods

    /// Loads the current song into the playback service.
    func load() async {
        guard canAttemptRemotePlayback(for: song) else {
            hasLoadedCurrentSong = false
            return
        }

        do {
            try await playbackService.load(url: resolvedPlaybackURL(for: song))
            syncFromPlaybackService()
            refreshPreviewStorageState()
            hasLoadedCurrentSong = true
        } catch let appError as AppError {
            hasLoadedCurrentSong = false
            maybePublishPlaybackUnavailableBanner(for: appError, song: song)
        } catch {
            hasLoadedCurrentSong = false
            publishBanner(AppError.unknown(error.localizedDescription).userMessage)
        }
    }

    /// Toggles playback between play and pause.
    func togglePlayPause() async {
        if isPlaying {
            playbackService.pause()
            syncFromPlaybackService()
            return
        }

        guard hasLoadedCurrentSong else {
            await loadAndStartCurrentSong()
            return
        }

        playbackService.play()
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

    /// Stores or removes the current song preview for offline playback.
    func toggleStoredState() async {
        guard previewStorageState != .storing else { return }

        switch previewStorageState {
        case .stored:
            do {
                try previewCacheManager.removeCachedPreview(for: song.previewURL)
                refreshPreviewStorageState()
                publishBanner("This song is no longer available offline")
            } catch let appError as AppError {
                previewStorageState = .failed
                publishBanner(appError.userMessage)
            } catch {
                previewStorageState = .failed
                publishBanner(AppError.unknown(error.localizedDescription).userMessage)
            }
        case .notStored, .failed:
            previewStorageState = .storing

            do {
                try await previewCacheManager.cachePreview(from: song.previewURL)
                refreshPreviewStorageState()
                publishBanner("This song is now available offline")
            } catch let appError as AppError {
                previewStorageState = .failed
                publishBanner(appError.userMessage)
            } catch {
                previewStorageState = .failed
                publishBanner(AppError.unknown(error.localizedDescription).userMessage)
            }
        case .storing:
            break
        }
    }

    /// Clears the current transient banner message after the view has consumed it.
    func clearBannerMessage() {
        bannerMessage = nil
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

    /// Refreshes the published preview storage state for the current song.
    private func refreshPreviewStorageState() {
        previewStorageState = Self.storageState(for: song.previewURL, using: previewCacheManager)
    }

    /// The index of the currently loaded song in the normalized playlist.
    private var currentIndex: Int? {
        playlist.firstIndex { $0.id == song.id }
    }

    /// Seeks back to the beginning of the current song and resumes playback.
    private func replayCurrentTrack() async {
        guard hasLoadedCurrentSong else {
            await loadAndStartCurrentSong()
            return
        }

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
        refreshPreviewStorageState()
        hasLoadedCurrentSong = false

        guard canAttemptRemotePlayback(for: nextSong) else { return }

        do {
            try await playbackService.load(url: resolvedPlaybackURL(for: nextSong))
            playbackService.seek(to: 0)
            playbackService.play()
            syncFromPlaybackService()
            refreshPreviewStorageState()
            hasLoadedCurrentSong = true
        } catch let appError as AppError {
            syncFromPlaybackService()
            maybePublishPlaybackUnavailableBanner(for: appError, song: nextSong)
        } catch {
            syncFromPlaybackService()
            publishBanner(AppError.unknown(error.localizedDescription).userMessage)
        }
    }

    /// Loads the current song and starts playback when remote access or a cached preview is available.
    private func loadAndStartCurrentSong() async {
        guard canAttemptRemotePlayback(for: song) else { return }

        do {
            try await playbackService.load(url: resolvedPlaybackURL(for: song))
            playbackService.play()
            syncFromPlaybackService()
            refreshPreviewStorageState()
            hasLoadedCurrentSong = true
        } catch let appError as AppError {
            syncFromPlaybackService()
            hasLoadedCurrentSong = false
            maybePublishPlaybackUnavailableBanner(for: appError, song: song)
        } catch {
            syncFromPlaybackService()
            hasLoadedCurrentSong = false
            publishBanner(AppError.unknown(error.localizedDescription).userMessage)
        }
    }

    /// Publishes a transient banner message for the player UI.
    ///
    /// - Parameter message: The message that should be rendered in the banner.
    private func publishBanner(_ message: String) {
        bannerMessage = message
    }

    /// Publishes an offline-unavailable banner when remote playback fails without a cached preview.
    ///
    /// - Parameters:
    ///   - appError: The playback error that occurred.
    ///   - song: The song whose preview failed to load.
    private func maybePublishPlaybackUnavailableBanner(for appError: AppError, song: Song) {
        guard case .transport = appError else { return }
        guard previewCacheManager.isPreviewCached(for: song.previewURL) == false else { return }
        publishOfflineUnavailableMessage()
    }

    /// Returns whether playback can proceed for the provided song using a cached preview or live internet access.
    ///
    /// - Parameter song: The song whose preview availability should be validated.
    /// - Returns: `true` when playback can proceed.
    private func canAttemptRemotePlayback(for song: Song) -> Bool {
        guard previewCacheManager.isPreviewCached(for: song.previewURL) == false else { return true }
        guard song.previewURL != nil else { return true }
        guard connectionMonitor.isConnected else {
            publishOfflineUnavailableMessage()
            return false
        }

        return true
    }

    /// Publishes the standard offline-unavailable feedback used when a preview has not been downloaded.
    private func publishOfflineUnavailableMessage() {
        let message = "This song is not available offline"
        publishBanner(message)
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

    /// Resolves the best playback URL for the provided song, preferring cached previews when available.
    ///
    /// - Parameter song: The song whose playback URL should be resolved.
    /// - Returns: A cached local file URL when present, otherwise the remote preview URL.
    private func resolvedPlaybackURL(for song: Song) -> URL? {
        previewCacheManager.cachedFileURL(for: song.previewURL) ?? song.previewURL
    }

    /// Derives the preview storage state for the provided remote URL.
    ///
    /// - Parameters:
    ///   - remoteURL: The remote preview URL used as the cache key.
    ///   - previewCacheManager: The preview cache manager used to inspect cached files.
    /// - Returns: The preview storage state that matches the current cache contents.
    private static func storageState(
        for remoteURL: URL?,
        using previewCacheManager: any PreviewCacheManaging
    ) -> PreviewStorageState {
        previewCacheManager.isPreviewCached(for: remoteURL) ? .stored : .notStored
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
