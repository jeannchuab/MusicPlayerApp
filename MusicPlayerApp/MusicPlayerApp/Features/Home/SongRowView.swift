import SwiftUI

/// A reusable song row with independent actions for row selection and menu presentation.
struct SongRowView: View {

    // MARK: - Properties

    /// The song rendered by the row.
    let song: Song

    /// Triggered when the main row area is tapped.
    let onTap: () -> Void

    /// Triggered when the trailing menu button is tapped.
    let onTapMenu: () -> Void

    // MARK: - Initialization

    /// Creates a new song row.
    ///
    /// - Parameters:
    ///   - song: The song displayed by the row.
    ///   - onTap: The action triggered when the user taps the main row area.
    ///   - onTapMenu: The action triggered when the user taps the trailing menu button.
    init(
        song: Song,
        onTap: @escaping () -> Void = {},
        onTapMenu: @escaping () -> Void = {}
    ) {
        self.song = song
        self.onTap = onTap
        self.onTapMenu = onTapMenu
    }

    // MARK: - Body

    /// The row layout containing the artwork, metadata, and trailing menu action.
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    AsyncImage(url: song.artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "music.note")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(AppTheme.surface)
                        }
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.app(13, weight: .semibold600))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)

                        Text(song.artistName)
                            .font(.app(11, relativeTo: .caption))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(song.title), \(song.artistName)")
            .accessibilityHint("Opens the player")

            Button {
                onTapMenu()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options for \(song.title)")
        }
        .frame(height: 68)
    }
}

/// The actions sheet presented from a song row menu.
struct SongRowOptionsSheet: View {

    // MARK: - Properties

    /// The song currently associated with the sheet.
    let song: Song

    /// Controls whether the share action is available.
    let isShareEnabled: Bool

    /// Called when the share action is selected.
    let onShare: () -> Void

    // MARK: - Initialization

    /// Creates a new row options sheet for the provided song.
    ///
    /// - Parameters:
    ///   - song: The song whose actions are presented in the sheet.
    ///   - isShareEnabled: Indicates whether the share action should be enabled.
    ///   - onShare: The action triggered when the share button is tapped.
    init(
        song: Song,
        isShareEnabled: Bool,
        onShare: @escaping () -> Void
    ) {
        self.song = song
        self.isShareEnabled = isShareEnabled
        self.onShare = onShare
    }

    // MARK: - Body

    /// The sheet content showing the song metadata and share action.
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

            Button(action: onShare) {
                Label("Share this song", systemImage: "square.and.arrow.up")
                    .font(.app(17, weight: .semibold600))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(!isShareEnabled)
            .opacity(isShareEnabled ? 1 : 0.45)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }
}
