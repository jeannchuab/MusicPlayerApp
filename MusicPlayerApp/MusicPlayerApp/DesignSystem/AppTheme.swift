import SwiftUI

/// Centralizes the core colors used throughout the app.
enum AppTheme {

    // MARK: - Colors

    /// The primary background color used across full-screen views.
    static let background = Color(red: 0.01, green: 0.01, blue: 0.01)

    /// The secondary surface color used for controls and placeholders.
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.08)

    /// The main text color used on dark backgrounds.
    static let primaryText = Color.white

    /// The secondary text color used for supporting information.
    static let secondaryText = Color.white.opacity(0.68)

    /// The accent color used for highlights, buttons, and emphasis.
    static let accent = Color(red: 0.0, green: 0.5255, blue: 0.6275)
}
