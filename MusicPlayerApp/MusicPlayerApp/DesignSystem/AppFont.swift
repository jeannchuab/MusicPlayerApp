import SwiftUI

/// Centralizes the bundled Articulat CF font family used across the app.
enum AppFont {

    // MARK: - Supporting Types

    /// The supported Articulat CF font weights available in the app bundle.
    enum Weight: Int {
        case light300 = 300
        case regular400 = 400
        case medium500 = 500
        case semibold600 = 600
        case bold700 = 700
        case heavy800 = 800
    }

    // MARK: - Factory

    /// Creates a SwiftUI `Font` using the bundled Articulat CF family.
    ///
    /// - Parameters:
    ///   - size: The point size for the font.
    ///   - weight: The Articulat CF weight to load.
    ///   - textStyle: The text style used for Dynamic Type scaling.
    static func font(
        size: CGFloat,
        weight: Weight = .regular400,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        Font.custom(postScriptName(for: weight), size: size, relativeTo: textStyle)
    }

    // MARK: - Helpers

    /// Returns the PostScript font name associated with the provided weight.
    ///
    /// - Parameter weight: The Articulat CF weight to resolve.
    private static func postScriptName(for weight: Weight) -> String {
        switch weight {
        case .light300:
            "ArticulatCF-Light"
        case .regular400:
            "ArticulatCF-Regular"
        case .medium500:
            "ArticulatCF-Medium"
        case .semibold600:
            "ArticulatCF-DemiBold"
        case .bold700:
            "ArticulatCF-Bold"
        case .heavy800:
            "ArticulatCF-Heavy"
        }
    }
}

/// Convenience helpers for creating app-branded fonts from `Font`.
extension Font {
    /// Creates a SwiftUI `Font` using the bundled Articulat CF family.
    ///
    /// - Parameters:
    ///   - size: The point size for the font.
    ///   - weight: The Articulat CF weight to load.
    ///   - textStyle: The text style used for Dynamic Type scaling.
    static func app(
        _ size: CGFloat,
        weight: AppFont.Weight = .regular400,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        AppFont.font(size: size, weight: weight, relativeTo: textStyle)
    }
}
