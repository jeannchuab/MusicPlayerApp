import Foundation

/// A single page of search results returned by the song repository.
///
/// `SearchPage` captures both the results and the pagination metadata needed to determine
/// whether additional pages are available.
struct SearchPage: Equatable, Sendable {
    
    /// The search term that produced these results.
    let query: String

    /// The zero-based offset into the full result set where this page begins.
    let offset: Int

    /// The maximum number of results that were requested for this page.
    let limit: Int

    /// The total number of results returned by the API for this page.
    let resultCount: Int

    /// The songs contained in this page.
    let songs: [Song]

    /// The offset to use when requesting the next page of results.
    var nextOffset: Int {
        offset + songs.count
    }

    /// Whether the API is likely to have more results beyond this page.
    ///
    /// Returns `true` when the number of songs equals the requested ``limit``,
    /// indicating the result set was not exhausted.
    var canRequestNextPage: Bool {
        songs.count == limit
    }
}
