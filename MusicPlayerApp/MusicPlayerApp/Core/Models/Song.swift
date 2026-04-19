import Foundation

struct Song: Identifiable, Sendable, Hashable {
    let id: Int
    let title: String
    let artistName: String
    let albumId: Int?
    let albumTitle: String?
    let artworkURL: URL?
    let previewURL: URL?
    let durationMilliseconds: Int?
    let genreName: String?
    let releaseDate: Date?
    let trackNumber: Int?
    let trackCount: Int?
    
    //TODO: Add the trackViewUrl to share the music

    var durationSeconds: TimeInterval? {
        guard let durationMilliseconds else { return nil }
        return TimeInterval(durationMilliseconds) / 1_000
    }
}
