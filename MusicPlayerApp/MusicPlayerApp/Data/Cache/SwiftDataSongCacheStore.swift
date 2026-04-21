import Foundation
import SwiftData

/// A ``SongCacheStore`` implementation backed by SwiftData models.
@MainActor
final class SwiftDataSongCacheStore: SongCacheStore {

    // MARK: - Properties

    /// The SwiftData context used for all cache reads and writes.
    private let context: ModelContext

    // MARK: - Initialization

    /// Creates a SwiftData-backed cache store.
    ///
    /// - Parameter context: The model context used for all cache reads and writes.
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - SongCacheStore

    /// Returns the cached search page for the provided query and paging values, if present.
    ///
    /// - Parameters:
    ///   - query: The original search term.
    ///   - limit: The number of songs requested for the page.
    ///   - offset: The start offset of the requested page.
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

    /// Persists a search page and all of its songs in SwiftData.
    ///
    /// - Parameter page: The search page to persist.
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

    /// Returns the cached album for the provided collection identifier, if present.
    ///
    /// - Parameter collectionId: The iTunes collection identifier for the album.
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

    /// Persists an album and all of its songs in SwiftData.
    ///
    /// - Parameter album: The album to persist.
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

    /// Returns the most recently played songs up to the requested limit.
    ///
    /// - Parameter limit: The maximum number of songs to return.
    func recentlyPlayed(limit: Int) throws -> [Song] {
        var descriptor = FetchDescriptor<CachedSongEntity>(
            predicate: #Predicate { $0.recentlyPlayedAt != nil },
            sortBy: [SortDescriptor(\.recentlyPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor).map(\.song)
    }

    /// Adds a song to the recently played history, updating the cached song if needed.
    ///
    /// - Parameter song: The song that should be marked as recently played.
    func addRecentlyPlayed(_ song: Song) throws {
        upsertSong(song)

        let songID = song.id
        let descriptor = FetchDescriptor<CachedSongEntity>(
            predicate: #Predicate { $0.id == songID }
        )
        try context.fetch(descriptor).first?.recentlyPlayedAt = .now
        try context.save()
    }

    // MARK: - Helpers

    /// Inserts a new cached song or updates the existing one for the same identifier.
    ///
    /// - Parameter song: The song to insert or update.
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

    /// Loads every cached song and indexes them by identifier.
    private func cachedSongsByID() throws -> [Int: CachedSongEntity] {
        let songs = try context.fetch(FetchDescriptor<CachedSongEntity>())
        return Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
    }

    /// Builds the stable cache key used for search pages.
    ///
    /// - Parameters:
    ///   - query: The original search term.
    ///   - limit: The number of songs requested for the page.
    ///   - offset: The start offset of the requested page.
    private static func pageKey(query: String, limit: Int, offset: Int) -> String {
        "\(query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(limit)|\(offset)"
    }
}
