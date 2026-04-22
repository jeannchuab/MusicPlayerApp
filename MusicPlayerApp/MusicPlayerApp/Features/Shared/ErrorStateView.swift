import SwiftUI

/// Presents a reusable error state with a retry action.
struct ErrorStateView: View {

    // MARK: - Properties

    /// The user-facing error message displayed below the title.
    let message: String

    /// The action triggered when the retry button is tapped.
    let retry: () -> Void

    // MARK: - Body

    /// The error UI containing an icon, explanatory text, and retry button.
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)

            Text("Something went wrong")
                .font(.app(20, weight: .bold700, relativeTo: .title3))
                .foregroundStyle(AppTheme.primaryText)

            Text(message)
                .font(.app(15, relativeTo: .subheadline))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .accessibilityIdentifier("error.retryButton")
                .accessibilityLabel("Try again")
                .accessibilityHint("Attempts to load the content again")
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("error.state")
        .accessibilityLabel("Error")
        .accessibilityValue(message)
    }
}
