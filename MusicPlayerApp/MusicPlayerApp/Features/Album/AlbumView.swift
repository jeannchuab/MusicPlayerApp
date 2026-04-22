import SwiftUI

/// Displays album metadata and its tracks, and presents the player for the selected song.
struct AlbumView: View {

    // MARK: - Properties

    /// The view model that loads and exposes album state for the screen.
    @StateObject private var viewModel: AlbumViewModel

    /// The song whose row menu is currently active.
    @State private var menuSong: Song?

    /// Controls the visibility of the row options sheet.
    @State private var showsRowOptions = false

    /// The track URL currently being shared from the row options sheet.
    @State private var shareURL: URL?

    /// Repository forwarded to the player for follow-up album and song interactions.
    private let repository: any SongRepository

    /// Factory used to provide a fresh playback service to each presented player.
    private let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService

    /// Callback invoked whenever playback starts from this album flow.
    private let onSongPlayed: (Song) -> Void

    // MARK: - Initialization

    /// Creates a new album screen for the provided collection identifier.
    ///
    /// - Parameters:
    ///   - collectionId: The iTunes collection identifier used to load the album.
    ///   - repository: The repository used to fetch album data and support downstream player flows.
    ///   - makeAudioPlaybackService: A factory that creates a fresh playback service for each presented player.
    ///   - onSongPlayed: A callback invoked whenever playback starts from the album flow.
    init(
        collectionId: Int,
        repository: any SongRepository,
        makeAudioPlaybackService: @escaping @MainActor () -> any AudioPlaybackService,
        onSongPlayed: @escaping (Song) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: AlbumViewModel(collectionId: collectionId, repository: repository)
        )
        self.repository = repository
        self.makeAudioPlaybackService = makeAudioPlaybackService
        self.onSongPlayed = onSongPlayed
    }

    // MARK: - Body

    /// The album screen layout, including the song list, row options sheet, and share sheet presentation.
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            content

            rowOptionsOverlay
        }
        .navigationTitle("Album")
        .accessibilityIdentifier("album.screen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .sheet(item: selectedSongBinding) { song in
            PlayerView(
                song: song,
                playlist: songsForSelectedSong,
                songRepository: repository,
                playbackService: makeAudioPlaybackService(),
                makeAudioPlaybackService: makeAudioPlaybackService,
                onSongPlayed: onSongPlayed
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: isShowingShareSheet) {
            if let shareURL {
                SystemShareSheet(items: [shareURL])
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading album")
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.primaryText)
        case .loaded(let album):
            albumList(album)
        case .empty:
            ContentUnavailableView(
                "No songs found",
                systemImage: "rectangle.stack",
                description: Text("This album does not have tracks available.")
            )
            .foregroundStyle(AppTheme.primaryText)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) {
                Task { await viewModel.refresh() }
            }
            .padding(24)
        }
    }

    /// Builds the scrollable album details and song list.
    private func albumList(_ album: Album) -> some View {
        List {
            Section {
                VStack(spacing: 16) {
                    RemoteArtworkView(url: album.artworkURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                            Image(systemName: "music.note")
                                .font(.system(size: 56, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(AppTheme.surface)
                    }
                    .frame(width: 210, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        Text(album.title)
                            .font(.app(22, weight: .bold700, relativeTo: .title2))
                            .foregroundStyle(AppTheme.primaryText)
                            .multilineTextAlignment(.center)

                        Text(album.artistName)
                            .font(.app(17, weight: .semibold600, relativeTo: .headline))
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("\(album.songs.count) songs")
                            .font(.app(15, relativeTo: .subheadline))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(album.title) by \(album.artistName)")
                    .accessibilityValue("\(album.songs.count) songs")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .listRowBackground(AppTheme.background)
            .listRowSeparator(.hidden)

            Section {
                ForEach(album.songs) { song in
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
                    .listRowSeparatorTint(Color.white.opacity(0.08))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("album.songList")
        .accessibilityLabel("Album songs")
        .accessibilityValue("\(album.songs.count) songs")
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Helpers

    /// The custom row options sheet that supports sharing a song from the album track list.
    private var rowOptionsOverlay: some View {
        CustomSheetView(isPresented: $showsRowOptions, contentHeight: 160) {
            if let menuSong {
                SongOptionsSheet(
                    song: menuSong,
                    options: rowOptions(for: menuSong)
                )
            }
        }
    }

    /// Bridges the selected song from the view model into sheet presentation state.
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

    /// Returns the current album tracks so the player can navigate within the album.
    private var songsForSelectedSong: [Song] {
        guard case .loaded(let album) = viewModel.state else { return [] }
        return album.songs
    }

    /// A binding that drives the native share sheet from the album screen.
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

    /// Builds the actions presented in the album row options sheet for the selected song.
    ///
    /// - Parameter song: The song associated with the active row options sheet.
    /// - Returns: The actions rendered by the shared ``SongOptionsSheet``.
    private func rowOptions(for song: Song) -> [SongOptionsSheet.Option] {
        [
            SongOptionsSheet.Option(
                id: "share-song",
                title: "Share this song",
                accessibilityIdentifier: "album.songOptions.shareSong",
                icon: .system("square.and.arrow.up"),
                isEnabled: song.trackViewURL != nil
            ) {
                showsRowOptions = false
                guard let trackViewURL = song.trackViewURL else { return }
                DispatchQueue.main.async {
                    shareURL = trackViewURL
                }
            }
        ]
    }
}
