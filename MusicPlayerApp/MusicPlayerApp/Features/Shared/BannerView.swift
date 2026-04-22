import SwiftUI

/// Displays a short message in a styled banner.
struct BannerView: View {

    // MARK: - Properties

    /// The message rendered inside the banner.
    let message: String

    // MARK: - Initialization

    /// Creates a banner with the provided message.
    ///
    /// - Parameter message: The message rendered inside the banner.
    init(message: String) {
        self.message = message
    }

    // MARK: - Body

    /// The styled banner content.
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityHidden(true)

            Text(message)
                .font(.app(14, weight: .medium500, relativeTo: .subheadline))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: AppTheme.background.opacity(0.28), radius: 10, x: 0, y: 6)
    }
}
