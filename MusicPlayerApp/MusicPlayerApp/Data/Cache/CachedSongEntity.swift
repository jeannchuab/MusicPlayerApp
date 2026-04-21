import Foundation
import SwiftData

/// A persisted SwiftData representation of a ``Song`` used for search caching and playback history.
@Model
final class CachedSongEntity {

    // MARK: - Properties

    /// The unique track identifier for the cached song.
    @Attribute(.unique) var id: Int

    /// The song title.
    var title: String

    /// The name of the performing artist.
    var artistName: String

    /// The album collection identifier, when available.
    var albumId: Int?

    /// The album title, when available.
    var albumTitle: String?

    /// The artwork URL persisted as a string for SwiftData storage.
    var artworkURLString: String?

    /// The preview URL persisted as a string for SwiftData storage.
    var previewURLString: String?

    /// The iTunes track page URL persisted as a string for SwiftData storage.
    var trackViewURLString: String?

    /// The track duration in milliseconds.
    var durationMilliseconds: Int?

    /// The primary genre name for the song.
    var genreName: String?

    /// The release date of the song.
    var releaseDate: Date?

    /// The track position within its album.
    var trackNumber: Int?

    /// The total number of tracks in the album.
    var trackCount: Int?

    /// The timestamp associated with the cached song payload.
    var cachedAt: Date

    /// The timestamp used to order recently played songs.
    var recentlyPlayedAt: Date?

    // MARK: - Initialization

    /// Creates a cached song entity from a domain ``Song``.
    ///
    /// - Parameters:
    ///   - song: The song to persist in the cache.
    ///   - cachedAt: The timestamp associated with the cached payload.
    init(song: Song, cachedAt: Date = .now) {
        id = song.id
        title = song.title
        artistName = song.artistName
        albumId = song.albumId
        albumTitle = song.albumTitle
        artworkURLString = song.artworkURL?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        trackViewURLString = song.trackViewURL?.absoluteString
        durationMilliseconds = song.durationMilliseconds
        genreName = song.genreName
        releaseDate = song.releaseDate
        trackNumber = song.trackNumber
        trackCount = song.trackCount
        self.cachedAt = cachedAt
        recentlyPlayedAt = nil
    }

    // MARK: - Helpers

    /// Refreshes the cached values using the latest ``Song`` payload while preserving playback history.
    ///
    /// - Parameters:
    ///   - song: The latest song payload to persist.
    ///   - cachedAt: The timestamp associated with the updated cache entry.
    func update(with song: Song, cachedAt: Date = .now) {
        title = song.title
        artistName = song.artistName
        albumId = song.albumId
        albumTitle = song.albumTitle
        artworkURLString = song.artworkURL?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        trackViewURLString = song.trackViewURL?.absoluteString
        durationMilliseconds = song.durationMilliseconds
        genreName = song.genreName
        releaseDate = song.releaseDate
        trackNumber = song.trackNumber
        trackCount = song.trackCount
        self.cachedAt = cachedAt
    }

    /// Reconstructs the domain ``Song`` value from the cached fields.
    var song: Song {
        Song(
            id: id,
            title: title,
            artistName: artistName,
            albumId: albumId,
            albumTitle: albumTitle,
            artworkURL: artworkURLString.flatMap(URL.init(string:)),
            previewURL: previewURLString.flatMap(URL.init(string:)),
            trackViewURL: trackViewURLString.flatMap(URL.init(string:)),
            durationMilliseconds: durationMilliseconds,
            genreName: genreName,
            releaseDate: releaseDate,
            trackNumber: trackNumber,
            trackCount: trackCount
        )
    }
}
