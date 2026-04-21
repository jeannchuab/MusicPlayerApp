import SwiftUI

/// The main Home screen that displays a searchable list of songs and navigates to the player on selection.
///
/// `HomeView` presents a search field at the top and a vertically scrolling song list below it.
/// When no search query is active, recently played songs are shown as the initial content.
/// Tapping a song navigates to ``PlayerView`` via a `navigationDestination`.
/// Infinite-scroll pagination is handled automatically as the user scrolls to the bottom of the list.
struct HomeView: View {

    // MARK: - Properties

    /// The view model that owns the search, pagination, and selection state for this screen.
    @StateObject private var viewModel: HomeViewModel

    /// The song whose row menu is currently active.
    @State private var menuSong: Song?

    /// Controls the visibility of the row options sheet.
    @State private var showsRowOptions = false

    /// The track URL currently being shared from the row options sheet.
    @State private var shareURL: URL?

    /// Tracks whether the search text field is focused.
    @FocusState private var isSearchFocused: Bool

    /// Factory closure that creates a fresh ``AudioPlaybackService`` for each ``PlayerView`` instance.
    private let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService

    /// The song repository forwarded to child views that need direct repository access.
    private let repository: any SongRepository

    // MARK: - Initialization

    /// Creates a new `HomeView`.
    ///
    /// - Parameters:
    ///   - repository: The song repository used for search, caching, and playback history.
    ///   - makeAudioPlaybackService: A factory that produces a new ``AudioPlaybackService`` each time a player is presented.
    init(
        repository: any SongRepository,
        makeAudioPlaybackService: @escaping @MainActor () -> any AudioPlaybackService
    ) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
        self.makeAudioPlaybackService = makeAudioPlaybackService
        self.repository = repository
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    content
                }

                rowOptionsOverlay
            }
            .toolbar(.hidden, for: .navigationBar)
            .accessibilityIdentifier("home.screen")
            .task {
                await viewModel.loadInitialIfNeeded()
            }
            .navigationDestination(item: selectedSongBinding) { song in
                PlayerView(
                    song: song,
                    playlist: viewModel.visibleSongs,
                    songRepository: repository,
                    playbackService: makeAudioPlaybackService(),
                    makeAudioPlaybackService: makeAudioPlaybackService,
                    onSongPlayed: { song in
                        viewModel.recordPlayback(for: song)
                    }
                )
            }
            .sheet(isPresented: isShowingShareSheet) {
                if let shareURL {
                    SystemShareSheet(items: [shareURL])
                }
            }
        }
    }

    // MARK: - Subviews

    /// The top section containing the screen title and search text field.
    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Songs")
                .font(.app(24, weight: .semibold600, relativeTo: .headline))
                .foregroundStyle(AppTheme.primaryText)

            HStack(spacing: 10) {
                Image("SearchIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.white.opacity(0.35))
                    .accessibilityHidden(true)

                TextField("Search", text: $viewModel.searchText)
                    .focused($isSearchFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .font(.app(13))
                    .foregroundStyle(AppTheme.primaryText)
                    .tint(AppTheme.primaryText)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }
            }
            .padding(.horizontal, 13)
            .frame(height: 44)
            .background(Color(red: 0.09, green: 0.09, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("home.searchField")
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 7)
        .onAppear {
            isSearchFocused = true
        }
    }

    /// The main content area, which displays a loading indicator, song list, empty state, or error view
    /// depending on the current ``HomeViewModel/state``.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading songs")
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let songs):
            songList(songs)
        case .empty:
            ContentUnavailableView(
                "No songs found",
                systemImage: "music.note.list",
                description: Text("Try another artist, album, or track.")
            )
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) {
                Task { await viewModel.search() }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Builds a scrollable, pull-to-refresh list of songs with infinite-scroll pagination.
    ///
    /// - Parameter songs: The songs to display as rows in the list.
    /// - Returns: A `List` view containing tappable song rows and an optional loading indicator at the bottom.
    private func songList(_ songs: [Song]) -> some View {
        List {
            ForEach(songs) { song in
                SongRowView(
                    song: song,
                    onTap: {
                        viewModel.select(song)
                    },
                    onTapMenu: {
                        menuSong = song
                        showsRowOptions = true
                    }
                )
                .listRowBackground(AppTheme.background)
                .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
                .task {
                    await viewModel.loadMoreIfNeeded(currentSong: song)
                }
            }

            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.accent)
                    Spacer()
                }
                .listRowBackground(AppTheme.background)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("home.songList")
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Helpers

    private var rowOptionsOverlay: some View {
        CustomSheetView(isPresented: $showsRowOptions, contentHeight: 160) {
            if let menuSong {
                //TODO: Maybe the share works inside SongRowOptionsSheet?
                SongRowOptionsSheet(song: menuSong, isShareEnabled: menuSong.trackViewURL != nil) {
                    showsRowOptions = false
                    guard let trackViewURL = menuSong.trackViewURL else { return }
                    DispatchQueue.main.async {
                        shareURL = trackViewURL
                    }
                }
            }
        }
    }

    /// A custom binding that bridges ``HomeViewModel/selectedSong`` to a `navigationDestination`.
    ///
    /// Setting this binding to `nil` calls ``HomeViewModel/dismissSelection()`` to clear the selection.
    private var selectedSongBinding: Binding<Song?> {
        Binding(
            get: { viewModel.selectedSong },
            set: { newValue in
                if newValue == nil {
                    viewModel.dismissSelection()
                }
            }
        )
    }

    private var isShowingShareSheet: Binding<Bool> {
        Binding(
            get: { shareURL != nil },
            set: { isPresented in
                if !isPresented {
                    shareURL = nil
                }
            }
        )
    }
}
