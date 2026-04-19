import Foundation

@MainActor
protocol AudioPlaybackService: AnyObject {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }

    func load(url: URL?) async throws
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func refresh()
}
