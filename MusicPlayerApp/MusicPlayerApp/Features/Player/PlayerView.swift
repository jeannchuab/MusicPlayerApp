import Combine
import SwiftUI

/// Presents the now-playing experience for a selected song, including playback
/// controls, timeline scrubbing, and navigation to the album screen.
struct PlayerView: View {

    // MARK: - Properties

    /// Dismisses the player when it is presented inside a navigation stack.
    @Environment(\.dismiss) private var dismiss

    /// Owns the playback state for the current song and playlist context.
    @StateObject private var viewModel: PlayerViewModel

    /// Controls the visibility of the custom more-options sheet.
    @State private var showsMoreOptions = false

    /// Drives navigation from the player into the selected album.
    @State private var albumRoute: AlbumRoute?

    /// The track URL currently being shared from the player options sheet.
    @State private var shareURL: URL?

    /// The current banner message shown above the player content.
    @State private var bannerMessage: String?

    /// The dismissal task for the currently visible banner.
    @State private var bannerDismissTask: Task<Void, Never>?

    /// Repository used to load album details from the player flow.
    private let songRepository: any SongRepository

    /// Factory for creating playback services when child screens need one.
    private let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService

    /// Callback used to notify parent flows when playback should affect
    /// recently played state or visible song ordering.
    private let onSongPlayed: (Song) -> Void

    /// The preview cache manager used to store and resolve offline preview files.
    private let previewCacheManager: any PreviewCacheManaging

    // MARK: - Initialization

    /// Creates the player for a selected song and the playlist context it
    /// belongs to.
    ///
    /// - Parameters:
    ///   - song: The song that should be loaded when the player appears.
    ///   - playlist: The ordered songs used for previous and next navigation.
    ///   - songRepository: Repository used for album navigation from the player.
    ///   - playbackService: Service responsible for audio playback operations.
    ///   - makeAudioPlaybackService: Factory used when child flows need a fresh
    ///     playback service instance.
    ///   - onSongPlayed: Callback invoked when playback should update parent
    ///     state, such as recently played songs.
    ///   - previewCacheManager: The preview cache manager used to store and resolve offline preview files.
    init(
        song: Song,
        playlist: [Song] = [],
        songRepository: any SongRepository,
        playbackService: any AudioPlaybackService,
        makeAudioPlaybackService: @escaping @MainActor () -> any AudioPlaybackService,
        onSongPlayed: @escaping (Song) -> Void = { _ in },
        previewCacheManager: any PreviewCacheManaging
    ) {
        _viewModel = StateObject(
            wrappedValue: PlayerViewModel(
                song: song,
                playlist: playlist,
                playbackService: playbackService,
                previewCacheManager: previewCacheManager
            )
        )
        self.songRepository = songRepository
        self.makeAudioPlaybackService = makeAudioPlaybackService
        self.onSongPlayed = onSongPlayed
        self.previewCacheManager = previewCacheManager
    }

    // MARK: - View Body

