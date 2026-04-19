import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            //TODO: Add a animation on the Logo
            
            Image("MusicalNote")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 100, height: 100)
                .accessibilityHidden(true)
        }
        .accessibilityIdentifier("splash.view")
    }
}

#Preview {
    SplashView()
}
