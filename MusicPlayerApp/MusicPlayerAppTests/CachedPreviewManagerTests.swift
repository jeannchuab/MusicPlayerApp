import Foundation
import Testing
@testable import MusicPlayerApp

/// Tests for the app-managed preview cache used for offline playback.
@MainActor
struct CachedPreviewManagerTests {

    // MARK: - Tests

    @Test func cachePreviewDownloadsAndPersistsData() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let httpClient = StubPreviewHTTPClient(
            result: .success((Data("preview".utf8), makeResponse(url: remoteURL))),
            requestCount: 0
        )
        let manager = CachedPreviewManager(httpClient: httpClient, cacheDirectory: tempDirectory)

        try await manager.cachePreview(from: remoteURL)

        #expect(manager.isPreviewCached(for: remoteURL))
        #expect(httpClient.requestCount == 1)
        #expect(FileManager.default.fileExists(atPath: manager.diskURL(for: remoteURL).path))
    }

    @Test func cachedFileURLReusesDiskCacheWithoutNetwork() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))

        let warmClient = StubPreviewHTTPClient(
            result: .success((Data("preview".utf8), makeResponse(url: remoteURL))),
            requestCount: 0
        )
        let warmManager = CachedPreviewManager(httpClient: warmClient, cacheDirectory: tempDirectory)
        try await warmManager.cachePreview(from: remoteURL)

        let coldClient = StubPreviewHTTPClient(
            result: .failure(AppError.transport("Network should not be used")),
            requestCount: 0
        )
        let coldManager = CachedPreviewManager(httpClient: coldClient, cacheDirectory: tempDirectory)

        #expect(coldManager.cachedFileURL(for: remoteURL) != nil)
        #expect(coldClient.requestCount == 0)
    }

    @Test func removeCachedPreviewDeletesPersistedFile() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let httpClient = StubPreviewHTTPClient(
            result: .success((Data("preview".utf8), makeResponse(url: remoteURL))),
            requestCount: 0
        )
        let manager = CachedPreviewManager(httpClient: httpClient, cacheDirectory: tempDirectory)
        try await manager.cachePreview(from: remoteURL)

        try manager.removeCachedPreview(for: remoteURL)

        #expect(manager.isPreviewCached(for: remoteURL) == false)
        #expect(FileManager.default.fileExists(atPath: manager.diskURL(for: remoteURL).path) == false)
    }

    @Test func cachePreviewThrowsForInvalidURL() async {
        let manager = CachedPreviewManager(cacheDirectory: makeTemporaryDirectory())

        await #expect(throws: AppError.invalidURL) {
            try await manager.cachePreview(from: nil)
        }
    }

    @Test func cachePreviewDoesNotPersistDataForBadResponses() async throws {
        let tempDirectory = makeTemporaryDirectory()
        let remoteURL = try #require(URL(string: "https://example.com/preview.m4a"))
        let httpClient = StubPreviewHTTPClient(
            result: .success((Data("preview".utf8), makeErrorResponse(url: remoteURL))),
            requestCount: 0
        )
        let manager = CachedPreviewManager(httpClient: httpClient, cacheDirectory: tempDirectory)

        await #expect(throws: AppError.httpStatus(500)) {
            try await manager.cachePreview(from: remoteURL)
        }

        #expect(FileManager.default.fileExists(atPath: manager.diskURL(for: remoteURL).path) == false)
    }

    @Test func diskURLUsesStableKeysPerRemoteURL() async throws {
        let manager = CachedPreviewManager(cacheDirectory: makeTemporaryDirectory())
        let firstURL = try #require(URL(string: "https://example.com/preview-one.m4a"))
        let secondURL = try #require(URL(string: "https://example.com/preview-two.m4a"))

        #expect(manager.diskURL(for: firstURL) == manager.diskURL(for: firstURL))
        #expect(manager.diskURL(for: firstURL) != manager.diskURL(for: secondURL))
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

    /// Builds an error HTTP response for the provided URL.
    ///
    /// - Parameter url: The response URL.
    /// - Returns: A `500` HTTP response.
    private func makeErrorResponse(url: URL) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
    }
}

// MARK: - Test Doubles

/// A deterministic HTTP client used by the preview cache tests.
@MainActor
private final class StubPreviewHTTPClient: HTTPClient {

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
