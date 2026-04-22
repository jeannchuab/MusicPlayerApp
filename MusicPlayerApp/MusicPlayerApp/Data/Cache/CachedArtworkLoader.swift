import CryptoKit
import Foundation
import UIKit

/// Loads artwork images with app-managed memory and disk caching for offline availability.
@MainActor
final class CachedArtworkLoader: ArtworkLoading {

    // MARK: - Properties

    /// The HTTP transport used to download uncached artwork.
    private let httpClient: HTTPClient

    /// The file manager used for disk cache reads and writes.
    private let fileManager: FileManager

    /// The directory used to persist cached artwork files.
    private let cacheDirectory: URL

    /// The in-memory cache used for fast artwork reuse.
    private let memoryCache = NSCache<NSURL, UIImage>()

    // MARK: - Initialization

    /// Creates an artwork loader backed by memory and disk caching.
    ///
    /// - Parameters:
    ///   - httpClient: The HTTP transport used to download uncached artwork.
    ///   - fileManager: The file manager used for disk cache reads and writes.
    ///   - cacheDirectory: The directory used to persist cached artwork files.
    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil
    ) {
        self.httpClient = httpClient
        self.fileManager = fileManager
        self.cacheDirectory = cacheDirectory ?? Self.defaultCacheDirectory(using: fileManager)
    }

    // MARK: - ArtworkLoading

    /// Returns an artwork image from memory, disk, or the network.
    ///
    /// - Parameter remoteURL: The remote artwork URL used as the cache key.
    /// - Returns: A cached or freshly downloaded image, or `nil` when the image is unavailable.
    func loadImage(from remoteURL: URL) async -> UIImage? {
        let cacheKey = remoteURL as NSURL

        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        let fileURL = diskURL(for: remoteURL)
        if let diskImage = loadImageFromDisk(at: fileURL) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        guard let downloadedImage = await downloadImage(from: remoteURL, fileURL: fileURL) else {
            return nil
        }

        memoryCache.setObject(downloadedImage, forKey: cacheKey)
        return downloadedImage
    }

    // MARK: - Helpers

    /// Returns the disk location used for the provided artwork URL.
    ///
    /// - Parameter remoteURL: The remote artwork URL used as the cache key.
    /// - Returns: The disk file URL for the cached artwork bytes.
    func diskURL(for remoteURL: URL) -> URL {
        let key = Self.cacheKey(for: remoteURL)
        let pathExtension = remoteURL.pathExtension.isEmpty ? "img" : remoteURL.pathExtension
        return cacheDirectory.appendingPathComponent(key).appendingPathExtension(pathExtension)
    }

    /// Loads and decodes an image from disk, removing invalid cached files when needed.
    ///
    /// - Parameter fileURL: The cached artwork file location.
    /// - Returns: The decoded image, or `nil` when no valid file exists.
    private func loadImageFromDisk(at fileURL: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        guard let image = UIImage(data: data) else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        return image
    }

    /// Downloads an image and persists the raw bytes to disk for later offline use.
    ///
    /// - Parameters:
    ///   - remoteURL: The remote artwork URL to fetch.
    ///   - fileURL: The destination file used to persist the downloaded bytes.
    /// - Returns: The decoded image, or `nil` when the download fails or returns invalid data.
    private func downloadImage(from remoteURL: URL, fileURL: URL) async -> UIImage? {
        guard let (data, response) = try? await httpClient.data(from: remoteURL),
              200..<300 ~= response.statusCode,
              let image = UIImage(data: data)
        else {
            return nil
        }

        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Keep the successfully decoded in-memory image even when disk persistence fails.
        }

        return image
    }

    /// Returns the default artwork cache directory under the user caches folder.
    ///
    /// - Parameter fileManager: The file manager used to resolve the caches folder.
    /// - Returns: The default directory used to persist artwork files.
    private static func defaultCacheDirectory(using fileManager: FileManager) -> URL {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (cachesDirectory ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("ArtworkCache", isDirectory: true)
    }

    /// Returns the stable disk cache key for a remote artwork URL.
    ///
    /// - Parameter remoteURL: The remote artwork URL used as the cache key.
    /// - Returns: A SHA-256 hash string derived from the URL.
    private static func cacheKey(for remoteURL: URL) -> String {
        let digest = SHA256.hash(data: Data(remoteURL.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
