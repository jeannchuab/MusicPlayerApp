import Foundation
import Testing
@testable import MusicPlayerApp

/// A configurable song repository test double for unit tests.
@MainActor
final class StubSongRepository: SongRepository {

    // MARK: - Properties

    /// The canned result returned for search requests.
    var searchResult: Result<SearchPage, Error>

    /// The canned result returned for album lookup requests.
    var albumResult: Result<Album, Error>

    /// The search requests captured by the stub for test assertions.
    private(set) var searchRequests: [(term: String, limit: Int, offset: Int)] = []

    /// The in-memory recently played songs returned by the stub.
    private(set) var recentlyPlayedSongs: [Song] = []

    /// The canned error thrown when recently played songs are requested.
    var recentlyPlayedError: Error?

    // MARK: - Initialization

    /// Creates a stub repository with canned search, album, and recently played results.
    ///
    /// - Parameters:
    ///   - searchResult: The result returned when ``searchSongs(term:limit:offset:)`` is called.
    ///   - albumResult: The result returned when ``lookupAlbum(collectionId:)`` is called.
    ///   - recentlyPlayedSongs: The initial recently played songs exposed by the stub.
    init(
        searchResult: Result<SearchPage, Error>,
        albumResult: Result<Album, Error> = .success(.stub()),
        recentlyPlayedSongs: [Song] = []
    ) {
        self.searchResult = searchResult
        self.albumResult = albumResult
        self.recentlyPlayedSongs = recentlyPlayedSongs
    }

    // MARK: - SongRepository

    /// Records the incoming search request and returns the configured result.
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage {
        searchRequests.append((term, limit, offset))
        return try searchResult.get()
    }

    /// Returns the configured album lookup result.
    func lookupAlbum(collectionId: Int) async throws -> Album {
        try albumResult.get()
    }

    /// Returns the configured recently played songs up to the requested limit.
    func recentlyPlayed(limit: Int) throws -> [Song] {
        if let recentlyPlayedError {
            throw recentlyPlayedError
        }

        return Array(recentlyPlayedSongs.prefix(limit))
    }

    /// Updates the in-memory recently played list in the same order expected from production code.
    func addRecentlyPlayed(_ song: Song) throws {
        recentlyPlayedSongs.removeAll { $0.id == song.id }
        recentlyPlayedSongs.insert(song, at: 0)
    }
}

// MARK: - Test Fixtures

extension Song {
    /// Creates a default song fixture for unit tests.
    static func stub(
        id: Int = 1,
        title: String = "Demo Song",
        previewURL: URL? = URL(string: "https://example.com/preview.m4a"),
        durationMilliseconds: Int? = 180_000
    ) -> Song {
        Song(
            id: id,
            title: title,
            artistName: "Demo Artist",
            albumId: 10,
            albumTitle: "Demo Album",
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            previewURL: previewURL,
            trackViewURL: URL(string: "https://example.com/tracks/\(id)"),
            durationMilliseconds: durationMilliseconds,
            genreName: "Pop",
            releaseDate: nil,
            trackNumber: 1,
            trackCount: 10
        )
    }
}

extension Album {
    /// Creates a default album fixture for unit tests.
    static func stub(id: Int = 10, songs: [Song] = [.stub()]) -> Album {
        Album(
            id: id,
            title: "Demo Album",
            artistName: "Demo Artist",
            artworkURL: URL(string: "https://example.com/album.jpg"),
            songs: songs
        )
    }
}
