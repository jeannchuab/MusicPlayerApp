import Foundation

@MainActor
final class SilentAudioPlaybackService: AudioPlaybackService {
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 30
    private(set) var isPlaying = false

    func load(url: URL?) async throws {
        currentTime = 0
        duration = 30
        isPlaying = false
    }

    func play() {
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func seek(to time: TimeInterval) {
        currentTime = min(max(time, 0), duration)
    }

    func refresh() {
        guard isPlaying else { return }
        currentTime = min(currentTime + 0.1, duration)
        if currentTime >= duration {
            isPlaying = false
        }
    }
}
