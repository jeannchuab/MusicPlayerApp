import CryptoKit
import Foundation

/// Persists audio preview files on disk so previously downloaded songs can play offline.
@MainActor
final class CachedPreviewManager: PreviewCacheManaging {

    // MARK: - Properties

    /// The HTTP transport used to download uncached preview files.
    private let httpClient: HTTPClient

    /// The file manager used for disk reads, writes, and deletions.
    private let fileManager: FileManager

    /// The directory used to persist cached preview files.
    private let cacheDirectory: URL

    // MARK: - Initialization

    /// Creates a disk-backed preview cache manager.
    ///
    /// - Parameters:
    ///   - httpClient: The HTTP transport used to download uncached preview files.
    ///   - fileManager: The file manager used for disk reads, writes, and deletions.
    ///   - cacheDirectory: The directory used to persist cached preview files.
    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil
    ) {
        self.httpClient = httpClient
        self.fileManager = fileManager
        self.cacheDirectory = cacheDirectory ?? Self.defaultCacheDirectory(using: fileManager)
    }

    // MARK: - PreviewCacheManaging

    /// Indicates whether a cached preview file already exists for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: `true` when a cached preview file exists for the URL.
    func isPreviewCached(for remoteURL: URL?) -> Bool {
        cachedFileURL(for: remoteURL) != nil
    }

    /// Returns the local cached preview file URL for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: The local file URL when a cached preview exists, otherwise `nil`.
    func cachedFileURL(for remoteURL: URL?) -> URL? {
        guard let remoteURL else { return nil }

        let fileURL = diskURL(for: remoteURL)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        return fileURL
    }

    /// Downloads and persists the preview file for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL that should be cached.
    func cachePreview(from remoteURL: URL?) async throws {
        guard let remoteURL else {
            throw AppError.invalidURL
        }

        let targetURL = diskURL(for: remoteURL)
        if fileManager.fileExists(atPath: targetURL.path) {
            return
        }

        let (data, response) = try await httpClient.data(from: remoteURL)

        guard 200..<300 ~= response.statusCode else {
            throw AppError.httpStatus(response.statusCode)
        }

        guard data.isEmpty == false else {
            throw AppError.invalidResponse
        }

        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try data.write(to: targetURL, options: .atomic)
        } catch {
            try? fileManager.removeItem(at: targetURL)
            throw AppError.unknown(error.localizedDescription)
        }
    }

    /// Removes the cached preview file associated with the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL whose cached file should be removed.
    func removeCachedPreview(for remoteURL: URL?) throws {
        guard let remoteURL else {
            throw AppError.invalidURL
        }

        let targetURL = diskURL(for: remoteURL)
        guard fileManager.fileExists(atPath: targetURL.path) else { return }
        try fileManager.removeItem(at: targetURL)
    }

    // MARK: - Helpers

    /// Returns the disk location used for the provided preview URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: The disk file URL for the cached preview bytes.
    func diskURL(for remoteURL: URL) -> URL {
        let key = Self.cacheKey(for: remoteURL)
        let pathExtension = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        return cacheDirectory.appendingPathComponent(key).appendingPathExtension(pathExtension)
    }

    /// Returns the default preview cache directory under the user caches folder.
    ///
    /// - Parameter fileManager: The file manager used to resolve the caches folder.
    /// - Returns: The default directory used to persist preview files.
    private static func defaultCacheDirectory(using fileManager: FileManager) -> URL {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (cachesDirectory ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("PreviewCache", isDirectory: true)
    }

    /// Returns the stable disk cache key for a remote preview URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: A SHA-256 hash string derived from the URL.
    private static func cacheKey(for remoteURL: URL) -> String {
        let digest = SHA256.hash(data: Data(remoteURL.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
