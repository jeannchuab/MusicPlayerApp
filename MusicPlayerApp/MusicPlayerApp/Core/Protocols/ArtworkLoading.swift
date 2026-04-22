import UIKit

/// Defines the artwork loading interface used by feature views.
@MainActor
protocol ArtworkLoading: AnyObject {

    // MARK: - ArtworkLoading

    /// Returns an artwork image for the provided remote URL, using cache storage when available.
    ///
    /// - Parameter remoteURL: The remote artwork URL used as the cache key.
    /// - Returns: A cached or freshly downloaded image, or `nil` when the image is unavailable.
    func loadImage(from remoteURL: URL) async -> UIImage?
}
