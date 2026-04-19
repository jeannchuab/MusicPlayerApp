import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var song: Song
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval
    @Published private(set) var errorMessage: String?
    @Published var isRepeating = false

    private let playbackService: any AudioPlaybackService
    private let playlist: [Song]

    init(song: Song, playlist: [Song] = [], playbackService: any AudioPlaybackService) {
        self.song = song
        self.playlist = Self.normalizedPlaylist(playlist, selectedSong: song)
        self.playbackService = playbackService
        duration = song.durationSeconds ?? 30
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    var currentTimeText: String {
        Self.formattedTime(currentTime)
    }

    var durationText: String {
        Self.formattedTime(duration)
    }

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

    func togglePlayPause() {
        isPlaying ? playbackService.pause() : playbackService.play()
        syncFromPlaybackService()
    }

    func startPlaybackProgressUpdates() async {
        while !Task.isCancelled {
            refreshPlaybackState()
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func pause() {
        playbackService.pause()
        syncFromPlaybackService()
    }

    func seek(toProgress progress: Double) {
        let safeProgress = min(max(progress, 0), 1)
        playbackService.seek(to: duration * safeProgress)
        syncFromPlaybackService()
    }

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

    func playNextTrack() async {
        guard let currentIndex, playlist.indices.contains(currentIndex + 1) else { return }
        await play(song: playlist[currentIndex + 1])
    }

    func toggleRepeat() {
        isRepeating.toggle()
    }

    func refreshPlaybackState() {
        playbackService.refresh()
        syncFromPlaybackService()

        if isRepeating && !isPlaying && duration > 0 && currentTime >= duration {
            playbackService.seek(to: 0)
            playbackService.play()
            syncFromPlaybackService()
        }
    }

    private func syncFromPlaybackService() {
        currentTime = playbackService.currentTime
        if playbackService.duration > 0 {
            duration = playbackService.duration
        }
        isPlaying = playbackService.isPlaying
    }

    private var currentIndex: Int? {
        playlist.firstIndex { $0.id == song.id }
    }

    private func replayCurrentTrack() async {
        playbackService.seek(to: 0)
        playbackService.play()
        syncFromPlaybackService()
    }

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

    static func formattedTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(Int(time.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
