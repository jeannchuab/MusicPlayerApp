import Foundation
import SwiftData

@Model
final class CachedSongEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var artistName: String
    var albumId: Int?
    var albumTitle: String?
    var artworkURLString: String?
    var previewURLString: String?
    var durationMilliseconds: Int?
    var genreName: String?
    var releaseDate: Date?
    var trackNumber: Int?
    var trackCount: Int?
    var cachedAt: Date
    var recentlyPlayedAt: Date?

    init(song: Song, cachedAt: Date = .now) {
        id = song.id
        title = song.title
        artistName = song.artistName
        albumId = song.albumId
        albumTitle = song.albumTitle
        artworkURLString = song.artworkURL?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        durationMilliseconds = song.durationMilliseconds
        genreName = song.genreName
        releaseDate = song.releaseDate
        trackNumber = song.trackNumber
        trackCount = song.trackCount
        self.cachedAt = cachedAt
        recentlyPlayedAt = nil
    }

    func update(with song: Song, cachedAt: Date = .now) {
        title = song.title
        artistName = song.artistName
        albumId = song.albumId
        albumTitle = song.albumTitle
        artworkURLString = song.artworkURL?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        durationMilliseconds = song.durationMilliseconds
        genreName = song.genreName
        releaseDate = song.releaseDate
        trackNumber = song.trackNumber
        trackCount = song.trackCount
        self.cachedAt = cachedAt
    }

    var song: Song {
        Song(
            id: id,
            title: title,
            artistName: artistName,
            albumId: albumId,
            albumTitle: albumTitle,
            artworkURL: artworkURLString.flatMap(URL.init(string:)),
            previewURL: previewURLString.flatMap(URL.init(string:)),
            durationMilliseconds: durationMilliseconds,
            genreName: genreName,
            releaseDate: releaseDate,
            trackNumber: trackNumber,
            trackCount: trackCount
        )
    }
}
