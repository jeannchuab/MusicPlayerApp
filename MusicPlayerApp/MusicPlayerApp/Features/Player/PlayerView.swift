import SwiftUI

struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlayerViewModel
    @State private var showsMoreOptions = false
    @State private var moreOptionsDragOffset: CGFloat = 0
    @State private var albumRoute: AlbumRoute?
    private let songRepository: any SongRepository
    private let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService
    private let onSongPlayed: (Song) -> Void

    init(
        song: Song,
        playlist: [Song] = [],
        songRepository: any SongRepository,
        playbackService: any AudioPlaybackService,
        makeAudioPlaybackService: @escaping @MainActor () -> any AudioPlaybackService,
        onSongPlayed: @escaping (Song) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: PlayerViewModel(song: song, playlist: playlist, playbackService: playbackService)
        )
        self.songRepository = songRepository
        self.makeAudioPlaybackService = makeAudioPlaybackService
        self.onSongPlayed = onSongPlayed
    }
    
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
        }
        .navigationTitle("Now Playing")
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
                .accessibilityLabel("More options")
            }
        }
        .task {
            await viewModel.load()
            onSongPlayed(viewModel.song)
            await viewModel.startPlaybackProgressUpdates()
        }
        .onDisappear {
            viewModel.pause()
        }
        .navigationDestination(item: $albumRoute) { route in
            AlbumView(
                collectionId: route.collectionId,
                repository: songRepository,
                makeAudioPlaybackService: makeAudioPlaybackService,
                onSongPlayed: onSongPlayed
            )
        }
    }

    //TODO: Make a component instead
    
    private var moreOptionsOverlay: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom
            let sheetHeight: CGFloat = 192 + bottomInset
            let hiddenOffset = sheetHeight + 34
            let sheetOffset = showsMoreOptions ? moreOptionsDragOffset : hiddenOffset

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.18)
                    .opacity(showsMoreOptions ? 1 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissMoreOptions()
                    }
                    .allowsHitTesting(showsMoreOptions)

                PlayerMoreOptionsSheet(song: viewModel.song) {
                    dismissMoreOptions()
                    if let albumId = viewModel.song.albumId {
                        albumRoute = AlbumRoute(collectionId: albumId)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: sheetHeight)
                .padding(.bottom, bottomInset)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.96))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16,
                        style: .continuous
                    )
                )
                .offset(y: sheetOffset)
                .gesture(moreOptionsDismissGesture)
                .accessibilityIdentifier("player.moreOptionsPanel")
                .allowsHitTesting(showsMoreOptions)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .allowsHitTesting(showsMoreOptions)
        .animation(moreOptionsAnimation, value: showsMoreOptions)
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86), value: moreOptionsDragOffset)
    }

    private var artwork: some View {
        AsyncImage(url: viewModel.song.artworkURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Image(systemName: "music.note")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.surface)
            }
        }
        .frame(maxWidth: 264, maxHeight: 264)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .accessibilityHidden(true)
    }

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
                .accessibilityIdentifier("player.repeatButton")
            }
        }
    }
    
    private var playbackTimeline: some View {
        GeometryReader { proxy in
            let trackWidth = max(proxy.size.width, 1)
            let progress = min(max(viewModel.progress, 0), 1)
            let thumbSize: CGFloat = 24
            let thumbOffset = progress * (trackWidth - thumbSize)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.22, green: 0.22, blue: 0.22))
                    .frame(height: 8)

                Capsule()
                    .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
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
            .accessibilityValue("\(viewModel.currentTimeText) of \(viewModel.durationText)")
        }
        .frame(height: 28)
        .padding(.horizontal, 4)
        .animation(.linear(duration: 0.12), value: viewModel.progress)
    }

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
            .accessibilityLabel("Previous track")
            
            Button {
                viewModel.togglePlayPause()
                if viewModel.isPlaying {
                    onSongPlayed(viewModel.song)
                }
            } label: {
                PlayPauseButton(isPlaying: viewModel.isPlaying)
            }
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            
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
            .accessibilityLabel("Next track")
        }
        .font(.title)
        .foregroundStyle(AppTheme.primaryText)
        .accessibilityIdentifier("player.controls")
    }

    private var moreOptionsDismissGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                moreOptionsDragOffset = max(value.translation.height, 0)
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > 72 || value.predictedEndTranslation.height > 128

                if shouldDismiss {
                    dismissMoreOptions()
                } else {
                    moreOptionsDragOffset = 0
                }
            }
    }

    private func dismissMoreOptions() {
        withAnimation(moreOptionsAnimation) {
            showsMoreOptions = false
            moreOptionsDragOffset = 0
        }
    }

    private func toggleMoreOptions() {
        withAnimation(moreOptionsAnimation) {
            showsMoreOptions.toggle()
            moreOptionsDragOffset = 0
        }
    }

    private var moreOptionsAnimation: Animation {
        .spring(response: 0.36, dampingFraction: 0.92, blendDuration: 0.08)
    }
}

private struct AlbumRoute: Identifiable, Hashable {
    let collectionId: Int

    var id: Int {
        collectionId
    }
}

private struct PlayPauseButton: View {
    let isPlaying: Bool

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
