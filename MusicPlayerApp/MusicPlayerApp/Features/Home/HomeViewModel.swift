import Combine
import Foundation

/// View model that drives the Home screen, managing song search, client-side pagination, and recently played history.
///
/// `HomeViewModel` fetches a large batch of results from the iTunes API in a single request
/// (because the API does not support server-side pagination) and pages through them locally.
/// When no search query is active, the view model surfaces the user's recently played songs instead.
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Constants

    /// Maximum number of results to fetch from the iTunes API per search request.
    /// The iTunes Search API does not support server-side pagination, so a large batch
    /// is fetched up front and paged through locally via ``pageSize``.
    private static let searchFetchLimit = 200

    // MARK: - Published Properties

    /// The current search query entered by the user, bound to the search field.
    @Published var searchText: String

    /// The loadable state of the song list displayed on screen (idle, loading, loaded, empty, or failed).
    @Published private(set) var state: LoadableState<[Song]> = .idle

    /// Indicates whether the next page of local results is currently being appended.
    @Published private(set) var isLoadingNextPage = false

    /// Indicates whether a pull-to-refresh operation is currently running.
    @Published private(set) var isRefreshing = false

    /// The song the user has tapped on, presented in the preview sheet. `nil` when no song is selected.
    @Published private(set) var selectedSong: Song?

    /// The most recently played songs, shown when no search query is active.
    @Published private(set) var recentlyPlayed: [Song] = []

    // MARK: - Private Properties

    /// The repository used for searching songs and persisting playback history.
    private let repository: any SongRepository

    /// The number of songs to show per page when paginating locally through ``allSearchResults``.
    private let pageSize: Int

    /// The full set of results returned by the last search request, used as the source for local pagination.
    private var allSearchResults: [Song] = []

    /// The subset of ``allSearchResults`` currently exposed to the view through ``visibleSongs``.
    private var currentSongs: [Song] = []

    // MARK: - Computed Properties

    /// The songs currently visible to the view, representing the current page of results.
    var visibleSongs: [Song] {
        currentSongs
    }

    // MARK: - Initialization

    /// Creates a new view model with the given dependencies.
    ///
    /// - Parameters:
    ///   - repository: The song repository used for search and playback history.
    ///   - initialSearchText: The default search term populated in the search field.
    ///   - pageSize: The number of songs displayed per page of local pagination.
    init(
        repository: any SongRepository,
        initialSearchText: String = DataLayer.defaultSearchTerm,
        pageSize: Int = DataLayer.defaultPageSize
    ) {
        self.repository = repository
        self.searchText = initialSearchText
        self.pageSize = pageSize
    }

    // MARK: - Public Methods

    /// Loads the initial Home state if the screen has not been initialized yet.
    ///
    /// Call this when the view first appears to preload recently played metadata
    /// without placing those songs into the main search results list.
    func loadInitialIfNeeded() async {
        guard case .idle = state else { return }
        loadRecentlyPlayedAsInitialResults()
    }

    /// Executes a search against the repository using the current ``searchText``.
    ///
    /// Fetches up to ``searchFetchLimit`` results in a single request and displays the first
    /// ``pageSize`` songs. Subsequent pages are loaded on demand via ``loadMoreIfNeeded(currentSong:)``.
    /// If the search text is empty, the state is set to `.empty`.
    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            allSearchResults = []
            currentSongs = []
            state = .empty
            return
        }

        state = .loading

        do {
            let searchLimit = max(pageSize, Self.searchFetchLimit)
            let page = try await repository.searchSongs(term: query, limit: searchLimit, offset: 0)

            allSearchResults = page.songs
            currentSongs = Array(page.songs.prefix(pageSize))
            state = currentSongs.isEmpty ? .empty : .loaded(currentSongs)
        } catch let appError as AppError {
            state = .failed(appError)
        } catch {
            state = .failed(.unknown(error.localizedDescription))
        }
    }

    /// Refreshes the current content.
    ///
    /// If no search query is active, reloads recently played songs.
    /// Otherwise, refreshes the recently played list and re-executes the current search.
    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loadRecentlyPlayedAsInitialResults()
        } else {
            loadRecentlyPlayed()
            await search()
        }
    }

    /// Loads the next page of results when the user scrolls to the given song.
    ///
    /// This implements infinite-scroll behavior by checking whether `currentSong` is the last
    /// visible item. If more results are available in ``allSearchResults``, the next ``pageSize``
    /// songs are appended to the visible list.
    ///
    /// - Parameter currentSong: The song the user is currently viewing, typically the last visible cell.
    func loadMoreIfNeeded(currentSong: Song) async {
        guard currentSong.id == currentSongs.last?.id else { return }
        guard currentSongs.count < allSearchResults.count, !isLoadingNextPage else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let nextEndIndex = min(currentSongs.count + pageSize, allSearchResults.count)
        currentSongs = Array(allSearchResults.prefix(nextEndIndex))
        state = currentSongs.isEmpty ? .empty : .loaded(currentSongs)
    }

    /// Selects a song for preview, recording it as recently played.
    ///
    /// - Parameter song: The song the user tapped on.
    func select(_ song: Song) {
        recordPlayback(for: song)
        selectedSong = song
    }

    /// Persists the given song to the recently played history and refreshes the recently played list.
    ///
    /// - Parameter song: The song that was played.
    func recordPlayback(for song: Song) {
        try? repository.addRecentlyPlayed(song)

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loadRecentlyPlayedAsInitialResults()
        } else {
            loadRecentlyPlayed()
        }
    }

    /// Clears the current song selection, dismissing the preview sheet.
    func dismissSelection() {
        selectedSong = nil
    }

    // MARK: - Private Methods

    /// Fetches the 10 most recently played songs from the repository and updates ``recentlyPlayed``.
    private func loadRecentlyPlayed() {
        do {
            recentlyPlayed = try repository.recentlyPlayed(limit: 10)
        } catch {
            recentlyPlayed = []
        }
    }

    /// Resets search results and populates the visible song list with the recently played history.
    private func loadRecentlyPlayedAsInitialResults() {
        allSearchResults = []
        do {
            recentlyPlayed = try repository.recentlyPlayed(limit: 10)
            currentSongs = recentlyPlayed
            state = recentlyPlayed.isEmpty ? .empty : .loaded(recentlyPlayed)
        } catch let appError as AppError {
            recentlyPlayed = []
            currentSongs = []
            state = .failed(appError)
        } catch {
            recentlyPlayed = []
            currentSongs = []
            state = .failed(.unknown(error.localizedDescription))
        }
    }
}
