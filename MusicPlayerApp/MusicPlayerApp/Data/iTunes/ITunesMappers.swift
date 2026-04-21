import Foundation

/// Converts iTunes DTOs into the app's domain models.
enum ITunesMappers {

    // MARK: - Properties

    /// The formatter used to parse ISO-8601 release date strings from the API.
    private static let releaseDateFormatter = ISO8601DateFormatter()

    // MARK: - Mapping

    /// Maps a single iTunes song DTO into a domain ``Song``.
    static func mapSong(_ dto: ITunesSongDTO) -> Song {
        Song(
            id: dto.trackId,
            title: dto.trackName,
            artistName: dto.artistName,
            albumId: dto.collectionId,
            albumTitle: dto.collectionName,
            artworkURL: upgradedArtworkURL(from: dto.artworkUrl100),
            previewURL: dto.previewUrl,
            trackViewURL: dto.trackViewUrl,
            durationMilliseconds: dto.trackTimeMillis,
            genreName: dto.primaryGenreName,
            releaseDate: dto.releaseDate.flatMap { releaseDateFormatter.date(from: $0) },
            trackNumber: dto.trackNumber,
            trackCount: dto.trackCount
        )
    }

    /// Maps album metadata plus its track list into a domain ``Album``.
    ///
    /// - Parameters:
    ///   - collection: The album metadata payload from the lookup response.
    ///   - songs: The track payloads associated with the album.
    ///   - fallbackCollectionId: The collection identifier used when the response omits album metadata.
    static func mapAlbum(collection: ITunesCollectionDTO?, songs: [ITunesSongDTO], fallbackCollectionId: Int) -> Album {
        let mappedSongs = songs.map(mapSong)
        let firstSong = mappedSongs.first

        return Album(
            id: collection?.collectionId ?? firstSong?.albumId ?? fallbackCollectionId,
            title: collection?.collectionName ?? firstSong?.albumTitle ?? "Album",
            artistName: collection?.artistName ?? firstSong?.artistName ?? "Unknown Artist",
            artworkURL: upgradedArtworkURL(from: collection?.artworkUrl100 ?? firstSong?.artworkURL),
            songs: mappedSongs
        )
    }

    // MARK: - Helpers

    /// Upgrades the default iTunes artwork URL to a larger asset when possible.
    ///
    /// - Parameter url: The original artwork URL returned by the API.
    static func upgradedArtworkURL(from url: URL?) -> URL? {
        guard let url else { return nil }

        let absoluteString = url.absoluteString
        let upgradedString = absoluteString
            .replacingOccurrences(of: "100x100bb", with: "600x600bb")
            .replacingOccurrences(of: "100x100-75", with: "600x600-75")

        return URL(string: upgradedString) ?? url
    }
}
