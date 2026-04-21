import SwiftUI

/// A reusable actions sheet for song-specific actions such as viewing the album or sharing the track.
struct SongOptionsSheet: View {

    // MARK: - Supporting Types

    /// A single action rendered inside ``SongOptionsSheet``.
    struct Option: Identifiable {

        // MARK: - Supporting Types

        /// The icon source used when rendering an option label.
        enum Icon {
            /// Uses an image asset bundled with the app.
            case asset(String)

            /// Uses an SF Symbol name.
            case system(String)
        }

        // MARK: - Properties

        /// The stable identifier for the option row.
        let id: String

        /// The user-facing title shown in the sheet.
        let title: String

        /// The icon rendered alongside the title.
        let icon: Icon

        /// Indicates whether the action can currently be invoked.
        let isEnabled: Bool

        /// The action triggered when the option is tapped.
        let action: () -> Void

        // MARK: - Initialization

        /// Creates a new song options sheet action.
        ///
        /// - Parameters:
        ///   - id: The stable identifier for the option row.
        ///   - title: The user-facing title shown in the sheet.
        ///   - icon: The icon rendered alongside the title.
        ///   - isEnabled: Indicates whether the option should be tappable.
        ///   - action: The action triggered when the option is tapped.
        init(
            id: String,
            title: String,
            icon: Icon,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.icon = icon
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    // MARK: - Properties

    /// The song currently associated with the sheet.
    let song: Song

    /// The list of actions rendered below the song metadata.
    let options: [Option]

    // MARK: - Initialization

    /// Creates a new song options sheet for the provided song.
    ///
    /// - Parameters:
    ///   - song: The song whose actions are presented in the sheet.
    ///   - options: The actions rendered below the song metadata.
    init(
        song: Song,
        options: [Option]
    ) {
        self.song = song
        self.options = options
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

            ForEach(options) { option in
                Button(action: option.action) {
                    optionRow(option)
                }
                .buttonStyle(.plain)
                .disabled(!option.isEnabled)
                .opacity(option.isEnabled ? 1 : 0.45)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    /// Builds a leading-aligned row option from a typed ``Option`` model.
    @ViewBuilder
    private func optionRow(_ option: Option) -> some View {
        switch option.icon {
        case .asset(let imageName):
            Label(option.title, image: imageName)
                .font(.app(17, weight: .semibold600))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        case .system(let systemImage):
            Label(option.title, systemImage: systemImage)
                .font(.app(17, weight: .semibold600))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
    }
}
