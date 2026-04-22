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
            .accessibilityIdentifier("song.row.\(song.id)")
            .accessibilityLabel("\(song.title), \(song.artistName)")
            .accessibilityHint("Opens the player")

            Button {
                onTapMenu()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("song.row.menu.\(song.id)")
            .accessibilityLabel("More options for \(song.title)")
        }
        .frame(height: 68)
    }
}
