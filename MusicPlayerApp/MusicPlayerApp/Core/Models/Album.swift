import Foundation

struct Album: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let artistName: String
    let artworkURL: URL?
    let songs: [Song]
}
