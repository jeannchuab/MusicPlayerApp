import Foundation
import Testing
@testable import MusicPlayerApp

/// Tests for the app-managed artwork loader memory and disk cache behavior.
@MainActor
struct CachedArtworkLoaderTests {

    // MARK: - Tests

    @Test func loadImageDownloadsAndPersistsArtwork() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/artwork.png"))
        let httpClient = StubArtworkHTTPClient(
            result: .success((Self.validImageData, makeResponse(url: remoteURL))),
            requestCount: 0
        )
        let loader = CachedArtworkLoader(httpClient: httpClient, cacheDirectory: tempDirectory)

        let image = await loader.loadImage(from: remoteURL)

        #expect(image != nil)
        #expect(httpClient.requestCount == 1)
        #expect(FileManager.default.fileExists(atPath: loader.diskURL(for: remoteURL).path))
    }

    @Test func loadImageReusesDiskCacheWithoutNetwork() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/artwork.png"))

        let warmClient = StubArtworkHTTPClient(
            result: .success((Self.validImageData, makeResponse(url: remoteURL))),
            requestCount: 0
        )
        let warmLoader = CachedArtworkLoader(httpClient: warmClient, cacheDirectory: tempDirectory)
        let warmedImage = await warmLoader.loadImage(from: remoteURL)

        #expect(warmedImage != nil)
        #expect(warmClient.requestCount == 1)

        let coldClient = StubArtworkHTTPClient(
            result: .failure(AppError.transport("Network should not be used")),
            requestCount: 0
        )
        let coldLoader = CachedArtworkLoader(httpClient: coldClient, cacheDirectory: tempDirectory)

        let cachedImage = await coldLoader.loadImage(from: remoteURL)

        #expect(cachedImage != nil)
        #expect(coldClient.requestCount == 0)
    }

    @Test func loadImageReturnsNilForInvalidImageData() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/invalid.png"))
        let httpClient = StubArtworkHTTPClient(
            result: .success((Data("not-an-image".utf8), makeResponse(url: remoteURL))),
            requestCount: 0
        )
        let loader = CachedArtworkLoader(httpClient: httpClient, cacheDirectory: tempDirectory)

        let image = await loader.loadImage(from: remoteURL)

        #expect(image == nil)
        #expect(httpClient.requestCount == 1)
        #expect(FileManager.default.fileExists(atPath: loader.diskURL(for: remoteURL).path) == false)
    }

    // MARK: - Helpers

    /// Creates a fresh temporary directory for a test case.
    ///
    /// - Returns: The temporary directory URL used by the test.
    private func makeTemporaryDirectory() -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Builds a successful HTTP response for the provided URL.
    ///
    /// - Parameter url: The response URL.
    /// - Returns: A `200 OK` HTTP response.
    private func makeResponse(url: URL) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Constants

    /// A valid 1x1 PNG image used for deterministic artwork cache tests.
    private static let validImageData = Data(
        base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X6l8AAAAASUVORK5CYII="
    )!
}

// MARK: - Test Doubles

/// A deterministic HTTP client used by the artwork loader tests.
@MainActor
private final class StubArtworkHTTPClient: HTTPClient {

    // MARK: - Properties

    /// The canned result returned for every HTTP request.
    private let result: Result<(Data, HTTPURLResponse), Error>

    /// The number of requests performed through the stub.
    private(set) var requestCount: Int

    // MARK: - Initialization

    /// Creates a deterministic HTTP client test double.
    ///
    /// - Parameters:
    ///   - result: The canned result returned for every HTTP request.
    ///   - requestCount: The initial request count used by the test.
    init(
        result: Result<(Data, HTTPURLResponse), Error>,
        requestCount: Int
    ) {
        self.result = result
        self.requestCount = requestCount
    }

    // MARK: - HTTPClient

    /// Returns the configured result and records the request count.
    ///
    /// - Parameter url: The requested remote URL.
    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestCount += 1
        return try result.get()
    }
}
