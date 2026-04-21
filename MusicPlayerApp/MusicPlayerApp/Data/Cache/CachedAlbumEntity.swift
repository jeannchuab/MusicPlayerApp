import Foundation
import SwiftData

/// A persisted SwiftData representation of an ``Album`` used for cached album lookups.
@Model
final class CachedAlbumEntity {

    // MARK: - Properties

    /// The unique collection identifier for the cached album.
    @Attribute(.unique) var id: Int

    /// The album title.
    var title: String

    /// The name of the album artist.
    var artistName: String

    /// The artwork URL persisted as a string for SwiftData storage.
    var artworkURLString: String?

    /// The comma-separated list of cached song identifiers belonging to the album.
    var songIDsString: String

    /// The timestamp associated with the cached album payload.
    var cachedAt: Date

    // MARK: - Initialization

    /// Creates a cached album entity from a domain ``Album``.
    ///
    /// - Parameters:
    ///   - album: The album to persist in the cache.
    ///   - cachedAt: The timestamp associated with the cached payload.
    init(album: Album, cachedAt: Date = .now) {
        id = album.id
        title = album.title
        artistName = album.artistName
        artworkURLString = album.artworkURL?.absoluteString
        songIDsString = album.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    // MARK: - Helpers

    /// Refreshes the cached values using the latest ``Album`` payload.
    ///
    /// - Parameters:
    ///   - album: The latest album payload to persist.
    ///   - cachedAt: The timestamp associated with the updated cache entry.
    func update(with album: Album, cachedAt: Date = .now) {
        title = album.title
        artistName = album.artistName
        artworkURLString = album.artworkURL?.absoluteString
        songIDsString = album.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    /// The cached song identifiers decoded from the stored comma-separated value.
    var songIDs: [Int] {
        songIDsString
            .split(separator: ",")
            .compactMap { Int($0) }
    }
}
