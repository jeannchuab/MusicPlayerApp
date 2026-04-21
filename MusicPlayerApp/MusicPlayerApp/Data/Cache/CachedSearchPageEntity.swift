import Foundation
import SwiftData

/// A persisted SwiftData representation of a cached search page.
@Model
final class CachedSearchPageEntity {

    // MARK: - Properties

    /// The stable key derived from the query and paging values.
    @Attribute(.unique) var pageKey: String

    /// The original normalized search query.
    var query: String

    /// The start offset of the cached page.
    var offset: Int

    /// The number of songs requested for the cached page.
    var limit: Int

    /// The total result count reported by the search endpoint.
    var resultCount: Int

    /// The comma-separated list of cached song identifiers belonging to the page.
    var songIDsString: String

    /// The timestamp associated with the cached search page payload.
    var cachedAt: Date

    // MARK: - Initialization

    /// Creates a cached search page entity from a domain ``SearchPage``.
    ///
    /// - Parameters:
    ///   - page: The search page to persist in the cache.
    ///   - pageKey: The stable cache key derived from the query and paging values.
    ///   - cachedAt: The timestamp associated with the cached payload.
    init(page: SearchPage, pageKey: String, cachedAt: Date = .now) {
        self.pageKey = pageKey
        query = page.query
        offset = page.offset
        limit = page.limit
        resultCount = page.resultCount
        songIDsString = page.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    // MARK: - Helpers

    /// Refreshes the cached values using the latest ``SearchPage`` payload.
    ///
    /// - Parameters:
    ///   - page: The latest search page to persist.
    ///   - cachedAt: The timestamp associated with the updated cache entry.
    func update(with page: SearchPage, cachedAt: Date = .now) {
        query = page.query
        offset = page.offset
        limit = page.limit
        resultCount = page.resultCount
        songIDsString = page.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    /// The cached song identifiers decoded from the stored comma-separated value.
    var songIDs: [Int] {
        songIDsString
            .split(separator: ",")
            .compactMap { Int($0) }
    }
}
