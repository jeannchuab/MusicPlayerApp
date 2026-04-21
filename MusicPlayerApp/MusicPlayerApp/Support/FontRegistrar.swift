import CoreText
import Foundation

/// Registers bundled font files with the current process.
enum FontRegistrar {

    // MARK: - Registration

    /// Registers all bundled `.otf` font files found in the app bundle.
    static func registerFonts() {
        let bundledFontURLs = Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: "Resources/Fonts")
            ?? Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil)
            ?? []

        for url in bundledFontURLs {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
