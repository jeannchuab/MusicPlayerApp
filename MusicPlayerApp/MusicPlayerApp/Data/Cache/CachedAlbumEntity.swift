import Foundation
import SwiftData

@Model
final class CachedAlbumEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var artistName: String
    var artworkURLString: String?
    var songIDsString: String
    var cachedAt: Date

    init(album: Album, cachedAt: Date = .now) {
        id = album.id
        title = album.title
        artistName = album.artistName
        artworkURLString = album.artworkURL?.absoluteString
        songIDsString = album.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    func update(with album: Album, cachedAt: Date = .now) {
        title = album.title
        artistName = album.artistName
        artworkURLString = album.artworkURL?.absoluteString
        songIDsString = album.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    var songIDs: [Int] {
        songIDsString
            .split(separator: ",")
            .compactMap { Int($0) }
    }
}
