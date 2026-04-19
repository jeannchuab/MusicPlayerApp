import Foundation

struct SearchPage: Equatable, Sendable {
    let query: String
    let offset: Int
    let limit: Int
    let resultCount: Int
    let songs: [Song]

    var nextOffset: Int {
        offset + songs.count
    }

    var canRequestNextPage: Bool {
        songs.count == limit
    }
}
