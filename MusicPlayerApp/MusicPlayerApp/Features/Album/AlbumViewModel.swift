import Combine
import Foundation

@MainActor
final class AlbumViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<Album> = .idle
    @Published private(set) var selectedSong: Song?

    private let collectionId: Int
    private let repository: any SongRepository

    init(collectionId: Int, repository: any SongRepository) {
        self.collectionId = collectionId
        self.repository = repository
    }

    func load() async {
        guard case .idle = state else { return }
        await refresh()
    }

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

    func select(_ song: Song) {
        try? repository.addRecentlyPlayed(song)
        selectedSong = song
    }

    func dismissSelection() {
        selectedSong = nil
    }
}
