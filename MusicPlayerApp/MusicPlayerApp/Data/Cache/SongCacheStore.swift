import Foundation

@MainActor
protocol SongCacheStore: AnyObject {
    func cachedSearchPage(query: String, limit: Int, offset: Int) throws -> SearchPage?
    func saveSearchPage(_ page: SearchPage) throws
    func cachedAlbum(collectionId: Int) throws -> Album?
    func saveAlbum(_ album: Album) throws
    func recentlyPlayed(limit: Int) throws -> [Song]
    func addRecentlyPlayed(_ song: Song) throws
}
