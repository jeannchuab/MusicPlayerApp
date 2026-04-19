import CoreText
import Foundation

enum FontRegistrar {
    static func registerFonts() {
        let bundledFontURLs = Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: "Resources/Fonts")
            ?? Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil)
            ?? []

        for url in bundledFontURLs {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
