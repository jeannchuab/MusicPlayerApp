import Foundation

protocol AlbumLookupService: Sendable {
    func lookupAlbum(collectionId: Int) async throws -> Album
}
