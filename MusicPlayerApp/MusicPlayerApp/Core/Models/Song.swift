import Foundation

/// A single music track with metadata sourced from the iTunes Search API.
struct Song: Identifiable, Sendable, Hashable {

    /// The iTunes track identifier.
    let id: Int

    /// The track title.
    let title: String

    /// The name of the performing artist.
    let artistName: String

    /// The iTunes collection identifier for the album this track belongs to, if available.
    let albumId: Int?

    /// The title of the album this track belongs to, if available.
    let albumTitle: String?

    /// A URL pointing to the track's cover artwork, if available.
    let artworkURL: URL?

    /// A URL to a 30-second audio preview of the track, if available.
    let previewURL: URL?

    /// A URL to the track page on the iTunes Store, if available.
    let trackViewURL: URL?

    /// The track duration in milliseconds as returned by the API.
    let durationMilliseconds: Int?

    /// The primary genre of the track (e.g. "Pop", "Rock").
    let genreName: String?

    /// The date the track was released on the iTunes Store.
    let releaseDate: Date?

    /// The position of this track within its album.
    let trackNumber: Int?

    /// The total number of tracks in the album this track belongs to.
    let trackCount: Int?

    /// The track duration converted to seconds, or `nil` if ``durationMilliseconds`` is not set.
    var durationSeconds: TimeInterval? {
        guard let durationMilliseconds else { return nil }
        return TimeInterval(durationMilliseconds) / 1_000
    }
}
