import CryptoKit
import Foundation

/// A deterministic preview cache manager used by UI tests without relying on network access.
@MainActor
final class FixturePreviewCacheManager: PreviewCacheManaging {

    // MARK: - Properties

    /// The file manager used for disk reads, writes, and deletions.
    private let fileManager: FileManager

    /// The directory used to persist cached fixture preview files.
    private let cacheDirectory: URL

    // MARK: - Initialization

    /// Creates a fixture preview cache manager.
    ///
    /// - Parameters:
    ///   - fileManager: The file manager used for disk reads, writes, and deletions.
    ///   - cacheDirectory: The directory used to persist cached fixture preview files.
    init(
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil
    ) {
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

    /// Persists a deterministic fixture preview file for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL that should be cached.
    func cachePreview(from remoteURL: URL?) async throws {
        guard let remoteURL else {
            throw AppError.invalidURL
        }

        let fileURL = diskURL(for: remoteURL)
        try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try Data("fixture-preview".utf8).write(to: fileURL, options: .atomic)
    }

    /// Removes the cached fixture preview file associated with the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL whose cached file should be removed.
    func removeCachedPreview(for remoteURL: URL?) throws {
        guard let remoteURL else {
            throw AppError.invalidURL
        }

        let fileURL = diskURL(for: remoteURL)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    // MARK: - Helpers

    /// Returns the disk location used for the provided preview URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: The disk file URL for the cached fixture preview bytes.
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
