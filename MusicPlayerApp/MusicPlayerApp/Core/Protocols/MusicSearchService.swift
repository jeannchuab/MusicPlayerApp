import Foundation

protocol MusicSearchService: Sendable {
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage
}
