import Foundation
@testable import MusicPlayerApp

/// A configurable preview cache manager test double for unit tests.
@MainActor
final class StubPreviewCacheManager: PreviewCacheManaging {

    // MARK: - Properties

    /// The remote preview URLs currently considered cached by the stub.
    private(set) var cachedRemoteURLs: Set<URL>

    /// The canned error thrown when caching a preview fails.
    var cacheError: Error?

    /// The canned error thrown when removing a cached preview fails.
    var removeError: Error?

    /// The local file URLs returned for cached preview lookups.
    var localFileURLs: [URL: URL]

    /// The remote preview URLs passed to ``cachePreview(from:)``.
    private(set) var cacheRequests: [URL?] = []

    /// The remote preview URLs passed to ``removeCachedPreview(for:)``.
    private(set) var removeRequests: [URL?] = []

    // MARK: - Initialization

    /// Creates a stub preview cache manager with the provided cached URLs.
    ///
    /// - Parameters:
    ///   - cachedRemoteURLs: The remote preview URLs initially marked as cached.
    ///   - localFileURLs: The local file URLs returned for cached preview lookups.
    init(
        cachedRemoteURLs: Set<URL> = [],
        localFileURLs: [URL: URL] = [:]
    ) {
        self.cachedRemoteURLs = cachedRemoteURLs
        self.localFileURLs = localFileURLs
    }

    // MARK: - PreviewCacheManaging

    /// Indicates whether a cached preview file already exists for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: `true` when a cached preview file exists for the URL.
    func isPreviewCached(for remoteURL: URL?) -> Bool {
        guard let remoteURL else { return false }
        return cachedRemoteURLs.contains(remoteURL)
    }

    /// Returns the local cached preview file URL for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: The local file URL when a cached preview exists, otherwise `nil`.
    func cachedFileURL(for remoteURL: URL?) -> URL? {
        guard let remoteURL, cachedRemoteURLs.contains(remoteURL) else { return nil }
        return localFileURLs[remoteURL] ?? URL(fileURLWithPath: "/tmp/\(remoteURL.lastPathComponent)")
    }

    /// Records the cache request and marks the provided preview URL as cached when successful.
    ///
    /// - Parameter remoteURL: The remote preview URL that should be cached.
    func cachePreview(from remoteURL: URL?) async throws {
        cacheRequests.append(remoteURL)

        if let cacheError {
            throw cacheError
        }

        guard let remoteURL else {
            throw AppError.invalidURL
        }

        cachedRemoteURLs.insert(remoteURL)
    }

    /// Records the removal request and removes the provided preview URL from the cached set when successful.
    ///
    /// - Parameter remoteURL: The remote preview URL whose cached file should be removed.
    func removeCachedPreview(for remoteURL: URL?) throws {
        removeRequests.append(remoteURL)

        if let removeError {
            throw removeError
        }

        guard let remoteURL else {
            throw AppError.invalidURL
        }

        cachedRemoteURLs.remove(remoteURL)
    }
}
