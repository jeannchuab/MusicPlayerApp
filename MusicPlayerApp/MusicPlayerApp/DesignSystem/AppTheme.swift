import SwiftUI

/// Centralizes the core colors used throughout the app.
enum AppTheme {

    // MARK: - Colors

    /// The primary background color used across full-screen views.
    static let background = Color(red: 0.01, green: 0.01, blue: 0.01)

    /// The secondary surface color used for controls and placeholders.
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.08)

    /// The tertiary surface color used for inputs and elevated controls.
    static let surfaceElevated = Color(red: 0.09, green: 0.09, blue: 0.09)

    /// The quaternary surface color used for progress tracks.
    static let surfaceMuted = Color(red: 0.22, green: 0.22, blue: 0.22)

    /// The light surface color used for active progress fills.
    static let surfaceBright = Color(red: 0.72, green: 0.72, blue: 0.72)

    /// The overlay background color used by custom modal sheets.
    static let modalBackground = Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.96)

    /// The main text color used on dark backgrounds.
    static let primaryText = Color.white

    /// The secondary text color used for supporting information.
    static let secondaryText = Color.white.opacity(0.68)

    /// The tertiary text color used for icons and low-emphasis placeholders.
    static let tertiaryText = Color.white.opacity(0.35)

    /// The accent color used for highlights, buttons, and emphasis.
    static let accent = Color(red: 0.0, green: 0.5255, blue: 0.6275)
}
