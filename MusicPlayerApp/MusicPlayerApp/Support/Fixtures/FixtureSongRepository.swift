import Foundation

/// A deterministic repository used by previews and UI tests to avoid live network dependencies.
@MainActor
final class FixtureSongRepository: SongRepository {

    // MARK: - Supporting Types

    /// Selects the deterministic data behavior used by the fixture repository.
    typealias Mode = AppLaunchConfiguration.FixtureMode

    // MARK: - Properties

    /// The complete set of songs exposed by the fixture repository.
    private let songs: [Song]

    /// The deterministic mode used to shape repository responses.
    private let mode: Mode

    /// The in-memory recently played history exposed by the fixture repository.
    private var recentSongs: [Song]

    /// The standard fixture catalog used for previews and tests.
    private static let standardSongs: [Song] = [
        Song.fixture(id: 1, title: "Midnight Signal", artistName: "Music AI", albumId: 101, albumTitle: "Neural Notes"),
        Song.fixture(id: 2, title: "Golden Static", artistName: "Lina Wave", albumId: 101, albumTitle: "Neural Notes"),
        Song.fixture(id: 3, title: "Circuit Heart", artistName: "Nova Echo", albumId: 202, albumTitle: "Synthetic Bloom"),
        Song.fixture(id: 4, title: "Soft Voltage", artistName: "The Prompts", albumId: 202, albumTitle: "Synthetic Bloom")
    ]

    // MARK: - Initialization

    /// Creates the fixture repository with an initial recently played list.
    ///
    /// - Parameter mode: The deterministic dataset behavior used by the repository.
    init(mode: Mode = .standard) {
        self.mode = mode
        songs = Self.standardSongs
        recentSongs = mode == .empty ? [] : Self.standardSongs
    }

    // MARK: - SongRepository

    /// Returns fixture songs filtered by the provided search term.
    func searchSongs(term: String, limit: Int, offset: Int) async throws -> SearchPage {
        try throwIfNeeded()
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceSongs = mode == .empty ? [] : songs
        let matchingSongs = sourceSongs.filter {
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
        try throwIfNeeded()
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
        try throwIfNeeded()
        return Array(recentSongs.prefix(limit))
    }

    /// Moves a song to the front of the in-memory recently played list.
    func addRecentlyPlayed(_ song: Song) throws {
        try throwIfNeeded()
        recentSongs.removeAll { $0.id == song.id }
        recentSongs.insert(song, at: 0)
    }

    // MARK: - Helpers

    /// Throws the deterministic fixture error when the repository is in error mode.
    private func throwIfNeeded() throws {
        guard mode == .error else { return }
        throw AppError.transport("Fixture repository forced failure")
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
            previewURL: URL(string: "https://example.com/previews/\(id).m4a"),
            trackViewURL: URL(string: "https://example.com/tracks/\(id)"),
            durationMilliseconds: 30_000,
            genreName: "Electronic",
            releaseDate: nil,
            trackNumber: id,
            trackCount: 4
        )
    }
}
