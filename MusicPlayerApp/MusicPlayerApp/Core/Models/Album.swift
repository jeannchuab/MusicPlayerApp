import Foundation

/// A music album containing metadata and its track listing.
struct Album: Equatable, Identifiable, Sendable {

    /// The iTunes collection identifier.
    let id: Int

    /// The album title.
    let title: String

    /// The name of the album's primary artist.
    let artistName: String

    /// A URL pointing to the album's cover artwork, if available.
    let artworkURL: URL?

    /// The songs that belong to this album.
    let songs: [Song]
}
