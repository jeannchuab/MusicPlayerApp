import Foundation
import Testing
@testable import MusicPlayerApp

@MainActor
struct ITunesSearchClientTests {
    @Test func searchURLContainsExpectedParameters() throws {
        let url = try ITunesEndpoint.search(term: "jack johnson", limit: 25)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })

        #expect(components.scheme == "https")
        #expect(components.host == "itunes.apple.com")
        #expect(components.path == "/search")
        #expect(queryItems["term"] == "jack johnson")
        #expect(queryItems["media"] == "music")
        #expect(queryItems["entity"] == "song")
        #expect(queryItems["limit"] == "25")
        #expect(queryItems["offset"] == "50")
        #expect(queryItems["country"] == "US")
    }

    @Test func searchURLRejectsEmptyTerm() throws {
        #expect(throws: AppError.emptySearchTerm) {
            _ = try ITunesEndpoint.search(term: "   ", limit: 25)
        }
    }

    @Test func decodesAndMapsSearchResults() async throws {
        let client = ITunesSearchClient(httpClient: StubHTTPClient(data: Data(ITunesFixtures.searchResponse.utf8)))

        let page = try await client.searchSongs(term: " jack johnson ", limit: 25, offset: 0)

        #expect(page.query == "jack johnson")
        #expect(page.limit == 25)
        #expect(page.offset == 0)
        #expect(page.resultCount == 2)
        #expect(page.songs.count == 2)
        #expect(page.songs[0].id == 120954025)
        #expect(page.songs[0].title == "Upside Down")
        #expect(page.songs[0].artistName == "Jack Johnson")
        #expect(page.songs[0].albumId == 120954021)
        #expect(page.songs[0].artworkURL?.absoluteString.contains("600x600bb") == true)
        #expect(page.songs[0].durationSeconds == 208.643)
    }

    @Test func lookupAlbumMapsCollectionAndSongs() async throws {
        let client = ITunesSearchClient(httpClient: StubHTTPClient(data: Data(ITunesFixtures.albumLookupResponse.utf8)))

        let album = try await client.lookupAlbum(collectionId: 120954021)

        #expect(album.id == 120954021)
        #expect(album.title == "Sing-A-Longs and Lullabies")
        #expect(album.artistName == "Jack Johnson")
        #expect(album.songs.map(\.title) == ["Upside Down", "Broken"])
    }

    @Test func nonSuccessStatusThrowsHTTPStatusError() async throws {
        let client = ITunesSearchClient(httpClient: StubHTTPClient(
            data: Data("{}".utf8),
            statusCode: 503
        ))

        await #expect(throws: AppError.httpStatus(503)) {
            _ = try await client.searchSongs(term: "jack johnson", limit: 25, offset: 0)
        }
    }

    @Test func malformedPayloadThrowsDecodingError() async throws {
        let client = ITunesSearchClient(httpClient: StubHTTPClient(data: Data("{".utf8)))

        await #expect(throws: AppError.decodingFailed) {
            _ = try await client.searchSongs(term: "jack johnson", limit: 25, offset: 0)
        }
    }
}

private struct StubHTTPClient: HTTPClient {
    let data: Data
    let statusCode: Int

    init(data: Data, statusCode: Int = 200) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )

        return (data, response!)
    }
}