    /// The full player screen layout, including artwork, controls, and album navigation.
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 100)

                artwork

                Spacer(minLength: 116)

                songDetails

                playbackTimeline

                controls

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.app(13, relativeTo: .footnote))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)

            moreOptionsOverlay

            bannerOverlay
        }
        .navigationTitle(viewModel.song.albumTitle ?? "Now Playing")
        .accessibilityIdentifier("player.screen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleMoreOptions()
                } label: {
                    Image(systemName: "ellipsis")
                }
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityIdentifier("player.moreOptionsButton")
                .accessibilityLabel("More options")
                .accessibilityHint("Shows actions for the current song")
            }
        }
        .task {
            await viewModel.load()
            onSongPlayed(viewModel.song)
            await viewModel.startPlaybackProgressUpdates()
        }
        .onReceive(viewModel.$bannerMessage.compactMap { $0 }) { message in
            showBanner(message)
            viewModel.clearBannerMessage()
        }
        .onDisappear {
            viewModel.pause()
        }
        .navigationDestination(item: $albumRoute) { route in
            AlbumView(
                collectionId: route.collectionId,
                repository: songRepository,
                makeAudioPlaybackService: makeAudioPlaybackService,
                onSongPlayed: onSongPlayed,
                previewCacheManager: previewCacheManager
            )
        }
        .sheet(isPresented: isShowingShareSheet) {
            if let shareURL {
                SystemShareSheet(items: [shareURL])
            }
        }
        .onDisappear {
            bannerDismissTask?.cancel()
            bannerDismissTask = nil
        }
    }

    // MARK: - Overlay

    /// Keeps the player-specific call site in `PlayerView` while delegating the
    /// sheet presentation and dismissal behavior to `CustomSheetView`.
    private var moreOptionsOverlay: some View {
        CustomSheetView(isPresented: $showsMoreOptions, contentHeight: 208) {
            SongOptionsSheet(
                song: viewModel.song,
                options: playerOptions
            )
            .accessibilityIdentifier("player.moreOptionsPanel")
        }
    }

    /// Presents a dismissible status banner above the player content.
    @ViewBuilder
    private var bannerOverlay: some View {
        if let bannerMessage {
            ZStack(alignment: .top) {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissBanner()
                    }

                BannerView(message: bannerMessage)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .accessibilityIdentifier("player.previewBanner")
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(2)
        }
    }

    // MARK: - Content Sections

    /// The primary album artwork displayed near the top of the player.
    private var artwork: some View {
        RemoteArtworkView(url: viewModel.song.artworkURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
                Image(systemName: "music.note")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.surface)
        }
        .frame(maxWidth: 264, maxHeight: 264)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .accessibilityHidden(true)
    }

    /// The track title, artist name, and repeat toggle displayed below the artwork.
    private var songDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.song.title)
                .font(.app(32, weight: .semibold600))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            HStack {
                Text(viewModel.song.artistName)
                    .font(.app(17, weight: .semibold600))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                
                Spacer()
                
                Button {
                    viewModel.toggleRepeat()
                } label: {
                    Image("ic-play-on-repeat")
                        .frame(width: 24, height: 24)
                        .opacity(viewModel.isRepeating ? 1.0 : 0.4)
                }
                .accessibilityLabel(viewModel.isRepeating ? "Disable repeat" : "Enable repeat")
                .accessibilityHint("Repeats the current song when it finishes")
                .accessibilityValue(viewModel.isRepeating ? "On" : "Off")
                .accessibilityIdentifier("player.repeatButton")

                Button {
                    Task {
                        await viewModel.toggleStoredState()
                    }
                } label: {
                    Image(systemName: viewModel.previewStorageSymbolName)
                        .symbolRenderingMode(.hierarchical)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(
                            viewModel.previewStorageState == .stored
                            ? AppTheme.accent
                            : AppTheme.secondaryText
                        )
                }
                .disabled(viewModel.previewStorageState == .storing)
                .accessibilityIdentifier("player.previewStorageButton")
                .accessibilityLabel(viewModel.previewStorageLabel)
                .accessibilityHint(
                    viewModel.previewStorageState == .stored
                    ? "Removes the downloaded preview file from this device"
                    : "Downloads the preview file for offline playback"
                )
                .accessibilityValue(viewModel.previewStorageState == .stored ? "Stored" : "Not stored")
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// The playback scrubber and elapsed and total time labels.
    private var playbackTimeline: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let trackWidth = max(proxy.size.width, 1)
                let progress = min(max(viewModel.progress, 0), 1)
                let thumbSize: CGFloat = 24
                let thumbOffset = progress * (trackWidth - thumbSize)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.surfaceMuted)
                        .frame(height: 8)

                    Capsule()
                        .fill(AppTheme.surfaceBright)
                        .frame(width: thumbOffset + thumbSize / 2, height: 8)

                    Circle()
                        .fill(AppTheme.primaryText)
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(x: thumbOffset)
                        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let clampedX = min(max(value.location.x, thumbSize / 2), trackWidth - thumbSize / 2)
                            let normalized = (clampedX - thumbSize / 2) / max(trackWidth - thumbSize, 1)
                            viewModel.seek(toProgress: normalized)
                        }
                )
                .accessibilityElement()
                .accessibilityLabel("Playback position")
                .accessibilityHint("Drag to seek to a different position in the song")
                .accessibilityValue("\(viewModel.currentTimeText) of \(viewModel.durationText)")
            }
            .frame(height: 28)

            HStack {
                Text(viewModel.currentTimeText)
                Spacer()
                Text(viewModel.durationText)
            }
            .font(.app(13, weight: .medium500, relativeTo: .caption))
            .foregroundStyle(AppTheme.secondaryText)
            .monospacedDigit()
        }
        .padding(.horizontal, 4)
        .animation(.linear(duration: 0.12), value: viewModel.progress)
    }

    /// Playback controls update the shared player state and notify the parent
    /// when a track transition should refresh recently played content.
    private var controls: some View {
        HStack(spacing: 28) {
            Button {
                Task {
                    await viewModel.playPreviousTrack()
                    onSongPlayed(viewModel.song)
                }
            } label: {
                Image("ic-previous-bar-fill")
            }
            .accessibilityIdentifier("player.previousButton")
            .accessibilityLabel("Previous track")
            .accessibilityHint("Plays the previous song in the current playlist")
            .accessibilityAddTraits(.isButton)
            
            Button {
                Task {
                    await viewModel.togglePlayPause()
                    if viewModel.isPlaying {
                        onSongPlayed(viewModel.song)
                    }
                }
            } label: {
                PlayPauseButton(isPlaying: viewModel.isPlaying)
            }
            .accessibilityIdentifier("player.playPauseButton")
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            .accessibilityHint(viewModel.isPlaying ? "Pauses the current song" : "Starts the current song")
            .accessibilityValue(viewModel.isPlaying ? "Playing" : "Paused")
            
            Button {
                Task {
                    let previousSong = viewModel.song
                    await viewModel.playNextTrack()
                    if viewModel.song != previousSong {
                        onSongPlayed(viewModel.song)
                    }
                }
            } label: {
                Image("ic-forward-bar-fill")
            }
            .accessibilityIdentifier("player.nextButton")
            .accessibilityLabel("Next track")
            .accessibilityHint("Plays the next song in the current playlist")
        }
        .font(.title)
        .foregroundStyle(AppTheme.primaryText)
        .accessibilityIdentifier("player.controls")
    }

    // MARK: - Actions

    /// Closes the custom more-options sheet.
    private func dismissMoreOptions() {
        showsMoreOptions = false
    }

    /// Toggles the visibility of the custom more-options sheet.
    private func toggleMoreOptions() {
        showsMoreOptions.toggle()
    }

    /// Shows a banner for two seconds unless it is dismissed earlier.
    ///
    /// - Parameter message: The message rendered inside the banner.
    private func showBanner(_ message: String) {
        bannerDismissTask?.cancel()

        withAnimation(.easeOut(duration: 0.75)) {
            bannerMessage = message
        }

        bannerDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            dismissBanner()
        }
    }

    /// Dismisses the currently visible banner.
    private func dismissBanner() {
        bannerDismissTask?.cancel()
        bannerDismissTask = nil

        withAnimation(.easeOut(duration: 0.75)) {
            bannerMessage = nil
        }
    }

    /// A binding that drives the native share sheet from the player screen.
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

    /// The actions presented in the player more-options sheet.
    private var playerOptions: [SongOptionsSheet.Option] {
        [
            SongOptionsSheet.Option(
                id: "view-album",
                title: "View album",
                accessibilityIdentifier: "player.songOptions.viewAlbum",
                icon: .asset("ic-setlist"),
                isEnabled: viewModel.song.albumId != nil
            ) {
                dismissMoreOptions()
                if let albumId = viewModel.song.albumId {
                    albumRoute = AlbumRoute(collectionId: albumId)
                }
            },
            SongOptionsSheet.Option(
                id: "share-song",
                title: "Share this song",
                accessibilityIdentifier: "player.songOptions.shareSong",
                icon: .system("square.and.arrow.up"),
                isEnabled: viewModel.song.trackViewURL != nil
            ) {
                dismissMoreOptions()
                guard let trackViewURL = viewModel.song.trackViewURL else { return }
                DispatchQueue.main.async {
                    shareURL = trackViewURL
                }
            }
        ]
    }
}

// MARK: - Supporting Types

/// Navigation model used to push an album destination from the player.
private struct AlbumRoute: Identifiable, Hashable {

    // MARK: - Properties

    /// Album identifier used to load the destination content.
    let collectionId: Int

    /// Stable identity for use with `navigationDestination(item:)`.
    var id: Int {
        collectionId
    }
}

/// Small wrapper for the custom play/pause background asset and icon state.
private struct PlayPauseButton: View {

    // MARK: - Properties

    /// Controls whether the pause or play glyph is rendered.
    let isPlaying: Bool

    // MARK: - View Body

    /// The circular play or pause control displayed in the center of the player controls.
    var body: some View {
        ZStack {
            Image("PlayPauseBackground")
                .resizable()
                .scaledToFit()

            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 25, height: 28)
                .offset(x: isPlaying ? 0 : 1.5)
        }
        .frame(width: 72, height: 72)
        .contentShape(Circle())
    }
}
