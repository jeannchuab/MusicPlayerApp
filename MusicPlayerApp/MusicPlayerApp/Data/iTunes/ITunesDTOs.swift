import Foundation

struct ITunesSearchResponseDTO: Decodable, Equatable {
    let resultCount: Int
    let results: [ITunesSongDTO]
}

struct ITunesLookupResponseDTO: Decodable, Equatable {
    let resultCount: Int
    let results: [ITunesLookupResultDTO]
}

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

struct ITunesCollectionDTO: Decodable, Equatable {
    let collectionId: Int
    let collectionName: String
    let artistName: String
    let artworkUrl100: URL?
}

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
    let trackTimeMillis: Int?
    let primaryGenreName: String?
    let releaseDate: String?
    let trackNumber: Int?
    let trackCount: Int?
}
