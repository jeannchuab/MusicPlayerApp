import Foundation

struct ITunesSearchClient: MusicSearchService, AlbumLookupService {
    private let httpClient: HTTPClient
    private let decoder: JSONDecoder
    private let defaultLimit: Int

    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        decoder: JSONDecoder = JSONDecoder(),
        defaultLimit: Int = 25
    ) {
        self.httpClient = httpClient
        self.decoder = decoder
        self.defaultLimit = defaultLimit
    }

    func searchSongs(term: String, limit: Int = 25, offset: Int = 0) async throws -> SearchPage {
        let pageLimit = limit > 0 ? limit : defaultLimit
        let url = try ITunesEndpoint.search(term: term, limit: pageLimit, offset: offset)
        let response: ITunesSearchResponseDTO = try await request(url)

        return SearchPage(
            query: term.trimmingCharacters(in: .whitespacesAndNewlines),
            offset: offset,
            limit: pageLimit,
            resultCount: response.resultCount,
            songs: response.results.map(ITunesMappers.mapSong)
        )
    }

    func lookupAlbum(collectionId: Int) async throws -> Album {
        let url = try ITunesEndpoint.albumLookup(collectionId: collectionId)
        let response: ITunesLookupResponseDTO = try await request(url)
        var collection: ITunesCollectionDTO?
        var songs: [ITunesSongDTO] = []

        for result in response.results {
            switch result {
            case .collection(let collectionDTO):
                collection = collectionDTO
            case .song(let songDTO):
                songs.append(songDTO)
            case .unsupported:
                continue
            }
        }

        return ITunesMappers.mapAlbum(
            collection: collection,
            songs: songs,
            fallbackCollectionId: collectionId
        )
    }

    private func request<Response: Decodable>(_ url: URL) async throws -> Response {
        do {
            let (data, response) = try await httpClient.data(from: url)
            guard 200..<300 ~= response.statusCode else {
                throw AppError.httpStatus(response.statusCode)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw AppError.decodingFailed
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.transport(error.localizedDescription)
        }
    }
}
