import Foundation

/// The top-level payload returned by the iTunes Search endpoint for song queries.
struct ITunesSearchResponseDTO: Decodable, Equatable {
    let resultCount: Int
    let results: [ITunesSongDTO]
}

/// The top-level payload returned by the iTunes Lookup endpoint for albums.
struct ITunesLookupResponseDTO: Decodable, Equatable {
    let resultCount: Int
    let results: [ITunesLookupResultDTO]
}

/// A lookup result wrapper that can represent either album metadata or an individual track.
enum ITunesLookupResultDTO: Decodable, Equatable {
    case collection(ITunesCollectionDTO)
    case song(ITunesSongDTO)
    case unsupported

    private enum CodingKeys: String, CodingKey {
        case wrapperType
    }

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
    let collectionId: Int
    let collectionName: String
    let artistName: String
    let artworkUrl100: URL?
}

/// The track metadata returned by iTunes search and lookup responses.
struct ITunesSongDTO: Decodable, Equatable {
    let wrapperType: String?
    let kind: String?
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionId: Int?
    let collectionName: String?
    let artworkUrl100: URL?
    let previewUrl: URL?
    let trackViewUrl: URL?
    let trackTimeMillis: Int?
    let primaryGenreName: String?
    let releaseDate: String?
    let trackNumber: Int?
    let trackCount: Int?
}
