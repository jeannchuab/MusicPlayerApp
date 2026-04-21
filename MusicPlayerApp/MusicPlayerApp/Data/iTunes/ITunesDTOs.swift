import Foundation

/// The top-level payload returned by the iTunes Search endpoint for song queries.
struct ITunesSearchResponseDTO: Decodable, Equatable {

    // MARK: - Properties

    /// The total number of results returned by the search request.
    let resultCount: Int

    /// The track results returned by the search request.
    let results: [ITunesSongDTO]
}

/// The top-level payload returned by the iTunes Lookup endpoint for albums.
struct ITunesLookupResponseDTO: Decodable, Equatable {

    // MARK: - Properties

    /// The total number of results returned by the lookup request.
    let resultCount: Int

    /// The collection and track results returned by the lookup request.
    let results: [ITunesLookupResultDTO]
}

/// A lookup result wrapper that can represent either album metadata or an individual track.
enum ITunesLookupResultDTO: Decodable, Equatable {

    // MARK: - Cases

    case collection(ITunesCollectionDTO)
    case song(ITunesSongDTO)
    case unsupported

    // MARK: - Supporting Types

    private enum CodingKeys: String, CodingKey {
        case wrapperType
    }

    // MARK: - Initialization

    /// Decodes a lookup result and maps it to the supported case for the wrapper type.
    ///
    /// - Parameter decoder: The decoder positioned at a lookup result payload.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wrapperType = try container.decodeIfPresent(String.self, forKey: .wrapperType)

        switch wrapperType {
        case "collection":
            self = .collection(try ITunesCollectionDTO(from: decoder))
        case "track":
            self = .song(try ITunesSongDTO(from: decoder))
        default:
            self = .unsupported
        }
    }
}

/// The album metadata returned by iTunes lookup responses.
struct ITunesCollectionDTO: Decodable, Equatable {

    // MARK: - Properties

    /// The iTunes collection identifier.
    let collectionId: Int

    /// The collection title.
    let collectionName: String

    /// The collection artist name.
    let artistName: String

    /// The artwork URL returned by the API for the collection.
    let artworkUrl100: URL?
}

/// The track metadata returned by iTunes search and lookup responses.
struct ITunesSongDTO: Decodable, Equatable {

    // MARK: - Properties

    /// The wrapper type reported by the API payload.
    let wrapperType: String?

    /// The media kind reported by the API payload.
    let kind: String?

    /// The iTunes track identifier.
    let trackId: Int

    /// The track title.
    let trackName: String

    /// The name of the performing artist.
    let artistName: String

    /// The collection identifier for the album, when available.
    let collectionId: Int?

    /// The album title, when available.
    let collectionName: String?

    /// The artwork URL returned by the API for the track.
    let artworkUrl100: URL?

    /// The preview audio URL, when available.
    let previewUrl: URL?

    /// The iTunes track page URL, when available.
    let trackViewUrl: URL?

    /// The track duration in milliseconds, when available.
    let trackTimeMillis: Int?

    /// The primary genre name, when available.
    let primaryGenreName: String?

    /// The release date string returned by the API, when available.
    let releaseDate: String?

    /// The track position within its album, when available.
    let trackNumber: Int?

    /// The total number of tracks in the album, when available.
    let trackCount: Int?
}
