import Foundation

/// A deterministic repository used by previews and UI tests to avoid live network dependencies.
@MainActor
final class FixtureSongRepository: SongRepository {
    private let songs: [Song] = [
        Song.fixture(id: 1, title: "Midnight Signal", artistName: "Music AI", albumId: 101, albumTitle: "Neural Notes"),
        Song.fixture(id: 2, title: "Golden Static", artistName: "Lina Wave", albumId: 101, albumTitle: "Neural Notes"),
        Song.fixture(id: 3, title: "Circuit Heart", artistName: "Nova Echo", albumId: 202, albumTitle: "Synthetic Bloom"),
        Song.fixture(id: 4, title: "Soft Voltage", artistName: "The Prompts", albumId: 202, albumTitle: "Synthetic Bloom")
    ]
    private var recentSongs: [Song]

    /// Creates the fixture repository with an initial recently played list.
    init() {
        recentSongs = songs
    }

    /// Returns fixture songs filtered by the provided search term.
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingSongs = songs.filter {
            trimmedTerm.isEmpty ||
            $0.title.localizedCaseInsensitiveContains(trimmedTerm) ||
            $0.artistName.localizedCaseInsensitiveContains(trimmedTerm) ||
            ($0.albumTitle?.localizedCaseInsensitiveContains(trimmedTerm) ?? false)
        }
        let pageSongs = Array(matchingSongs.dropFirst(offset).prefix(limit))

        return SearchPage(
            query: trimmedTerm,
            offset: offset,
            limit: limit,
            resultCount: matchingSongs.count,
            songs: pageSongs
        )
    }

    /// Returns a fixture album for the provided collection identifier.
    func lookupAlbum(collectionId: Int) async throws -> Album {
        let albumSongs = songs.filter { $0.albumId == collectionId }
        guard let firstSong = albumSongs.first else {
            return Album(
                id: collectionId,
                title: "Album",
                artistName: "Unknown Artist",
                artworkURL: nil,
                songs: []
            )
        }

        return Album(
            id: collectionId,
            title: firstSong.albumTitle ?? "Album",
            artistName: firstSong.artistName,
            artworkURL: firstSong.artworkURL,
            songs: albumSongs
        )
    }

    /// Returns the current in-memory recently played slice.
    func recentlyPlayed(limit: Int) throws -> [Song] {
        Array(recentSongs.prefix(limit))
    }

    /// Moves a song to the front of the in-memory recently played list.
    func addRecentlyPlayed(_ song: Song) throws {
        recentSongs.removeAll { $0.id == song.id }
        recentSongs.insert(song, at: 0)
    }
}

private extension Song {
    static func fixture(
        id: Int,
        title: String,
        artistName: String,
        albumId: Int,
        albumTitle: String
    ) -> Song {
        Song(
            id: id,
            title: title,
            artistName: artistName,
            albumId: albumId,
            albumTitle: albumTitle,
            artworkURL: nil,
            previewURL: nil,
            trackViewURL: URL(string: "https://example.com/tracks/\(id)"),
            durationMilliseconds: 30_000,
            genreName: "Electronic",
            releaseDate: nil,
            trackNumber: id,
            trackCount: 4
        )
    }
}
