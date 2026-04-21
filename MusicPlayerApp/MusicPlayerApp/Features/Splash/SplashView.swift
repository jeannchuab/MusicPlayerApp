import SwiftUI

struct SplashView: View {
    @State private var isBeating = false

    var body: some View {
        ZStack {
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            //TODO: Add a background animation with the colors?
            
            //LIST: Extra point: Animation on Splash screen
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

#Preview {
    SplashView()
}
