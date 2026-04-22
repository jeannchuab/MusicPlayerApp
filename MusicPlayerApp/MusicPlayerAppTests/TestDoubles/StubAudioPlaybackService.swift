import Foundation
@testable import MusicPlayerApp

@MainActor
final class StubAudioPlaybackService: AudioPlaybackService {
    var currentTime: TimeInterval
    var duration: TimeInterval
    var isPlaying: Bool
    var loadError: Error?
    private(set) var loadedURL: URL?
    var seekRequests: [TimeInterval] = []
    var playRequestCount = 0

    init(currentTime: TimeInterval = 0, duration: TimeInterval = 30, isPlaying: Bool = false) {
        self.currentTime = currentTime
        self.duration = duration
        self.isPlaying = isPlaying
    }

    func load(url: URL?) async throws {
        if let loadError {
            throw loadError
        }

        guard let url else {
            throw AppError.invalidURL
        }

        loadedURL = url
    }

    func play() {
        playRequestCount += 1
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func seek(to time: TimeInterval) {
        seekRequests.append(time)
        currentTime = time
    }

    func refresh() {}
}
