import Foundation

/// A service that retrieves full album details (including track listings) by collection identifier.
///
/// Conforming types typically call the iTunes Lookup API to resolve an album from its ID.
protocol AlbumLookupService: Sendable {

    /// Fetches the album matching the given iTunes collection identifier.
    ///
    /// - Parameter collectionId: The iTunes collection ID of the album to look up.
    /// - Returns: The fully populated ``Album`` including its ``Album/songs``.
    /// - Throws: An ``AppError`` if the network request or decoding fails.
    func lookupAlbum(collectionId: Int) async throws -> Album
}
