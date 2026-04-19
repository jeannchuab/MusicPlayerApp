import SwiftUI

struct SongPreviewSheet: View {
    let song: Song

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                AsyncImage(url: song.artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "music.note")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(AppTheme.surface)
                    }
                }
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(song.title)
                        .font(.app(22, weight: .bold700, relativeTo: .title2))
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text(song.artistName)
                        .font(.app(17, weight: .semibold600, relativeTo: .headline))
                        .foregroundStyle(AppTheme.secondaryText)

                    if let albumTitle = song.albumTitle {
                        Text(albumTitle)
                            .font(.app(15, relativeTo: .subheadline))
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 26) {
                    Image(systemName: "backward.fill")
                    Image(systemName: "play.fill")
                        .font(.title)
                    Image(systemName: "forward.fill")
                }
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityLabel("Player controls")
            }
            .padding(24)
        }
    }
}
