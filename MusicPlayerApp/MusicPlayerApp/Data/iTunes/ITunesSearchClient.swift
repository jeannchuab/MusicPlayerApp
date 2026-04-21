import Foundation

/// Live iTunes API client responsible for search queries and album lookups.
struct ITunesSearchClient: MusicSearchService, AlbumLookupService {
    /// The HTTP transport used to perform remote requests.
    private let httpClient: HTTPClient
    
    /// The JSON decoder shared across endpoint responses.
    private let decoder: JSONDecoder
    
    /// The fallback page size used when the caller provides an invalid limit.
    private let defaultLimit: Int

    /// Creates a new iTunes API client.
    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        decoder: JSONDecoder = JSONDecoder(),
        defaultLimit: Int = 25
    ) {
        self.httpClient = httpClient
        self.decoder = decoder
        self.defaultLimit = defaultLimit
    }

    /// Searches the iTunes catalog for tracks matching the provided term.
    func searchSongs(term: String, limit: Int = 25, offset: Int = 0) async throws -> SearchPage {
        let pageLimit = limit > 0 ? limit : defaultLimit
        let url = try ITunesEndpoint.search(term: term, limit: pageLimit, offset: offset)
        let data = try await requestData(url)
        let response: ITunesSearchResponseDTO = try decode(ITunesSearchResponseDTO.self, from: data)
        logSearchResponse(data, response: response, url: url)

        return SearchPage(
            query: term.trimmingCharacters(in: .whitespacesAndNewlines),
            offset: offset,
            limit: pageLimit,
            resultCount: response.resultCount,
            songs: response.results.map(ITunesMappers.mapSong)
        )
    }

    /// Fetches album details and tracks for the given collection identifier.
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

    /// Loads raw response data and decodes it into the requested response type.
    private func request<Response: Decodable>(_ url: URL) async throws -> Response {
        let data = try await requestData(url)
        return try decode(Response.self, from: data)
    }

    /// Performs the HTTP request and validates the status code before returning the raw payload.
    private func requestData(_ url: URL) async throws -> Data {
        do {
            let (data, response) = try await httpClient.data(from: url)
            guard 200..<300 ~= response.statusCode else {
                throw AppError.httpStatus(response.statusCode)
            }

            return data
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.transport(error.localizedDescription)
        }
    }

    /// Decodes raw JSON into the requested response type.
    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    /// Prints the raw search payload and decoded track URLs to help inspect API-side data issues during development.
    private func logSearchResponse(_ data: Data, response: ITunesSearchResponseDTO, url: URL) {
#if DEBUG
        let payload = String(data: data, encoding: .utf8) ?? "<unable to decode payload as UTF-8>"
        let trackURLs = response.results.enumerated().map { index, song in
            "[\(index)] trackId=\(song.trackId) name=\"\(song.trackName)\" trackViewUrl=\(song.trackViewUrl?.absoluteString ?? "nil")"
        }

        print(
            """
            [ITunesSearchClient] Search response
            URL: \(url.absoluteString)
            Result count: \(response.resultCount)
            Decoded trackViewUrl values:
            \(trackURLs.joined(separator: "\n"))
            Raw payload:
            \(payload)
            """
        )
#endif
    }
}
