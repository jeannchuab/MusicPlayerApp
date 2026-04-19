import Foundation
import Testing
@testable import MusicPlayerApp

@MainActor
final class StubSongRepository: SongRepository {
    var searchResult: Result<SearchPage, Error>
    var albumResult: Result<Album, Error>
    private(set) var searchRequests: [(term: String, limit: Int, offset: Int)] = []
    private(set) var recentlyPlayedSongs: [Song] = []

    init(
        searchResult: Result<SearchPage, Error>,
        albumResult: Result<Album, Error> = .success(.stub()),
        recentlyPlayedSongs: [Song] = []
    ) {
        self.searchResult = searchResult
        self.albumResult = albumResult
        self.recentlyPlayedSongs = recentlyPlayedSongs
    }

    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage {
        searchRequests.append((term, limit, offset))
        return try searchResult.get()
    }

    func lookupAlbum(collectionId: Int) async throws -> Album {
        try albumResult.get()
    }

    func recentlyPlayed(limit: Int) throws -> [Song] {
        Array(recentlyPlayedSongs.prefix(limit))
    }

    func addRecentlyPlayed(_ song: Song) throws {
        recentlyPlayedSongs.removeAll { $0.id == song.id }
        recentlyPlayedSongs.insert(song, at: 0)
    }
}

extension Song {
    static func stub(
        id: Int = 1,
        title: String = "Demo Song",
        previewURL: URL? = URL(string: "https://example.com/preview.m4a")
    ) -> Song {
        Song(
            id: id,
            title: title,
            artistName: "Demo Artist",
            albumId: 10,
            albumTitle: "Demo Album",
            artworkURL: URL(string: "https://example.com/artwork.jpg"),
            previewURL: previewURL,
            durationMilliseconds: 180_000,
            genreName: "Pop",
            releaseDate: nil,
            trackNumber: 1,
            trackCount: 10
        )
    }
}

extension Album {
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
