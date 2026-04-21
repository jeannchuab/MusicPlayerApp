import SwiftUI

struct AlbumView: View {
    @StateObject private var viewModel: AlbumViewModel
    private let repository: any SongRepository
    private let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService
    private let onSongPlayed: (Song) -> Void

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
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            content
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
    }

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

    private func albumList(_ album: Album) -> some View {
        List {
            Section {
                VStack(spacing: 16) {
                    AsyncImage(url: album.artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "music.note")
                                .font(.system(size: 56, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(AppTheme.surface)
                        }
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .listRowBackground(AppTheme.background)
            .listRowSeparator(.hidden)

            Section {
                ForEach(album.songs) { song in
                    Button {
                        viewModel.select(song)
                    } label: {
                        SongRowView(song: song)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.background)
                    .listRowSeparatorTint(Color.white.opacity(0.08))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
    }

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

    private var songsForSelectedSong: [Song] {
        guard case .loaded(let album) = viewModel.state else { return [] }
        return album.songs
    }
}
