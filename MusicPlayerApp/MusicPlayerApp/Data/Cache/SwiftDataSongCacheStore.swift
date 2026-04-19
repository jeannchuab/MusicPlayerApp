import Foundation
import SwiftData

@MainActor
final class SwiftDataSongCacheStore: SongCacheStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func cachedSearchPage(query: String, limit: Int, offset: Int) throws -> SearchPage? {
        let key = Self.pageKey(query: query, limit: limit, offset: offset)
        let descriptor = FetchDescriptor<CachedSearchPageEntity>(
            predicate: #Predicate { $0.pageKey == key }
        )

        guard let pageEntity = try context.fetch(descriptor).first else {
            return nil
        }

        let songsByID = try cachedSongsByID()
        let songs = pageEntity.songIDs.compactMap { songsByID[$0]?.song }

        guard !songs.isEmpty else {
            return nil
        }

        return SearchPage(
            query: pageEntity.query,
            offset: pageEntity.offset,
            limit: pageEntity.limit,
            resultCount: pageEntity.resultCount,
            songs: songs
        )
    }

    func saveSearchPage(_ page: SearchPage) throws {
        for song in page.songs {
            upsertSong(song)
        }

        let key = Self.pageKey(query: page.query, limit: page.limit, offset: page.offset)
        let descriptor = FetchDescriptor<CachedSearchPageEntity>(
            predicate: #Predicate { $0.pageKey == key }
        )

        if let existingPage = try context.fetch(descriptor).first {
            existingPage.update(with: page)
        } else {
            context.insert(CachedSearchPageEntity(page: page, pageKey: key))
        }

        try context.save()
    }

    func cachedAlbum(collectionId: Int) throws -> Album? {
        let descriptor = FetchDescriptor<CachedAlbumEntity>(
            predicate: #Predicate { $0.id == collectionId }
        )

        guard let albumEntity = try context.fetch(descriptor).first else {
            return nil
        }

        let songsByID = try cachedSongsByID()
        let songs = albumEntity.songIDs.compactMap { songsByID[$0]?.song }

        return Album(
            id: albumEntity.id,
            title: albumEntity.title,
            artistName: albumEntity.artistName,
            artworkURL: albumEntity.artworkURLString.flatMap(URL.init(string:)),
            songs: songs
        )
    }

    func saveAlbum(_ album: Album) throws {
        for song in album.songs {
            upsertSong(song)
        }

        let collectionId = album.id
        let descriptor = FetchDescriptor<CachedAlbumEntity>(
            predicate: #Predicate { $0.id == collectionId }
        )

        if let existingAlbum = try context.fetch(descriptor).first {
            existingAlbum.update(with: album)
        } else {
            context.insert(CachedAlbumEntity(album: album))
        }

        try context.save()
    }

    func recentlyPlayed(limit: Int) throws -> [Song] {
        var descriptor = FetchDescriptor<CachedSongEntity>(
            predicate: #Predicate { $0.recentlyPlayedAt != nil },
            sortBy: [SortDescriptor(\.recentlyPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor).map(\.song)
    }

    func addRecentlyPlayed(_ song: Song) throws {
        upsertSong(song)

        let songID = song.id
        let descriptor = FetchDescriptor<CachedSongEntity>(
            predicate: #Predicate { $0.id == songID }
        )
        try context.fetch(descriptor).first?.recentlyPlayedAt = .now
        try context.save()
    }

    private func upsertSong(_ song: Song) {
        let songID = song.id
        let descriptor = FetchDescriptor<CachedSongEntity>(
            predicate: #Predicate { $0.id == songID }
        )

        if let existingSong = try? context.fetch(descriptor).first {
            existingSong.update(with: song)
        } else {
            context.insert(CachedSongEntity(song: song))
        }
    }

    private func cachedSongsByID() throws -> [Int: CachedSongEntity] {
        let songs = try context.fetch(FetchDescriptor<CachedSongEntity>())
        return Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
    }

    private static func pageKey(query: String, limit: Int, offset: Int) -> String {
        "\(query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(limit)|\(offset)"
    }
}
