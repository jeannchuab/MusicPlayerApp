import AVFoundation
import Foundation

@MainActor
final class AVAudioPlaybackService: AudioPlaybackService {
    private let player = AVPlayer()

    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPlaying = false

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

    func play() {
        player.play()
        isPlaying = true
        refresh()
    }

    func pause() {
        player.pause()
        isPlaying = false
        refresh()
    }

    func seek(to time: TimeInterval) {
        let safeTime = max(0, min(time, duration > 0 ? duration : time))
        player.seek(to: CMTime(seconds: safeTime, preferredTimescale: 600))
        currentTime = safeTime
    }

    func refresh() {
        currentTime = player.currentTime().seconds.finiteValue(or: 0) ?? 0

        if let itemDuration = player.currentItem?.duration.seconds.finiteValue(or: nil) {
            duration = itemDuration
        }

        isPlaying = player.timeControlStatus == .playing
    }
}

private extension Double {
    func finiteValue(or fallback: Double?) -> Double? {
        isFinite ? self : fallback
    }
}
