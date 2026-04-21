import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
//    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool
    private let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService
    private let repository: any SongRepository

    init(
        repository: any SongRepository,
        makeAudioPlaybackService: @escaping @MainActor () -> any AudioPlaybackService
    ) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
        self.makeAudioPlaybackService = makeAudioPlaybackService
        self.repository = repository
    }

    //TODO: Looks like the pagination is repeating
    //TODO: Fonts are not being loaded
    //TODO: The time is not appearing on the timeline compoment
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    content
                }
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
        }
    }

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

    private func songList(_ songs: [Song]) -> some View {
        List {
            
//            if !viewModel.recentlyPlayed.isEmpty {
//                Section {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 14) {
//                            ForEach(viewModel.recentlyPlayed) { song in
//                                RecentlyPlayedSongView(song: song) {
//                                    viewModel.select(song)
//                                }
//                            }
//                        }
//                        .padding(.vertical, 4)
//                    }
//                } header: {
//                    Text("Recently Played")
//                        .font(.app(17, weight: .semibold600, relativeTo: .headline))
//                        .foregroundStyle(AppTheme.primaryText)
//                        .textCase(nil)
//                }
//                .listRowBackground(AppTheme.background)
//                .listRowSeparator(.hidden)
//            }

            ForEach(songs) { song in
                Button {
                    viewModel.select(song)
                } label: {
                    SongRowView(song: song)
                }
                .buttonStyle(.plain)
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
}
