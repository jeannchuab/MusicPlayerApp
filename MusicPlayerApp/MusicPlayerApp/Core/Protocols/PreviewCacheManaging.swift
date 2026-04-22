import Foundation

/// Defines the preview-file cache used to support offline song playback.
@MainActor
protocol PreviewCacheManaging: AnyObject {

    // MARK: - Methods

    /// Indicates whether a cached preview file already exists for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: `true` when a cached preview file exists for the URL.
    func isPreviewCached(for remoteURL: URL?) -> Bool

    /// Returns the local cached preview file URL for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL used as the cache key.
    /// - Returns: The local file URL when a cached preview exists, otherwise `nil`.
    func cachedFileURL(for remoteURL: URL?) -> URL?

    /// Downloads and persists the preview file for the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL that should be cached.
    func cachePreview(from remoteURL: URL?) async throws

    /// Removes the cached preview file associated with the provided remote URL.
    ///
    /// - Parameter remoteURL: The remote preview URL whose cached file should be removed.
    func removeCachedPreview(for remoteURL: URL?) throws
}
