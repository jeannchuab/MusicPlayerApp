import Foundation

@MainActor
protocol SongRepository: AnyObject {
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage
    func lookupAlbum(collectionId: Int) async throws -> Album
    func recentlyPlayed(limit: Int) throws -> [Song]
    func addRecentlyPlayed(_ song: Song) throws
}
