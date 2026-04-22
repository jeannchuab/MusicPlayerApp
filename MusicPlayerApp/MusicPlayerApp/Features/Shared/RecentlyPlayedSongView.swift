import SwiftUI

/// A compact card used inside the Home recently played carousel.
struct RecentlyPlayedSongView: View {

    // MARK: - Properties

    /// The song rendered by the card.
    let song: Song

    /// Triggered when the card is tapped.
    let onTap: () -> Void

    // MARK: - Initialization

    /// Creates a new recently played song card.
    ///
    /// - Parameters:
    ///   - song: The song rendered by the card.
    ///   - onTap: The action triggered when the user taps the card.
    init(
        song: Song,
        onTap: @escaping () -> Void = {}
    ) {
        self.song = song
        self.onTap = onTap
    }

    // MARK: - Body

    /// The compact artwork and metadata layout used by the carousel.
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                RemoteArtworkView(url: song.artworkURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.surface)
                }
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.app(13, weight: .semibold600))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.app(11, relativeTo: .caption))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 112, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recentlyPlayed.song.\(song.id)")
        .accessibilityLabel("\(song.title), \(song.artistName)")
        .accessibilityHint("Opens the player")
    }
}
