import SwiftUI

struct RootView: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            HomeView(
                repository: dependencies.songRepository,
                makeAudioPlaybackService: dependencies.makeAudioPlaybackService
            )
            .accessibilityIdentifier("root.home")
            .opacity(shouldShowSplash ? 0 : 1)

            if shouldShowSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            guard !dependencies.launchConfiguration.skipsSplash else {
                showsSplash = false
                return
            }

            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeOut(duration: 0.28)) {
                showsSplash = false
            }
        }
    }

    private var shouldShowSplash: Bool {
        showsSplash && !dependencies.launchConfiguration.skipsSplash
    }
}
