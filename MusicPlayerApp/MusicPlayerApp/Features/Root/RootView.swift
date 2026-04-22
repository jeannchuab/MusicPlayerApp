import SwiftUI

/// Coordinates the initial splash presentation and transitions into the home screen.
struct RootView: View {

    // MARK: - Properties

    /// The shared app dependencies injected from the app entry point.
    @Environment(\.appDependencies) private var dependencies

    /// Tracks whether the splash screen should still be visible.
    @State private var showsSplash = true

    // MARK: - Body

    /// The root layout that fades from the splash screen into the home screen.
    var body: some View {
        ZStack {
            HomeView(
                repository: dependencies.songRepository,
                makeAudioPlaybackService: dependencies.makeAudioPlaybackService
            )
            .accessibilityIdentifier("root.home")
            .accessibilityLabel("Home")
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

    // MARK: - Helpers

    /// Indicates whether the splash should currently cover the home screen.
    private var shouldShowSplash: Bool {
        showsSplash && !dependencies.launchConfiguration.skipsSplash
    }
}
