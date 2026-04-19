import SwiftUI

struct PlayerMoreOptionsSheet: View {
    let song: Song
    let onGoToAlbum: () -> Void

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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .accessibilityIdentifier("player.moreOptions")
    }

    private func option(title: String, image: String) -> some View {
        Label(title, image: image)
            .font(.app(17, weight: .semibold600))
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
