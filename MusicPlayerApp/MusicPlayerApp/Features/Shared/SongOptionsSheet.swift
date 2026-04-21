import SwiftUI

/// A reusable actions sheet for song-specific actions such as viewing the album or sharing the track.
struct SongOptionsSheet: View {

    // MARK: - Properties

    /// The song currently associated with the sheet.
    let song: Song

    /// Called when the album action is selected.
    let onGoToAlbum: () -> Void

    /// Called when the share action is selected.
    let onShare: () -> Void

    // MARK: - Initialization

    /// Creates a new song options sheet for the provided song.
    ///
    /// - Parameters:
    ///   - song: The song whose actions are presented in the sheet.
    ///   - onGoToAlbum: The action triggered when the view album button is tapped.
    ///   - onShare: The action triggered when the share button is tapped.
    init(
        song: Song,
        onGoToAlbum: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self.song = song
        self.onGoToAlbum = onGoToAlbum
        self.onShare = onShare
    }

    // MARK: - Body

    /// The sheet content showing the current song metadata and available actions.
    var body: some View {
        VStack {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 56, height: 5)
                .padding(.top, 8)

            VStack(alignment: .center) {
                Text(song.title)
                    .font(.app(18, weight: .semibold600, relativeTo: .headline))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(height: 26, alignment: .center)
                    .lineLimit(2)

                Text(song.artistName)
                    .font(.app(14, weight: .medium500, relativeTo: .headline))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(height: 26, alignment: .center)
                    .lineLimit(2)
            }

            Button(action: onGoToAlbum) {
                option(title: "View album", image: "ic-setlist")
            }
            .buttonStyle(.plain)
            .disabled(song.albumId == nil)
            .opacity(song.albumId == nil ? 0.45 : 1)

            Button(action: onShare) {
                option(title: "Share this song", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .disabled(song.trackViewURL == nil)
            .opacity(song.trackViewURL == nil ? 0.45 : 1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    /// Builds a leading-aligned row option using an asset image.
    private func option(title: String, image: String) -> some View {
        Label(title, image: image)
            .font(.app(17, weight: .semibold600))
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    /// Builds a leading-aligned row option using an SF Symbol.
    private func option(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.app(17, weight: .semibold600))
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
