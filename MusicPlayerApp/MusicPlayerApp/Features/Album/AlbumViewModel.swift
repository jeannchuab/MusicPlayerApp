import Combine
import Foundation

/// View model that drives album loading, selection, and recently played updates.
@MainActor
final class AlbumViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The loadable state of the album screen.
    @Published private(set) var state: LoadableState<Album> = .idle

    /// The song currently selected from the album track list.
    @Published private(set) var selectedSong: Song?

    // MARK: - Private Properties

    /// The iTunes collection identifier used to load the album.
    private let collectionId: Int

    /// The repository used to fetch album data and record playback history.
    private let repository: any SongRepository

    // MARK: - Initialization

    /// Creates a new album view model.
    ///
    /// - Parameters:
    ///   - collectionId: The iTunes collection identifier used to load the album.
    ///   - repository: The repository used to fetch album data and record playback history.
    init(collectionId: Int, repository: any SongRepository) {
        self.collectionId = collectionId
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Loads the album once when the screen first appears.
    func load() async {
        guard case .idle = state else { return }
        await refresh()
    }

    /// Refreshes the album state from the repository.
    func refresh() async {
        state = .loading

        do {
            let album = try await repository.lookupAlbum(collectionId: collectionId)
            state = album.songs.isEmpty ? .empty : .loaded(album)
        } catch let appError as AppError {
            state = .failed(appError)
        } catch {
            state = .failed(.unknown(error.localizedDescription))
        }
    }

    /// Selects a song from the album track list and records it as recently played.
    ///
    /// - Parameter song: The selected song.
    func select(_ song: Song) {
        try? repository.addRecentlyPlayed(song)
        selectedSong = song
    }

    /// Clears the current song selection.
    func dismissSelection() {
        selectedSong = nil
    }
}
