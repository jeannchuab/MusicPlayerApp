import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

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
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("error.state")
    }
}
