import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchText: String
    @Published private(set) var state: LoadableState<[Song]> = .idle
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var selectedSong: Song?
    @Published private(set) var recentlyPlayed: [Song] = []

    private let repository: any SongRepository
    private let pageSize: Int
    private var currentPage: SearchPage?
    private var currentSongs: [Song] = []

    var visibleSongs: [Song] {
        currentSongs
    }

    init(
        repository: any SongRepository,
        initialSearchText: String = DataLayer.defaultSearchTerm,
        pageSize: Int = DataLayer.defaultPageSize
    ) {
        self.repository = repository
        self.searchText = initialSearchText
        self.pageSize = pageSize
    }

    func loadInitialIfNeeded() async {
        guard case .idle = state else { return }
        loadRecentlyPlayedAsInitialResults()
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            currentPage = nil
            currentSongs = []
            state = .empty
            return
        }

        state = .loading

        do {
            let page = try await repository.searchSongs(term: query, limit: pageSize, offset: 0)
            currentPage = page
            currentSongs = page.songs
            state = page.songs.isEmpty ? .empty : .loaded(page.songs)
        } catch let appError as AppError {
            state = .failed(appError)
        } catch {
            state = .failed(.unknown(error.localizedDescription))
        }
    }

    func refresh() async {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loadRecentlyPlayedAsInitialResults()
        } else {
            loadRecentlyPlayed()
            await search()
        }
    }

    func loadMoreIfNeeded(currentSong: Song) async {
        guard currentSong.id == currentSongs.last?.id else { return }
        guard let currentPage, currentPage.canRequestNextPage, !isLoadingNextPage else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let nextPage = try await repository.searchSongs(
                term: currentPage.query,
                limit: pageSize,
                offset: currentPage.nextOffset
            )

            self.currentPage = nextPage
            currentSongs.append(contentsOf: nextPage.songs)
            state = currentSongs.isEmpty ? .empty : .loaded(currentSongs)
        } catch {
            // Keep the already loaded songs visible; the next pull-to-refresh can retry.
        }
    }

    func select(_ song: Song) {
        recordPlayback(for: song)
        selectedSong = song
    }

    func recordPlayback(for song: Song) {
        try? repository.addRecentlyPlayed(song)

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loadRecentlyPlayedAsInitialResults()
        } else {
            loadRecentlyPlayed()
        }
    }

    func dismissSelection() {
        selectedSong = nil
    }

    private func loadRecentlyPlayed() {
        recentlyPlayed = (try? repository.recentlyPlayed(limit: 10)) ?? []
    }

    private func loadRecentlyPlayedAsInitialResults() {
        currentPage = nil
        loadRecentlyPlayed()
        currentSongs = recentlyPlayed
        state = recentlyPlayed.isEmpty ? .empty : .loaded(recentlyPlayed)
    }
}
