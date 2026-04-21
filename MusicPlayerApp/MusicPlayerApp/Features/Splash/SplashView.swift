import SwiftUI

/// Displays the launch splash experience before the root content becomes visible.
struct SplashView: View {

    // MARK: - Properties

    /// Controls the heartbeat-style animation applied to the musical note.
    @State private var isBeating = false

    // MARK: - Body

    /// The splash layout containing the background image and animated note mark.
    var body: some View {
        ZStack {
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Image("MusicalNote")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 100, height: 100)
                .scaleEffect(isBeating ? 1.08 : 1)
                .opacity(isBeating ? 0.9 : 0.72)
                .animation(
                    .easeInOut(duration: 0.42)
                        .repeatForever(autoreverses: true),
                    value: isBeating
                )
                .accessibilityHidden(true)
        }
        .onAppear {
            isBeating = true
        }
        .accessibilityIdentifier("splash.view")
    }
}

/// Preview configuration for the splash screen.
#Preview {
    SplashView()
}
